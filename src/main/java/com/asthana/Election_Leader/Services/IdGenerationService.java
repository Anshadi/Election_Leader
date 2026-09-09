package com.asthana.Election_Leader.Services;

import com.asthana.Election_Leader.Dtos.BatchIdResponse;
import com.asthana.Election_Leader.Dtos.IdResponse;
import com.asthana.Election_Leader.Dtos.ParsedIdDto;
import com.asthana.Election_Leader.Manager.AdaptiveIdManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class IdGenerationService {

    private final AdaptiveIdManager idManager;

    @Autowired
    public IdGenerationService(AdaptiveIdManager idManager) {
        this.idManager = idManager;
    }

    public Mono<IdResponse> getNextId() {
        return idManager.generateNextId();
    }

    public Mono<BatchIdResponse> getBatchIds(int count) {
        int boundedCount = Math.min(Math.max(1, count), 100_000);
        return idManager.generateBatch(boundedCount);
    }

    public Flux<Long> streamIds(int count) {
        int boundedCount = Math.min(Math.max(1, count), 1_000_000);
        return idManager.streamIds(boundedCount);
    }

    public ParsedIdDto decodeId(long id) {
        return idManager.decodeId(id);
    }
}
