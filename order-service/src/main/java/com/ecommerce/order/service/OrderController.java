package com.ecommerce.order.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/order")
public class OrderController {

    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);
    private static final String TOPIC = "order-events";

    private static final String CIRCUIT_BREAKER_NAME = "productServiceCircuit";

    private final RestTemplate restTemplate;
    private final KafkaTemplate<String, String> kafkaTemplate;

    public OrderController(RestTemplate restTemplate, KafkaTemplate<String, String> kafkaTemplate) {
        this.restTemplate = restTemplate;
        this.kafkaTemplate = kafkaTemplate;
    }

    @GetMapping("/test")
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME, fallbackMethod = "fallbackProductService")
    public String test(@RequestParam(defaultValue = "test") String endpoint) {
        logger.info("Processing test request in Order Service, endpoint: {}", endpoint);
        // Call Product-Service via HTTP
        String productResponse = restTemplate.getForObject("http://product-service/product/" + endpoint, String.class);
        logger.info("Received response from Product Service: {}", productResponse);

        // Publish event to Kafka
        String eventMessage = "Order processed with product response: " + productResponse;
        kafkaTemplate.send(TOPIC, eventMessage);
        logger.info("Published event to Kafka topic '{}': {}", TOPIC, eventMessage);

        return "Order Service Response -> " + productResponse;
    }

    @SuppressWarnings("unused")
    public String fallbackProductService(String endpoint, Throwable t) {
        logger.error("Circuit breaker fallback triggered for endpoint {}: {}", endpoint, t.getMessage());
        String fallbackMessage = "Product Service unavailable for endpoint " + endpoint + ", using fallback response";
        kafkaTemplate.send(TOPIC, fallbackMessage);
        return "Order Service Response -> Fallback due to: " + t.getMessage();
    }
}