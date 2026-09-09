package com.asthana.Election_Leader.Registry;

import com.asthana.Election_Leader.Configs.AppProperties;
import com.asthana.Election_Leader.Exceptions.NodeAllocationException;
import com.asthana.Election_Leader.Utils.IdPacker;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.state.ConnectionState;
import org.apache.curator.framework.state.ConnectionStateListener;
import org.apache.zookeeper.CreateMode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Component
public class ZookeeperNodeRegistry {

    private static final Logger log = LoggerFactory.getLogger(ZookeeperNodeRegistry.class);

    private final AppProperties appProperties;
    private final Optional<CuratorFramework> curatorClientOptional;

    private int allocatedNodeId;
    private String registeredPath;
    private volatile boolean isConnected = false;

    @Autowired
    public ZookeeperNodeRegistry(AppProperties appProperties, Optional<CuratorFramework> curatorFramework) {
        this.appProperties = appProperties;
        this.curatorClientOptional = curatorFramework;
        this.allocatedNodeId = appProperties.getNodeId();
    }

    @PostConstruct
    public void init() {
        if (curatorClientOptional.isPresent() && curatorClientOptional.get().getZookeeperClient().isConnected()) {
            CuratorFramework client = curatorClientOptional.get();
            try {
                registerWithZookeeper(client);
                isConnected = true;
            } catch (Exception e) {
                log.error("Failed to dynamically register node with ZooKeeper. Falling back to static nodeId={}",
                        appProperties.getNodeId(), e);
                allocatedNodeId = appProperties.getNodeId();
            }
        } else {
            log.info("ZooKeeper registry inactive. Using static nodeId={}", appProperties.getNodeId());
            allocatedNodeId = appProperties.getNodeId();
        }
    }

    private synchronized void registerWithZookeeper(CuratorFramework client) throws Exception {
        String nodesParentPath = appProperties.getZookeeper().getBasePath() + "/nodes";
        if (client.checkExists().forPath(nodesParentPath) == null) {
            client.create().creatingParentsIfNeeded().forPath(nodesParentPath);
        }

        String nodePrefix = nodesParentPath + "/node-";
        byte[] payload = ("node-info-" + System.currentTimeMillis()).getBytes(StandardCharsets.UTF_8);

        registeredPath = client.create()
                .withMode(CreateMode.EPHEMERAL_SEQUENTIAL)
                .forPath(nodePrefix, payload);

        // Extract sequential suffix, e.g. /election-leader/nodes/node-0000000042 -> 42
        String seqString = registeredPath.substring(nodePrefix.length());
        long seq = Long.parseLong(seqString);
        int computedNodeId = (int) (seq % (IdPacker.MAX_NODE_ID + 1));

        this.allocatedNodeId = computedNodeId;
        log.info("Successfully registered in ZooKeeper at {}. Allocated dynamic nodeId={}", registeredPath, allocatedNodeId);

        client.getConnectionStateListenable().addListener(new ConnectionStateListener() {
            @Override
            public void stateChanged(CuratorFramework curatorFramework, ConnectionState connectionState) {
                log.warn("ZooKeeper Connection state changed to: {}", connectionState);
                if (connectionState == ConnectionState.LOST) {
                    isConnected = false;
                } else if (connectionState == ConnectionState.RECONNECTED) {
                    isConnected = true;
                    try {
                        registerWithZookeeper(client);
                    } catch (Exception ex) {
                        log.error("Failed to re-register with ZooKeeper after reconnection", ex);
                    }
                }
            }
        });
    }

    @PreDestroy
    public void shutdown() {
        if (curatorClientOptional.isPresent() && registeredPath != null) {
            try {
                CuratorFramework client = curatorClientOptional.get();
                if (client.checkExists().forPath(registeredPath) != null) {
                    client.delete().guaranteed().forPath(registeredPath);
                    log.info("Successfully unregistered node path {}", registeredPath);
                }
            } catch (Exception e) {
                log.warn("Error unregistering ZooKeeper node path {}: {}", registeredPath, e.getMessage());
            }
        }
    }

    public int getNodeId() {
        return allocatedNodeId;
    }

    public boolean isConnected() {
        return isConnected && curatorClientOptional.isPresent() &&
                curatorClientOptional.get().getZookeeperClient().isConnected();
    }

    public List<String> getRegisteredNodes() {
        if (isConnected() && curatorClientOptional.isPresent()) {
            try {
                String nodesParentPath = appProperties.getZookeeper().getBasePath() + "/nodes";
                CuratorFramework client = curatorClientOptional.get();
                if (client.checkExists().forPath(nodesParentPath) != null) {
                    return client.getChildren().forPath(nodesParentPath);
                }
            } catch (Exception e) {
                log.warn("Could not retrieve active nodes from ZooKeeper: {}", e.getMessage());
            }
        }
        return Collections.singletonList("local-node-" + allocatedNodeId);
    }
}
