package com.asthana.Election_Leader.Strategy;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface IdGeneratorStrategy {

    /**
     * Generates a single globally unique 64-bit ID.
     */
    Mono<Long> nextId();

    /**
     * Generates a batch of unique 64-bit IDs in bulk.
     *
     * @param count number of IDs to generate
     */
    Flux<Long> nextBatch(int count);

    /**
     * Returns the unique identifier/name for this strategy.
     */
    String getStrategyName();

    /**
     * Checks if this strategy is healthy and ready to generate IDs.
     */
    boolean isAvailable();
}
