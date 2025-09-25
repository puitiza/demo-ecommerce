package com.ecommerce.order.service;

import com.ecommerce.order.service.config.TestSecurityConfig;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.restdocs.AutoConfigureRestDocs;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.restdocs.RestDocumentationExtension;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.AssertionsForClassTypes.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.restdocs.headers.HeaderDocumentation.headerWithName;
import static org.springframework.restdocs.headers.HeaderDocumentation.requestHeaders;
import static org.springframework.restdocs.mockmvc.MockMvcRestDocumentation.document;
import static org.springframework.restdocs.operation.preprocess.Preprocessors.*;
import static org.springframework.restdocs.payload.PayloadDocumentation.responseBody;
import static org.springframework.restdocs.request.RequestDocumentation.parameterWithName;
import static org.springframework.restdocs.request.RequestDocumentation.queryParameters;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(OrderController.class)
@AutoConfigureRestDocs //(outputDir = "target/generated-snippets")
@ExtendWith(RestDocumentationExtension.class)
@Import(TestSecurityConfig.class)
class OrderControllerDocumentationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderController controller;

    @MockitoBean
    private KafkaTemplate<String, String> kafkaTemplate;

    @MockitoBean
    private RestTemplate restTemplate;

    @Test
    void testOrderEndpoint() throws Exception {
        when(kafkaTemplate.send(any(String.class), any(String.class))).thenReturn(null);
        when(restTemplate.getForObject(any(String.class), eq(String.class)))
                .thenReturn("Response from Product Service");

        this.mockMvc.perform(get("/order/test")
                        .param("endpoint", "test")
                        .with(jwt()
                                .jwt(jwt -> jwt.tokenValue("mock-jwt-token"))
                                .authorities(new SimpleGrantedAuthority("ROLE_USER")))
                        .header("Authorization", "Bearer mock-jwt-token"))
                .andExpect(status().isOk())
                .andDo(document("order-test",
                        preprocessRequest(prettyPrint()),
                        preprocessResponse(prettyPrint()),
                        queryParameters(
                                parameterWithName("endpoint").description("The endpoint to test communication with Product Service")
                        ),
                        requestHeaders(
                                headerWithName("Authorization").description("Bearer token for OAuth2 authentication")
                        ),
                        responseBody()
                ));
    }

    @Test
    void shouldHandleFallbackProductService() {
        // Arrange
        String endpoint = "test";
        RuntimeException throwable = new RuntimeException("Service down");

        // Act
        String result = controller.fallbackProductService(endpoint, throwable);

        // Assert
        assertThat(result).isEqualTo("Order Service Response -> Fallback due to: Service down");

        verify(kafkaTemplate).send("order-events", "Product Service unavailable for endpoint test, using fallback response");

    }
}