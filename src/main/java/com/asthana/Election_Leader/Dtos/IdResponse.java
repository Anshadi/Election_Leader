package com.asthana.Election_Leader.Dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IdResponse {
    private long id;
    private long timestamp;
    private String dateTime;
    private int nodeId;
    private int sequence;
    private String strategy;
}
