package com.ecommerce.order.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/order")
public class OrderController {
    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);
    private static final String TOPIC = "order-events";

    private final RestTemplate restTemplate;
    private final KafkaTemplate<String, String> kafkaTemplate;

    public OrderController(RestTemplate restTemplate, KafkaTemplate<String, String> kafkaTemplate) {
        this.restTemplate = restTemplate;
        this.kafkaTemplate = kafkaTemplate;
    }

    @GetMapping("/test")
    public String test() {
        logger.info("Processing test request in Order Service");
        // Call Product-Service via HTTP
        String productResponse = restTemplate.getForObject("http://product-service/product/test", String.class);
        logger.info("Received response from Product Service: {}", productResponse);

        // Publish event to Kafka
        String eventMessage = "Order processed with product response: " + productResponse;
        kafkaTemplate.send(TOPIC, eventMessage);
        logger.info("Published event to Kafka topic '{}': {}", TOPIC, eventMessage);

        return "Order Service Response -> " + productResponse;
    }
}