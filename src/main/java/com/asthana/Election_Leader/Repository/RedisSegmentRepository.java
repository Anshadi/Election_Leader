package com.asthana.Election_Leader.Repository;

import com.asthana.Election_Leader.Configs.AppProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Repository
public class RedisSegmentRepository {

    private static final Logger log = LoggerFactory.getLogger(RedisSegmentRepository.class);

    private final ReactiveStringRedisTemplate redisTemplate;
    private final AppProperties appProperties;

    @Autowired
    public RedisSegmentRepository(ReactiveStringRedisTemplate redisTemplate, AppProperties appProperties) {
        this.redisTemplate = redisTemplate;
        this.appProperties = appProperties;
    }

    /**
     * Atomically allocates a new range of IDs of size 'step' by incrementing the Redis sequence key.
     *
     * @param step the number of IDs to allocate
     * @return Mono of the new upper bound (maxId)
     */
    public Mono<Long> allocateSegment(int step) {
        String key = appProperties.getRedis().getKey();
        return redisTemplate.opsForValue()
                .increment(key, step)
                .timeout(Duration.ofMillis(appProperties.getRedis().getRefillThresholdRatio() > 0 ? 3000 : 2000))
                .doOnSuccess(newMax -> log.debug("Allocated segment [maxId={}, step={}] from Redis key: {}", newMax, step, key))
                .doOnError(err -> log.warn("Failed to allocate segment from Redis key {}: {}", key, err.getMessage()));
    }

    /**
     * Checks if Redis connection is alive and healthy.
     */
    public Mono<Boolean> ping() {
        return redisTemplate.getConnectionFactory()
                .getReactiveConnection()
                .ping()
                .map("PONG"::equalsIgnoreCase)
                .onErrorReturn(false);
    }
}
