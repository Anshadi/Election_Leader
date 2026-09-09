package com.asthana.Election_Leader.Manager;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Dtos.*;
import com.asthana.Election_Leader.Registry.ZookeeperLeaderElection;
import com.asthana.Election_Leader.Registry.ZookeeperNodeRegistry;
import com.asthana.Election_Leader.Strategy.IdGeneratorStrategy;
import com.asthana.Election_Leader.Strategy.RedisSegmentStrategy;
import com.asthana.Election_Leader.Strategy.SnowflakeStrategy;
import com.asthana.Election_Leader.Utils.IdPacker;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import jakarta.annotation.PostConstruct;
import org.HdrHistogram.Histogram;
import org.HdrHistogram.SingleWriterRecorder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class AdaptiveIdManager {

    private static final Logger log = LoggerFactory.getLogger(AdaptiveIdManager.class);

    private final AppProperties appProperties;
    private final SnowflakeStrategy snowflakeStrategy;
    private final RedisSegmentStrategy redisSegmentStrategy;
    private final ZookeeperLeaderElection leaderElection;
    private final ZookeeperNodeRegistry nodeRegistry;

    // Micrometer Observability Meters
    private final Counter idSuccessCounter;
    private final Counter idFallbackCounter;
    private final Timer idTimer;
    private final MeterRegistry meterRegistry;

    // HdrHistogram for measuring latency in microseconds up to 100,000,000 (100 seconds)
    private final SingleWriterRecorder latencyRecorder = new SingleWriterRecorder(1, 100_000_000L, 3);
    private final AtomicLong totalGeneratedCount = new AtomicLong(0);

    @Autowired
    public AdaptiveIdManager(
            AppProperties appProperties,
            SnowflakeStrategy snowflakeStrategy,
            RedisSegmentStrategy redisSegmentStrategy,
            ZookeeperLeaderElection leaderElection,
            ZookeeperNodeRegistry nodeRegistry,
            Counter idGenerationSuccessCounter,
            Counter idGenerationFallbackCounter,
            Timer idGenerationTimer,
            MeterRegistry meterRegistry) {
        this.appProperties = appProperties;
        this.snowflakeStrategy = snowflakeStrategy;
        this.redisSegmentStrategy = redisSegmentStrategy;
        this.leaderElection = leaderElection;
        this.nodeRegistry = nodeRegistry;
        this.idSuccessCounter = idGenerationSuccessCounter;
        this.idFallbackCounter = idGenerationFallbackCounter;
        this.idTimer = idGenerationTimer;
        this.meterRegistry = meterRegistry;
    }

    @PostConstruct
    public void registerGauges() {
        meterRegistry.gauge("election_leader_active_node_id", nodeRegistry, ZookeeperNodeRegistry::getNodeId);
        meterRegistry.gauge("election_leader_is_cluster_leader", leaderElection, le -> le.isLeader() ? 1.0 : 0.0);
    }

    /**
     * Chooses the optimal strategy based on configuration and current cluster health.
     */
    public IdGeneratorStrategy resolveStrategy() {
        String configured = appProperties.getStrategy();

        if ("IN_MEMORY".equalsIgnoreCase(configured)) {
            return snowflakeStrategy;
        }
        if ("REDIS".equalsIgnoreCase(configured)) {
            return redisSegmentStrategy;
        }

        // AUTO mode: Prioritize Redis segment if available, else gracefully fallback to Snowflake
        if (redisSegmentStrategy.isAvailable()) {
            return redisSegmentStrategy;
        } else {
            return snowflakeStrategy;
        }
    }

    /**
     * Generates a single unique ID, records latency SLA histogram, and returns detailed response.
     */
    public Mono<IdResponse> generateNextId() {
        long startNanos = System.nanoTime();
        IdGeneratorStrategy strategy = resolveStrategy();

        return strategy.nextId()
                .onErrorResume(err -> {
                    log.warn("Strategy {} failed. Failing over to SnowflakeStrategy. Reason: {}",
                            strategy.getStrategyName(), err.getMessage());
                    idFallbackCounter.increment();
                    return snowflakeStrategy.nextId();
                })
                .map(id -> {
                    long elapsedNanos = System.nanoTime() - startNanos;
                    long elapsedMicros = Math.max(1, elapsedNanos / 1000);
                    recordLatency(elapsedMicros);
                    idTimer.record(elapsedNanos, TimeUnit.NANOSECONDS);
                    idSuccessCounter.increment();
                    totalGeneratedCount.incrementAndGet();

                    int nodeId = IdPacker.extractNodeId(id);
                    int sequence = IdPacker.extractSequence(id);
                    long absTimestamp = IdPacker.extractAbsoluteTimestamp(id, appProperties.getEpochMillis());
                    String isoDate = Instant.ofEpochMilli(absTimestamp).toString();

                    return IdResponse.builder()
                            .id(id)
                            .timestamp(absTimestamp)
                            .dateTime(isoDate)
                            .nodeId(nodeId)
                            .sequence(sequence)
                            .strategy(strategy.getStrategyName())
                            .build();
                });
    }

    /**
     * Generates a batch of unique IDs.
     */
    public Mono<BatchIdResponse> generateBatch(int count) {
        long startNanos = System.nanoTime();
        IdGeneratorStrategy strategy = resolveStrategy();

        return strategy.nextBatch(count)
                .onErrorResume(err -> {
                    log.warn("Batch on strategy {} failed. Failing over to SnowflakeStrategy: {}",
                            strategy.getStrategyName(), err.getMessage());
                    idFallbackCounter.increment(count);
                    return snowflakeStrategy.nextBatch(count);
                })
                .collectList()
                .map(ids -> {
                    long elapsedNanos = System.nanoTime() - startNanos;
                    double elapsedMicros = elapsedNanos / 1000.0;
                    idTimer.record(elapsedNanos, TimeUnit.NANOSECONDS);
                    idSuccessCounter.increment(ids.size());
                    totalGeneratedCount.addAndGet(ids.size());

                    return BatchIdResponse.builder()
                            .ids(ids)
                            .count(ids.size())
                            .strategy(strategy.getStrategyName())
                            .durationMicros(elapsedMicros)
                            .build();
                });
    }

    /**
     * Streams IDs reactively.
     */
    public Flux<Long> streamIds(int count) {
        IdGeneratorStrategy strategy = resolveStrategy();
        return strategy.nextBatch(count)
                .onErrorResume(err -> {
                    idFallbackCounter.increment(count);
                    return snowflakeStrategy.nextBatch(count);
                })
                .doOnNext(id -> {
                    idSuccessCounter.increment();
                    totalGeneratedCount.incrementAndGet();
                });
    }

    /**
     * Parses/decodes a 64-bit ID.
     */
    public ParsedIdDto decodeId(long id) {
        return IdPacker.unpack(id, appProperties.getEpochMillis());
    }

    /**
     * Collects latency percentiles from HdrHistogram.
     */
    public LatencyMetricsDto getLatencyMetrics() {
        Histogram histogram = latencyRecorder.getIntervalHistogram();
        return LatencyMetricsDto.builder()
                .totalGenerated(totalGeneratedCount.get())
                .p50Micros(histogram.getValueAtPercentile(50.0))
                .p90Micros(histogram.getValueAtPercentile(90.0))
                .p99Micros(histogram.getValueAtPercentile(99.0))
                .p999Micros(histogram.getValueAtPercentile(99.9))
                .maxMicros(histogram.getMaxValue())
                .meanMicros(histogram.getMean())
                .build();
    }

    /**
     * Returns the cluster and node health status.
     */
    public ClusterNodeDto getClusterStatus() {
        return ClusterNodeDto.builder()
                .nodeId(nodeRegistry.getNodeId())
                .isLeader(leaderElection.isLeader())
                .zookeeperConnected(nodeRegistry.isConnected())
                .redisConnected(redisSegmentStrategy.isAvailable())
                .activeStrategy(resolveStrategy().getStrategyName())
                .epochMillis(appProperties.getEpochMillis())
                .registeredNodes(nodeRegistry.getRegisteredNodes())
                .build();
    }

    private void recordLatency(long micros) {
        try {
            latencyRecorder.recordValue(Math.min(micros, 100_000_000L));
        } catch (Exception ignored) {}
    }
}
