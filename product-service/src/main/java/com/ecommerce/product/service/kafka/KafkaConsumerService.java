package com.ecommerce.product.service.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumerService {

    private static final Logger logger = LoggerFactory.getLogger(KafkaConsumerService.class);
    private static final String TOPIC = "order-events";

    @KafkaListener(topics = TOPIC)
    public void consume(@Header(name = KafkaHeaders.RECEIVED_KEY, required = false) String key,
                        @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
                        String message) {
        logger.info("Consumed message from Kafka topic '{}', key={}, partition={}: {}",
                TOPIC, key, partition, message);
    }

}
