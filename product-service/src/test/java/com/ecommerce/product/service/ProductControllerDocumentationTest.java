package com.ecommerce.product.service;

import com.ecommerce.product.service.config.TestSecurityConfig;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.restdocs.AutoConfigureRestDocs;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.restdocs.RestDocumentationExtension;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.restdocs.mockmvc.MockMvcRestDocumentation.document;
import static org.springframework.restdocs.operation.preprocess.Preprocessors.*;
import static org.springframework.restdocs.headers.HeaderDocumentation.headerWithName;
import static org.springframework.restdocs.headers.HeaderDocumentation.requestHeaders;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
@AutoConfigureRestDocs //(outputDir = "build/generated-snippets")
@ExtendWith(RestDocumentationExtension.class)
@Import(TestSecurityConfig.class)
class ProductControllerDocumentationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testProductEndpoint() throws Exception {
        this.mockMvc.perform(get("/product/test")
                        .with(jwt()
                                .jwt(jwt -> jwt.tokenValue("mock-jwt-token"))
                                .authorities(new SimpleGrantedAuthority("ROLE_USER")))
                        .header("Authorization", "Bearer mock-jwt-token"))
                .andExpect(status().isOk())
                .andDo(document("product-test",
                        preprocessRequest(prettyPrint()),
                        preprocessResponse(prettyPrint()),
                        requestHeaders(
                                headerWithName("Authorization").description("Bearer token for OAuth2 authentication")
                        )
                ));
    }

    @Test
    void testProductErrorEndpoint() throws Exception {
        this.mockMvc.perform(get("/product/test-error")
                        .with(jwt()
                                .jwt(jwt -> jwt.tokenValue("mock-jwt-token"))
                                .authorities(new SimpleGrantedAuthority("ROLE_USER")))
                        .header("Authorization", "Bearer mock-jwt-token"))
                .andExpect(status().is5xxServerError())
                .andDo(document("product-test-error",
                        preprocessRequest(prettyPrint()),
                        preprocessResponse(prettyPrint()),
                        requestHeaders(
                                headerWithName("Authorization").description("Bearer token for OAuth2 authentication")
                        )
                ));
    }

    @Test
    void testProductSlowEndpoint() throws Exception {
        this.mockMvc.perform(get("/product/test-slow")
                        .with(jwt()
                                .jwt(jwt -> jwt.tokenValue("mock-jwt-token"))
                                .authorities(new SimpleGrantedAuthority("ROLE_USER")))
                        .header("Authorization", "Bearer mock-jwt-token"))
                .andExpect(status().isOk())
                .andDo(document("product-test-slow",
                        preprocessRequest(prettyPrint()),
                        preprocessResponse(prettyPrint()),
                        requestHeaders(
                                headerWithName("Authorization").description("Bearer token for OAuth2 authentication")
                        )
                ));
    }
}
