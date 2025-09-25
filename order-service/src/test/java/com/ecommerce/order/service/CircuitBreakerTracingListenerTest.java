package com.ecommerce.order.service;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.circuitbreaker.event.CircuitBreakerOnStateTransitionEvent;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class CircuitBreakerTracingListenerTest {

    private CircuitBreakerTracingListener listener;
    private CircuitBreakerOnStateTransitionEvent event;

    @BeforeEach
    void setUp() {
        CircuitBreakerRegistry registry = CircuitBreakerRegistry.ofDefaults();
        listener = new CircuitBreakerTracingListener(registry);
        event = new CircuitBreakerOnStateTransitionEvent(
                "productServiceCircuit",
                CircuitBreaker.StateTransition.CLOSED_TO_OPEN
        );
    }

    @Test
    void shouldAddAttributesWhenSpanIsValid() {
        Span mockSpan = invokeListener(true);

        verify(mockSpan).setAttribute("circuitbreaker.name", "productServiceCircuit");
        verify(mockSpan).setAttribute("circuitbreaker.state", "OPEN");
    }

    @Test
    void shouldSkipAttributesWhenSpanIsInvalid() {
        Span mockSpan = invokeListener(false);

        verify(mockSpan, never()).setAttribute(anyString(), anyString());
    }

    private Span invokeListener(boolean spanValid) {
        Span mockSpan = mock(Span.class);
        SpanContext mockSpanContext = mock(SpanContext.class);
        when(mockSpan.getSpanContext()).thenReturn(mockSpanContext);
        when(mockSpanContext.isValid()).thenReturn(spanValid);

        try (MockedStatic<Span> spanStatic = mockStatic(Span.class)) {
            spanStatic.when(Span::current).thenReturn(mockSpan);
            listener.addStateToSpan(event);
        }
        return mockSpan;
    }
}
