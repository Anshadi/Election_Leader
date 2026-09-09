package com.asthana.Election_Leader.Exceptions;

public class ClockDriftException extends RuntimeException {
    public ClockDriftException(String message) {
        super(message);
    }
}
