#!/bin/bash
# ./verify.sh
# Validates the full PoC stack: healths, auth, API, Kafka.

set -e  # Exit on any error

echo "=== Verifying health endpoints ==="
curl -f http://localhost:8090/actuator/health || { echo "Gateway health failed"; exit 1; }
curl -f http://localhost:8081/actuator/health || { echo "Product service health failed"; exit 1; }
curl -f http://localhost:8082/actuator/health || { echo "Order service health failed"; exit 1; }
curl -f http://localhost:8761/actuator/health || { echo "Discovery health failed"; exit 1; }
curl -f http://localhost:8885/actuator/health || { echo "Config server health failed"; exit 1; }
echo "All health checks passed!"

echo "=== Testing Keycloak auth ==="
# Fetch JWT token (update client_id, username, password as per your realm setup)
TOKEN=$(curl -s -X POST http://localhost:8080/realms/demo-ecommerce/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=demo-client&username=user&password=pass&grant_type=password" | jq -r .access_token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Auth token fetch failed"
    exit 1
fi
echo "Auth token obtained successfully (length: ${#TOKEN})"

echo "=== Testing API with auth (via Gateway) ==="
curl -f -H "Authorization: Bearer $TOKEN" http://localhost:8090/api/products || { echo "Products API failed"; exit 1; }
echo "API call succeeded!"

echo "=== Verifying Kafka topics ==="
# Check for a sample topic (e.g., 'order-topic' from your setup; adjust if needed)
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -q "order-topic" || { echo "Kafka topic missing"; exit 1; }
echo "Kafka topic verified!"

echo "=== PoC stack is fully functional! ==="