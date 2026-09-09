package com.asthana.Election_Leader.Services;

import com.asthana.Election_Leader.Dtos.ClusterNodeDto;
import com.asthana.Election_Leader.Dtos.LatencyMetricsDto;
import com.asthana.Election_Leader.Manager.AdaptiveIdManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ClusterService {

    private final AdaptiveIdManager idManager;

    @Autowired
    public ClusterService(AdaptiveIdManager idManager) {
        this.idManager = idManager;
    }

    public ClusterNodeDto getClusterStatus() {
        return idManager.getClusterStatus();
    }

    public LatencyMetricsDto getLatencyMetrics() {
        return idManager.getLatencyMetrics();
    }
}
