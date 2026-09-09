package com.asthana.Election_Leader.Strategy;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Exceptions.SegmentExhaustedException;
import com.asthana.Election_Leader.Repository.RedisSegmentRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.ReentrantLock;

@Component("redisSegmentStrategy")
public class RedisSegmentStrategy implements IdGeneratorStrategy {

    private static final Logger log = LoggerFactory.getLogger(RedisSegmentStrategy.class);

    private final AppProperties appProperties;
    private final RedisSegmentRepository segmentRepository;

    private final SegmentBuffer segmentBuffer = new SegmentBuffer();
    private final AtomicBoolean isInitialized = new AtomicBoolean(false);
    private volatile boolean isRedisHealthy = false;

    @Autowired
    public RedisSegmentStrategy(AppProperties appProperties, RedisSegmentRepository segmentRepository) {
        this.appProperties = appProperties;
        this.segmentRepository = segmentRepository;
    }

    @PostConstruct
    public void init() {
        try {
            Long newMax = segmentRepository.allocateSegment(appProperties.getRedis().getBaseBlockSize())
                    .block(Duration.ofSeconds(2));

            if (newMax != null) {
                int step = appProperties.getRedis().getBaseBlockSize();
                long min = newMax - step + 1;
                segmentBuffer.getCurrentSegment().init(min, newMax, step);
                isInitialized.set(true);
                isRedisHealthy = true;
                log.info("RedisSegmentStrategy initialized with range [{}, {}], step={}", min, newMax, step);
            }
        } catch (Exception e) {
            log.warn("Redis Segment Strategy could not connect to Redis at startup: {}. Operating in fallback mode.", e.getMessage());
            isRedisHealthy = false;
        }
    }

    @Override
    public Mono<Long> nextId() {
        return Mono.fromSupplier(this::generateSingleId)
                .subscribeOn(Schedulers.boundedElastic());
    }

    @Override
    public Flux<Long> nextBatch(int count) {
        if (count <= 0) {
            return Flux.empty();
        }
        return Flux.defer(() -> {
            List<Long> ids = new ArrayList<>(count);
            for (int i = 0; i < count; i++) {
                ids.add(generateSingleId());
            }
            return Flux.fromIterable(ids);
        }).subscribeOn(Schedulers.boundedElastic());
    }

    private long generateSingleId() {
        if (!isInitialized.get()) {
            synchronized (this) {
                if (!isInitialized.get()) {
                    init();
                    if (!isInitialized.get()) {
                        throw new SegmentExhaustedException("Redis is unreachable and SegmentBuffer is not initialized.");
                    }
                }
            }
        }

        while (true) {
            segmentBuffer.getLock().lock();
            try {
                Segment current = segmentBuffer.getCurrentSegment();

                // Trigger asynchronous prefetch of the next buffer if remaining IDs fall below threshold
                if (!segmentBuffer.isNextReady() &&
                        (current.getMax() - current.getValue().get()) < (current.getStep() * appProperties.getRedis().getRefillThresholdRatio()) &&
                        segmentBuffer.getThreadRunning().compareAndSet(false, true)) {
                    
                    CompletableFuture.runAsync(this::asyncFetchNextSegment);
                }

                long value = current.getValue().getAndIncrement();
                if (value <= current.getMax()) {
                    return value;
                }

                // Current segment exhausted, try switching to next segment
                if (segmentBuffer.isNextReady()) {
                    segmentBuffer.switchPos();
                    segmentBuffer.setNextReady(false);
                } else {
                    // Synchronous emergency fetch
                    syncFetchSegment(current);
                }
            } finally {
                segmentBuffer.getLock().unlock();
            }
        }
    }

    private void asyncFetchNextSegment() {
        try {
            Segment next = segmentBuffer.getNextSegment();
            int nextStep = calculateNextStep(segmentBuffer.getCurrentSegment());

            Long newMax = segmentRepository.allocateSegment(nextStep)
                    .block(Duration.ofSeconds(3));

            if (newMax != null) {
                long min = newMax - nextStep + 1;
                next.init(min, newMax, nextStep);
                segmentBuffer.setNextReady(true);
                isRedisHealthy = true;
                log.debug("Asynchronously prefetched next ID segment: [{}, {}], step={}", min, newMax, nextStep);
            }
        } catch (Exception e) {
            log.warn("Failed to asynchronously prefetch next Redis ID segment: {}", e.getMessage());
            isRedisHealthy = false;
        } finally {
            segmentBuffer.getThreadRunning().set(false);
        }
    }

    private void syncFetchSegment(Segment current) {
        int nextStep = calculateNextStep(current);
        try {
            Long newMax = segmentRepository.allocateSegment(nextStep)
                    .block(Duration.ofSeconds(3));

            if (newMax != null) {
                long min = newMax - nextStep + 1;
                current.init(min, newMax, nextStep);
                isRedisHealthy = true;
                log.info("Synchronously allocated new ID segment: [{}, {}], step={}", min, newMax, nextStep);
            } else {
                isRedisHealthy = false;
                throw new SegmentExhaustedException("Redis returned null on segment allocation.");
            }
        } catch (Exception e) {
            isRedisHealthy = false;
            throw new SegmentExhaustedException("Failed to allocate segment from Redis: " + e.getMessage());
        }
    }

    private int calculateNextStep(Segment current) {
        int step = current.getStep();
        if (step <= 0) {
            step = appProperties.getRedis().getBaseBlockSize();
        }
        long duration = System.currentTimeMillis() - current.getCreateTime();
        if (duration < 15 * 60 * 1000 && step * 2 <= appProperties.getRedis().getMaxBlockSize()) {
            step = step * 2;
        } else if (duration > 30 * 60 * 1000 && step / 2 >= appProperties.getRedis().getMinBlockSize()) {
            step = step / 2;
        }
        return step;
    }

    @Override
    public String getStrategyName() {
        return "REDIS_SEGMENT_DOUBLE_BUFFER";
    }

    @Override
    public boolean isAvailable() {
        return isRedisHealthy && isInitialized.get();
    }

    private static class Segment {
        private final AtomicLong value = new AtomicLong(0);
        private volatile long min;
        private volatile long max;
        private volatile int step;
        private volatile long createTime;

        public void init(long min, long max, int step) {
            this.min = min;
            this.max = max;
            this.step = step;
            this.value.set(min);
            this.createTime = System.currentTimeMillis();
        }

        public AtomicLong getValue() { return value; }
        public long getMin() { return min; }
        public long getMax() { return max; }
        public int getStep() { return step; }
        public long getCreateTime() { return createTime; }
    }

    private static class SegmentBuffer {
        private final Segment[] segments = new Segment[]{new Segment(), new Segment()};
        private volatile int currentPos = 0;
        private volatile boolean nextReady = false;
        private final AtomicBoolean threadRunning = new AtomicBoolean(false);
        private final ReentrantLock lock = new ReentrantLock();

        public Segment getCurrentSegment() { return segments[currentPos]; }
        public Segment getNextSegment() { return segments[(currentPos + 1) % 2]; }
        public void switchPos() { currentPos = (currentPos + 1) % 2; }
        public boolean isNextReady() { return nextReady; }
        public void setNextReady(boolean nextReady) { this.nextReady = nextReady; }
        public AtomicBoolean getThreadRunning() { return threadRunning; }
        public ReentrantLock getLock() { return lock; }
    }
}
