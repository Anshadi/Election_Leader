package com.asthana.Election_Leader.Dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParsedIdDto {
    private long id;
    private long epochMillis;
    private long timestampDelta;
    private long absoluteTimestamp;
    private String dateTime;
    private int nodeId;
    private int sequence;
    private String binaryRepresentation;
}
