package com.ecommerce.product.service;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

@Component
public class TestKafkaListener {

    private final CountDownLatch latch = new CountDownLatch(1);
    private final AtomicReference<String> payload = new AtomicReference<>();

    @KafkaListener(topics = "order-events", groupId = "test-consumer")
    public void listen(@Payload String message) {
        payload.set(message);
        latch.countDown();
    }

    public CountDownLatch getLatch() {
        return latch;
    }

    public AtomicReference<String> getPayload() {
        return payload;
    }
}

