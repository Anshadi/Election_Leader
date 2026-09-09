package com.asthana.Election_Leader;

import com.asthana.Election_Leader.Dtos.ParsedIdDto;
import com.asthana.Election_Leader.Utils.IdPacker;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class IdPackerTest {

    private final long epochMillis = 1700000000000L;

    @Test
    @DisplayName("Should correctly pack and unpack boundary zero values")
    void testBoundaryZero() {
        long packed = IdPacker.pack(0L, 0L, 0L);
        assertEquals(0L, packed);
        assertEquals(0L, IdPacker.extractTimestampDelta(packed));
        assertEquals(0, IdPacker.extractNodeId(packed));
        assertEquals(0, IdPacker.extractSequence(packed));
    }

    @Test
    @DisplayName("Should correctly pack and unpack maximum 63-bit values")
    void testBoundaryMax() {
        long maxTimestamp = IdPacker.MAX_TIMESTAMP;
        long maxNodeId = IdPacker.MAX_NODE_ID;
        long maxSequence = IdPacker.MAX_SEQUENCE;

        long packed = IdPacker.pack(maxTimestamp, maxNodeId, maxSequence);
        assertTrue(packed > 0, "63-bit packed long must remain positive");

        assertEquals(maxTimestamp, IdPacker.extractTimestampDelta(packed));
        assertEquals(maxNodeId, IdPacker.extractNodeId(packed));
        assertEquals(maxSequence, IdPacker.extractSequence(packed));
    }

    @Test
    @DisplayName("Should unpack into ParsedIdDto accurately")
    void testUnpackDto() {
        long delta = 5000L;
        long nodeId = 42L;
        long seq = 128L;

        long packed = IdPacker.pack(delta, nodeId, seq);
        ParsedIdDto dto = IdPacker.unpack(packed, epochMillis);

        assertEquals(packed, dto.getId());
        assertEquals(delta, dto.getTimestampDelta());
        assertEquals(epochMillis + delta, dto.getAbsoluteTimestamp());
        assertEquals(42, dto.getNodeId());
        assertEquals(128, dto.getSequence());
        assertNotNull(dto.getDateTime());
        assertNotNull(dto.getBinaryRepresentation());
    }

    @Test
    @DisplayName("Should throw IllegalArgumentException on out-of-bounds inputs")
    void testOutOfBounds() {
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(-1L, 0, 0));
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(IdPacker.MAX_TIMESTAMP + 1, 0, 0));
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(0, -1, 0));
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(0, IdPacker.MAX_NODE_ID + 1, 0));
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(0, 0, -1));
        assertThrows(IllegalArgumentException.class, () -> IdPacker.pack(0, 0, IdPacker.MAX_SEQUENCE + 1));
    }
}
