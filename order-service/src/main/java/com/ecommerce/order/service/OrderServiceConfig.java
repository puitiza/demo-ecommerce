package com.ecommerce.order.service;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.client.RestTemplate;

@Configuration
public class OrderServiceConfig {
    @Bean
    @LoadBalanced //This use server-discovery
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder
                .interceptors((request, body, execution) -> {
                    // Extract JWT token from the current security context
                    Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                    if (principal instanceof Jwt jwt) {
                        request.getHeaders().set(HttpHeaders.AUTHORIZATION, "Bearer " + jwt.getTokenValue());
                    }
                    return execution.execute(request, body);
                })
                .build(); // This adds traction interceptors automatically
    }
}