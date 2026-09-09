package com.asthana.Election_Leader.Exceptions;

public class NodeAllocationException extends RuntimeException {
    public NodeAllocationException(String message) {
        super(message);
    }

    public NodeAllocationException(String message, Throwable cause) {
        super(message, cause);
    }
}
