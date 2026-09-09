package com.asthana.Election_Leader.Registry;

import com.asthana.Election_Leader.Configs.AppProperties;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.recipes.leader.LeaderLatch;
import org.apache.curator.framework.recipes.leader.LeaderLatchListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class ZookeeperLeaderElection {

    private static final Logger log = LoggerFactory.getLogger(ZookeeperLeaderElection.class);

    private final AppProperties appProperties;
    private final Optional<CuratorFramework> curatorFrameworkOptional;
    private LeaderLatch leaderLatch;
    private volatile boolean isLeader = false;

    @Autowired
    public ZookeeperLeaderElection(AppProperties appProperties, Optional<CuratorFramework> curatorFramework) {
        this.appProperties = appProperties;
        this.curatorFrameworkOptional = curatorFramework;
    }

    @PostConstruct
    public void init() {
        if (curatorFrameworkOptional.isPresent() && curatorFrameworkOptional.get().getZookeeperClient().isConnected()) {
            try {
                String leaderPath = appProperties.getZookeeper().getBasePath() + "/leader";
                String id = "node-" + appProperties.getNodeId() + "-" + System.currentTimeMillis();
                leaderLatch = new LeaderLatch(curatorFrameworkOptional.get(), leaderPath, id);
                leaderLatch.addListener(new LeaderLatchListener() {
                    @Override
                    public void isLeader() {
                        isLeader = true;
                        log.info(">>> [LEADER ELECTION] This node has been ELECTED CLUSTER LEADER! <<<");
                    }

                    @Override
                    public void notLeader() {
                        isLeader = false;
                        log.info(">>> [LEADER ELECTION] This node is NOT the cluster leader (Standby/Worker). <<<");
                    }
                });
                leaderLatch.start();
                log.info("Started ZooKeeper LeaderLatch on {}", leaderPath);
            } catch (Exception e) {
                log.warn("Failed to initialize ZooKeeper LeaderLatch: {}. Defaulting to standalone leader.", e.getMessage());
                isLeader = true; // In standalone single-node mode, this node is its own leader
            }
        } else {
            // Standalone single node
            isLeader = true;
            log.info("ZooKeeper inactive. Running in standalone single-instance mode (Acting Leader).");
        }
    }

    @PreDestroy
    public void shutdown() {
        if (leaderLatch != null) {
            try {
                leaderLatch.close();
                log.info("Closed ZooKeeper LeaderLatch.");
            } catch (Exception e) {
                log.warn("Error closing LeaderLatch: {}", e.getMessage());
            }
        }
    }

    public boolean isLeader() {
        if (leaderLatch != null && leaderLatch.getState() == LeaderLatch.State.STARTED) {
            return leaderLatch.hasLeadership();
        }
        return isLeader;
    }

    public String getLeaderId() {
        if (leaderLatch != null && leaderLatch.getState() == LeaderLatch.State.STARTED) {
            try {
                return leaderLatch.getLeader().getId();
            } catch (Exception e) {
                return "unknown";
            }
        }
        return "local-node-" + appProperties.getNodeId();
    }
}
