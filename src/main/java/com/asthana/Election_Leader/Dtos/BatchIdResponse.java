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
public class BatchIdResponse {
    private List<Long> ids;
    private int count;
    private String strategy;
    private double durationMicros;
}
