package com.asthana.Election_Leader.Utils;

import com.asthana.Election_Leader.Dtos.ParsedIdDto;

import java.time.Instant;
import java.time.format.DateTimeFormatter;

public class IdPacker {

    public static final long SEQUENCE_BITS = 16L;
    public static final long NODE_ID_BITS = 12L;
    public static final long TIMESTAMP_BITS = 35L;

    public static final long MAX_SEQUENCE = (1L << SEQUENCE_BITS) - 1L;   // 65535 (0xFFFF)
    public static final long MAX_NODE_ID = (1L << NODE_ID_BITS) - 1L;     // 4095 (0x0FFF)
    public static final long MAX_TIMESTAMP = (1L << TIMESTAMP_BITS) - 1L; // 34359738367 (0x7FFFFFFFF)

    public static final long NODE_ID_SHIFT = SEQUENCE_BITS;                // 16
    public static final long TIMESTAMP_SHIFT = SEQUENCE_BITS + NODE_ID_BITS; // 28

    private IdPacker() {}

    /**
     * Packs timestampDelta, nodeId, and sequence into a single 64-bit positive long integer.
     */
    public static long pack(long timestampDelta, long nodeId, long sequence) {
        if (timestampDelta < 0 || timestampDelta > MAX_TIMESTAMP) {
            throw new IllegalArgumentException(
                    String.format("Timestamp delta %d out of bounds [0, %d]", timestampDelta, MAX_TIMESTAMP));
        }
        if (nodeId < 0 || nodeId > MAX_NODE_ID) {
            throw new IllegalArgumentException(
                    String.format("Node ID %d out of bounds [0, %d]", nodeId, MAX_NODE_ID));
        }
        if (sequence < 0 || sequence > MAX_SEQUENCE) {
            throw new IllegalArgumentException(
                    String.format("Sequence %d out of bounds [0, %d]", sequence, MAX_SEQUENCE));
        }

        return ((timestampDelta & MAX_TIMESTAMP) << TIMESTAMP_SHIFT)
                | ((nodeId & MAX_NODE_ID) << NODE_ID_SHIFT)
                | (sequence & MAX_SEQUENCE);
    }

    /**
     * Extracts the timestamp delta (milliseconds since epoch) from a packed ID.
     */
    public static long extractTimestampDelta(long id) {
        return (id >>> TIMESTAMP_SHIFT) & MAX_TIMESTAMP;
    }

    /**
     * Computes the absolute UTC epoch timestamp in milliseconds for a packed ID.
     */
    public static long extractAbsoluteTimestamp(long id, long epochMillis) {
        return epochMillis + extractTimestampDelta(id);
    }

    /**
     * Extracts the 12-bit node ID (0-4095) from a packed ID.
     */
    public static int extractNodeId(long id) {
        return (int) ((id >>> NODE_ID_SHIFT) & MAX_NODE_ID);
    }

    /**
     * Extracts the 16-bit sequence (0-65535) from a packed ID.
     */
    public static int extractSequence(long id) {
        return (int) (id & MAX_SEQUENCE);
    }

    /**
     * Unpacks a 64-bit ID into a comprehensive ParsedIdDto.
     */
    public static ParsedIdDto unpack(long id, long epochMillis) {
        long delta = extractTimestampDelta(id);
        long absTime = epochMillis + delta;
        int nodeId = extractNodeId(id);
        int seq = extractSequence(id);

        String isoDate = Instant.ofEpochMilli(absTime).toString();
        String binaryString = toBinaryString64(id);

        return ParsedIdDto.builder()
                .id(id)
                .epochMillis(epochMillis)
                .timestampDelta(delta)
                .absoluteTimestamp(absTime)
                .dateTime(isoDate)
                .nodeId(nodeId)
                .sequence(seq)
                .binaryRepresentation(binaryString)
                .build();
    }

    /**
     * Formats the ID as a 64-character formatted binary string with bit field separators.
     */
    public static String toBinaryString64(long id) {
        StringBuilder sb = new StringBuilder(64);
        for (int i = 63; i >= 0; i--) {
            long bit = (id >>> i) & 1L;
            sb.append(bit);
            if (i == 63 || i == 28 || i == 16) {
                sb.append(" ");
            }
        }
        return sb.toString();
    }
}
