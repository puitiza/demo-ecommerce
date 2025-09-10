package com.ecommerce.order.service;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class OrderServiceConfig {
    @Bean
    @LoadBalanced //This use server-discovery
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build(); // This adds traction interceptors automatically
    }
}