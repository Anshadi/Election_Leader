package com.asthana.Election_Leader;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Dtos.BatchIdResponse;
import com.asthana.Election_Leader.Dtos.ClusterNodeDto;
import com.asthana.Election_Leader.Dtos.IdResponse;
import com.asthana.Election_Leader.Dtos.LatencyMetricsDto;
import com.asthana.Election_Leader.Manager.AdaptiveIdManager;
import com.asthana.Election_Leader.Registry.ZookeeperLeaderElection;
import com.asthana.Election_Leader.Registry.ZookeeperNodeRegistry;
import com.asthana.Election_Leader.Strategy.RedisSegmentStrategy;
import com.asthana.Election_Leader.Strategy.SnowflakeStrategy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.when;

class AdaptiveIdManagerTest {

    private AppProperties appProperties;
    private SnowflakeStrategy mockSnowflake;
    private RedisSegmentStrategy mockRedis;
    private ZookeeperLeaderElection mockLeader;
    private ZookeeperNodeRegistry mockRegistry;
    private AdaptiveIdManager manager;

    @BeforeEach
    void setup() {
        appProperties = new AppProperties();
        appProperties.setEpochMillis(1700000000000L);
        appProperties.setStrategy("AUTO");

        mockSnowflake = Mockito.mock(SnowflakeStrategy.class);
        mockRedis = Mockito.mock(RedisSegmentStrategy.class);
        mockLeader = Mockito.mock(ZookeeperLeaderElection.class);
        mockRegistry = Mockito.mock(ZookeeperNodeRegistry.class);

        when(mockRegistry.getNodeId()).thenReturn(0);
        when(mockLeader.isLeader()).thenReturn(true);
        when(mockSnowflake.getStrategyName()).thenReturn("IN_MEMORY_SNOWFLAKE");
        when(mockRedis.getStrategyName()).thenReturn("REDIS_SEGMENT_DOUBLE_BUFFER");

        manager = new AdaptiveIdManager(appProperties, mockSnowflake, mockRedis, mockLeader, mockRegistry);
    }

    @Test
    @DisplayName("Should route to Redis if healthy, else Snowflake in AUTO mode")
    void testStrategyResolution() {
        when(mockRedis.isAvailable()).thenReturn(true);
        assertEquals(mockRedis, manager.resolveStrategy());

        when(mockRedis.isAvailable()).thenReturn(false);
        assertEquals(mockSnowflake, manager.resolveStrategy());
    }

    @Test
    @DisplayName("Should generate ID and record latency metrics")
    void testGenerateIdAndMetrics() {
        when(mockRedis.isAvailable()).thenReturn(false);
        when(mockSnowflake.nextId()).thenReturn(Mono.just(123456789L));

        IdResponse response = manager.generateNextId().block();
        assertNotNull(response);
        assertEquals(123456789L, response.getId());

        LatencyMetricsDto metrics = manager.getLatencyMetrics();
        assertEquals(1, metrics.getTotalGenerated());
    }

    @Test
    @DisplayName("Should generate batch of IDs")
    void testBatchGeneration() {
        when(mockRedis.isAvailable()).thenReturn(false);
        when(mockSnowflake.nextBatch(3)).thenReturn(Flux.just(101L, 102L, 103L));

        BatchIdResponse batch = manager.generateBatch(3).block();
        assertNotNull(batch);
        assertEquals(3, batch.getCount());
        assertEquals(Arrays.asList(101L, 102L, 103L), batch.getIds());
    }

    @Test
    @DisplayName("Should return cluster status correctly")
    void testClusterStatus() {
        ClusterNodeDto status = manager.getClusterStatus();
        assertNotNull(status);
        assertEquals(0, status.getNodeId());
        assertTrue(status.isLeader());
    }
}
