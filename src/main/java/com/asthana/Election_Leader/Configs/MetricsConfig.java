package com.asthana.Election_Leader.Configs;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MetricsConfig {

    @Bean
    public Counter idGenerationSuccessCounter(MeterRegistry registry) {
        return Counter.builder("election_leader_ids_generated_total")
                .description("Total count of unique IDs successfully generated")
                .tag("status", "success")
                .register(registry);
    }

    @Bean
    public Counter idGenerationFallbackCounter(MeterRegistry registry) {
        return Counter.builder("election_leader_strategy_fallback_total")
                .description("Total count of failovers from Redis to Snowflake fallback")
                .tag("status", "fallback")
                .register(registry);
    }

    @Bean
    public Timer idGenerationTimer(MeterRegistry registry) {
        return Timer.builder("election_leader_generation_duration_seconds")
                .description("Time taken to generate IDs across strategies")
                .publishPercentiles(0.5, 0.9, 0.99, 0.999)
                .register(registry);
    }
}
