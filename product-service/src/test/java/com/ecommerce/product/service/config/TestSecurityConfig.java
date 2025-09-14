package com.ecommerce.product.service.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;

import java.time.Instant;
import java.util.Collections;

@TestConfiguration
public class TestSecurityConfig {

    @Bean
    public JwtDecoder jwtDecoder() {
        return token -> new Jwt(
                token,
                Instant.now(),
                Instant.now().plusSeconds(3600),
                Collections.singletonMap("alg", "none"),
                Collections.singletonMap("sub", "test-user")
        );
    }
}
