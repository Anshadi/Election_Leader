package com.asthana.Election_Leader.Utils;

import com.asthana.Election_Leader.Exceptions.ClockDriftException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ClockDriftHandler {

    private static final Logger log = LoggerFactory.getLogger(ClockDriftHandler.class);
    private static final long MAX_TOLERABLE_BACKWARD_DRIFT_MS = 5L;

    private ClockDriftHandler() {}

    /**
     * Checks if current timestamp is behind last timestamp.
     * If backward drift is small (<= 5ms), sleeps/spins until clock catches up.
     * If backward drift exceeds 5ms, throws ClockDriftException.
     */
    public static long handleBackwardDrift(long currentTimestamp, long lastTimestamp) {
        if (currentTimestamp < lastTimestamp) {
            long offset = lastTimestamp - currentTimestamp;
            if (offset <= MAX_TOLERABLE_BACKWARD_DRIFT_MS) {
                log.warn("Clock moved backwards by {} ms (tolerable). Waiting for clock to catch up...", offset);
                try {
                    Thread.sleep(offset);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    throw new ClockDriftException("Thread interrupted while waiting for clock synchronization");
                }
                currentTimestamp = System.currentTimeMillis();
                if (currentTimestamp < lastTimestamp) {
                    throw new ClockDriftException(
                            String.format("Clock is still behind after waiting. Current: %d, Last: %d", currentTimestamp, lastTimestamp));
                }
            } else {
                throw new ClockDriftException(
                        String.format("Clock moved backwards by %d ms, which exceeds tolerable threshold of %d ms. Refusing to generate ID.",
                                offset, MAX_TOLERABLE_BACKWARD_DRIFT_MS));
            }
        }
        return currentTimestamp;
    }

    /**
     * Spins/waits until next millisecond is reached.
     */
    public static long tillNextMillis(long lastTimestamp) {
        long timestamp = System.currentTimeMillis();
        while (timestamp <= lastTimestamp) {
            Thread.onSpinWait();
            timestamp = System.currentTimeMillis();
        }
        return timestamp;
    }
}
