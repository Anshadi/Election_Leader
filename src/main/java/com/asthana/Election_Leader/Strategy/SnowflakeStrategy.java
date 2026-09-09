package com.asthana.Election_Leader.Strategy;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Registry.ZookeeperNodeRegistry;
import com.asthana.Election_Leader.Utils.ClockDriftHandler;
import com.asthana.Election_Leader.Utils.IdPacker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;

@Component("snowflakeStrategy")
public class SnowflakeStrategy implements IdGeneratorStrategy {

    private static final Logger log = LoggerFactory.getLogger(SnowflakeStrategy.class);

    private final AppProperties appProperties;
    private final ZookeeperNodeRegistry nodeRegistry;

    private long lastTimestamp = -1L;
    private long sequence = 0L;

    @Autowired
    public SnowflakeStrategy(AppProperties appProperties, ZookeeperNodeRegistry nodeRegistry) {
        this.appProperties = appProperties;
        this.nodeRegistry = nodeRegistry;
    }

    @Override
    public synchronized Mono<Long> nextId() {
        return Mono.fromSupplier(this::generateSingleId);
    }

    @Override
    public synchronized Flux<Long> nextBatch(int count) {
        if (count <= 0) {
            return Flux.empty();
        }
        List<Long> ids = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            ids.add(generateSingleId());
        }
        return Flux.fromIterable(ids);
    }

    private synchronized long generateSingleId() {
        long currentTimestamp = System.currentTimeMillis();
        long epochMillis = appProperties.getEpochMillis();

        if (currentTimestamp < lastTimestamp) {
            currentTimestamp = ClockDriftHandler.handleBackwardDrift(currentTimestamp, lastTimestamp);
        }

        if (currentTimestamp == lastTimestamp) {
            sequence = (sequence + 1) & IdPacker.MAX_SEQUENCE;
            if (sequence == 0) {
                currentTimestamp = ClockDriftHandler.tillNextMillis(lastTimestamp);
            }
        } else {
            sequence = 0L;
        }

        lastTimestamp = currentTimestamp;
        long timestampDelta = currentTimestamp - epochMillis;
        int nodeId = nodeRegistry.getNodeId();

        return IdPacker.pack(timestampDelta, nodeId, sequence);
    }

    @Override
    public String getStrategyName() {
        return "IN_MEMORY_SNOWFLAKE";
    }

    @Override
    public boolean isAvailable() {
        return true; // Standalone snowflake is always available
    }
}
