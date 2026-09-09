package com.asthana.Election_Leader.Controllers;

import com.asthana.Election_Leader.Dtos.ClusterNodeDto;
import com.asthana.Election_Leader.Dtos.LatencyMetricsDto;
import com.asthana.Election_Leader.Services.ClusterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
public class ClusterController {

    private final ClusterService clusterService;

    @Autowired
    public ClusterController(ClusterService clusterService) {
        this.clusterService = clusterService;
    }

    @GetMapping("/cluster/status")
    public Mono<ClusterNodeDto> getClusterStatus() {
        return Mono.fromSupplier(clusterService::getClusterStatus);
    }

    @GetMapping("/metrics/latency")
    public Mono<LatencyMetricsDto> getLatencyMetrics() {
        return Mono.fromSupplier(clusterService::getLatencyMetrics);
    }
}
