package com.ecommerce.order.service;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.circuitbreaker.event.CircuitBreakerOnStateTransitionEvent;
import io.opentelemetry.api.trace.Span;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

//if you want to add circuitbreaker in your traceability
@Configuration
public class CircuitBreakerTracingListener {

    private final CircuitBreaker circuitBreaker;

    public CircuitBreakerTracingListener(CircuitBreakerRegistry registry) {
        // Listen to the breakfast you defined in application.yml
        this.circuitBreaker = registry.circuitBreaker("productServiceCircuit");
    }

    @PostConstruct
    public void init() {
        circuitBreaker.getEventPublisher()
                .onStateTransition(this::addStateToSpan);
    }


    private void addStateToSpan(CircuitBreakerOnStateTransitionEvent event) {
        Span span = Span.current();
        if (span != null && span.getSpanContext().isValid()) {
            span.setAttribute("circuitbreaker.name", event.getCircuitBreakerName());
            span.setAttribute("circuitbreaker.state", event.getStateTransition().getToState().name());
        }
    }
}