package com.ecommerce.order.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/order")
public class OrderController {
    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);

    private final RestTemplate restTemplate;

    public OrderController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @GetMapping("/test")
    public String test() {
        logger.info("Processing test request in Order Service");
        // Call product-service
        String productResponse = restTemplate.getForObject("http://product-service/product/test", String.class);
        logger.info("Received response from Product Service: {}", productResponse);
        return "Order Service Response -> " + productResponse;
    }
}