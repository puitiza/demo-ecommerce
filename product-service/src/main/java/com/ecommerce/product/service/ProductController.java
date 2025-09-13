package com.ecommerce.product.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/product")
public class ProductController {
    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    @GetMapping("/test")
    public String test() {
        logger.info("Processing test request in Product Service");
        return "Product Service Response";
    }

    @GetMapping("/test-error")
    public String testError() {
        logger.error("Simulating error in Product Service");
        throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Simulated server error");
    }

    @GetMapping("/test-slow")
    public String testSlow() throws InterruptedException {
        logger.info("Simulating slow response in Product Service");
        Thread.sleep(5000); // Simulate 5-second delay (exceeds 3s TimeLimiter)
        return "Product Service Slow Response";
    }
}