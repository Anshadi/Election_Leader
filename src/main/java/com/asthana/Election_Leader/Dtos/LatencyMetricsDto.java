package com.asthana.Election_Leader.Dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LatencyMetricsDto {
    private long totalGenerated;
    private double p50Micros;
    private double p90Micros;
    private double p99Micros;
    private double p999Micros;
    private double maxMicros;
    private double meanMicros;
}
