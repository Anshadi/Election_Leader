package com.asthana.Election_Leader;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Registry.ZookeeperNodeRegistry;
import com.asthana.Election_Leader.Strategy.SnowflakeStrategy;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

class SnowflakeStrategyTest {

    @Test
    @DisplayName("High Concurrency: Generate 50,000 IDs across 16 parallel threads with 0 collisions")
    void testConcurrentUniqueIdGeneration() throws InterruptedException {
        AppProperties appProperties = new AppProperties();
        appProperties.setEpochMillis(System.currentTimeMillis() - 5000L);

        ZookeeperNodeRegistry mockRegistry = Mockito.mock(ZookeeperNodeRegistry.class);
        when(mockRegistry.getNodeId()).thenReturn(7);

        SnowflakeStrategy strategy = new SnowflakeStrategy(appProperties, mockRegistry);

        int threadCount = 16;
        int idsPerThread = 3125; // 16 * 3125 = 50,000
        int totalExpectedIds = threadCount * idsPerThread;

        Set<Long> generatedIds = Collections.newSetFromMap(new ConcurrentHashMap<>());
        AtomicBoolean hasError = new AtomicBoolean(false);
        StringBuilder errorLog = new StringBuilder();

        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch finishLatch = new CountDownLatch(threadCount);

        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    startLatch.await();
                    for (int j = 0; j < idsPerThread; j++) {
                        Long id = strategy.nextId().block();
                        if (id == null || id <= 0) {
                            hasError.set(true);
                            errorLog.append("Invalid ID generated: ").append(id).append("\n");
                        } else {
                            generatedIds.add(id);
                        }
                    }
                } catch (Exception e) {
                    hasError.set(true);
                    errorLog.append("Thread error: ").append(e.getMessage()).append("\n");
                } finally {
                    finishLatch.countDown();
                }
            });
        }

        startLatch.countDown(); // Unblock all threads simultaneously
        boolean completed = finishLatch.await(30, TimeUnit.SECONDS);
        executor.shutdown();

        assertTrue(completed, "All threads must complete within timeout");
        assertFalse(hasError.get(), "Thread errors encountered:\n" + errorLog);
        assertEquals(totalExpectedIds, generatedIds.size(), "Zero collision guarantee violated!");
    }
}
