package com.asthana.Election_Leader.Dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClusterNodeDto {
    private int nodeId;
    private boolean isLeader;
    private boolean zookeeperConnected;
    private boolean redisConnected;
    private String activeStrategy;
    private long epochMillis;
    private List<String> registeredNodes;
}
