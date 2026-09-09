package com.asthana.Election_Leader.Registry;

import com.asthana.Election_Leader.Configs.AppProperties;
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ZookeeperConfig {

    private static final Logger log = LoggerFactory.getLogger(ZookeeperConfig.class);

    @Bean(destroyMethod = "close")
    @ConditionalOnProperty(prefix = "adaptive.zookeeper", name = "enabled", havingValue = "true")
    public CuratorFramework curatorFramework(AppProperties appProperties) {
        AppProperties.Zookeeper zkProps = appProperties.getZookeeper();
        log.info("Initializing ZooKeeper CuratorFramework connecting to: {}", zkProps.getConnectString());

        CuratorFramework client = CuratorFrameworkFactory.builder()
                .connectString(zkProps.getConnectString())
                .sessionTimeoutMs(zkProps.getSessionTimeoutMs())
                .connectionTimeoutMs(zkProps.getConnectionTimeoutMs())
                .retryPolicy(new ExponentialBackoffRetry(zkProps.getBaseSleepTimeMs(), zkProps.getMaxRetries()))
                .build();

        try {
            client.start();
            boolean connected = client.blockUntilConnected(
                    Math.min(zkProps.getConnectionTimeoutMs(), 3000),
                    java.util.concurrent.TimeUnit.MILLISECONDS
            );
            if (connected) {
                log.info("Successfully connected to ZooKeeper at {}", zkProps.getConnectString());
            } else {
                log.warn("ZooKeeper not reachable within timeout. Falling back to local/standalone mode.");
            }
        } catch (Exception e) {
            log.warn("Failed to connect to ZooKeeper: {}. Running in standalone mode.", e.getMessage());
        }

        return client;
    }
}
