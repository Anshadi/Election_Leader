package com.asthana.Election_Leader.Configs;

import com.asthana.Election_Leader.Utils.IdPacker;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "adaptive")
public class AppProperties {

    private long epochMillis = 1780000000000L;
    private int nodeId = 0;
    private String strategy = "AUTO";

    private Redis redis = new Redis();
    private Zookeeper zookeeper = new Zookeeper();

    public long getEpochMillis() {
        // If configured epoch is too far in the past (> 35-bit span), align to modern epoch
        long now = System.currentTimeMillis();
        if (epochMillis <= 0 || (now - epochMillis) > IdPacker.MAX_TIMESTAMP || now < epochMillis) {
            return 1780000000000L;
        }
        return epochMillis;
    }

    public void setEpochMillis(long epochMillis) {
        this.epochMillis = epochMillis;
    }

    public int getNodeId() {
        return nodeId;
    }

    public void setNodeId(int nodeId) {
        this.nodeId = nodeId;
    }

    public String getStrategy() {
        return strategy;
    }

    public void setStrategy(String strategy) {
        this.strategy = strategy;
    }

    public Redis getRedis() {
        return redis;
    }

    public void setRedis(Redis redis) {
        this.redis = redis;
    }

    public Zookeeper getZookeeper() {
        return zookeeper;
    }

    public void setZookeeper(Zookeeper zookeeper) {
        this.zookeeper = zookeeper;
    }

    public static class Redis {
        private String key = "adaptive:id:block";
        private int baseBlockSize = 1024;
        private int minBlockSize = 256;
        private int maxBlockSize = 1048576;
        private double refillThresholdRatio = 0.2; // 20%

        public String getKey() {
            return key;
        }

        public void setKey(String key) {
            this.key = key;
        }

        public int getBaseBlockSize() {
            return baseBlockSize;
        }

        public void setBaseBlockSize(int baseBlockSize) {
            this.baseBlockSize = baseBlockSize;
        }

        public int getMinBlockSize() {
            return minBlockSize;
        }

        public void setMinBlockSize(int minBlockSize) {
            this.minBlockSize = minBlockSize;
        }

        public int getMaxBlockSize() {
            return maxBlockSize;
        }

        public void setMaxBlockSize(int maxBlockSize) {
            this.maxBlockSize = maxBlockSize;
        }

        public double getRefillThresholdRatio() {
            return refillThresholdRatio;
        }

        public void setRefillThresholdRatio(double refillThresholdRatio) {
            this.refillThresholdRatio = refillThresholdRatio;
        }
    }

    public static class Zookeeper {
        private boolean enabled = false;
        private String connectString = "localhost:2181";
        private int sessionTimeoutMs = 60000;
        private int connectionTimeoutMs = 5000;
        private int baseSleepTimeMs = 1000;
        private int maxRetries = 3;
        private String basePath = "/election-leader";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getConnectString() {
            return connectString;
        }

        public void setConnectString(String connectString) {
            this.connectString = connectString;
        }

        public int getSessionTimeoutMs() {
            return sessionTimeoutMs;
        }

        public void setSessionTimeoutMs(int sessionTimeoutMs) {
            this.sessionTimeoutMs = sessionTimeoutMs;
        }

        public int getConnectionTimeoutMs() {
            return connectionTimeoutMs;
        }

        public void setConnectionTimeoutMs(int connectionTimeoutMs) {
            this.connectionTimeoutMs = connectionTimeoutMs;
        }

        public int getBaseSleepTimeMs() {
            return baseSleepTimeMs;
        }

        public void setBaseSleepTimeMs(int baseSleepTimeMs) {
            this.baseSleepTimeMs = baseSleepTimeMs;
        }

        public int getMaxRetries() {
            return maxRetries;
        }

        public void setMaxRetries(int maxRetries) {
            this.maxRetries = maxRetries;
        }

        public String getBasePath() {
            return basePath;
        }

        public void setBasePath(String basePath) {
            this.basePath = basePath;
        }
    }
}
