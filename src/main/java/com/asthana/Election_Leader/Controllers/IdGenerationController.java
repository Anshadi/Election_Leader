package com.asthana.Election_Leader.Controllers;

import com.asthana.Election_Leader.Dtos.BatchIdResponse;
import com.asthana.Election_Leader.Dtos.IdResponse;
import com.asthana.Election_Leader.Dtos.ParsedIdDto;
import com.asthana.Election_Leader.Services.IdGenerationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/id")
@CrossOrigin(origins = "*")
public class IdGenerationController {

    private final IdGenerationService idGenerationService;

    @Autowired
    public IdGenerationController(IdGenerationService idGenerationService) {
        this.idGenerationService = idGenerationService;
    }

    @GetMapping("/next")
    public Mono<IdResponse> getNextId() {
        return idGenerationService.getNextId();
    }

    @GetMapping("/batch")
    public Mono<BatchIdResponse> getBatch(
            @RequestParam(name = "count", defaultValue = "100") int count) {
        return idGenerationService.getBatchIds(count);
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<Long> streamIds(
            @RequestParam(name = "count", defaultValue = "1000") int count) {
        return idGenerationService.streamIds(count);
    }

    @GetMapping("/decode/{id}")
    public Mono<ParsedIdDto> decodeId(@PathVariable("id") long id) {
        return Mono.fromSupplier(() -> idGenerationService.decodeId(id));
    }
}
