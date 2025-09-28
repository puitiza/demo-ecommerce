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
# Keycloak config (from your realm: confidential client with service accounts)
CLIENT_ID="gateway-service"
CLIENT_SECRET="3rElcTH0OSsRZmdw9ubeaf9Pob6D7Ake"

# Fetch JWT token via client_credentials (M2M, no user needed)
TOKEN=$(curl -s -X POST http://localhost:8080/realms/demo-ecommerce/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" | jq -r '.access_token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ Auth token fetch failed. Full response:"
    curl -s -X POST http://localhost:8080/realms/demo-ecommerce/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "grant_type=client_credentials" \
      -d "client_id=$CLIENT_ID" \
      -d "client_secret=$CLIENT_SECRET"
    exit 1
fi
echo "✅ Auth token obtained successfully (length: ${#TOKEN})"

echo "=== Testing API with auth (via Gateway) ==="
# Use valid routed path: /product/test → lb://product-service /product/test
if ! curl -f -v -H "Authorization: Bearer $TOKEN" http://localhost:8090/product/test; then
    echo "Products API failed (verbose log above). Token claims for debug:"
    echo "$TOKEN" | jq -r '. | {sub: .sub, aud: .aud, scope: .scope, iss: .iss}'  # Decode JWT header (assumes jq can parse base64)
    exit 1
fi
echo "API call succeeded!"

echo "=== Verifying Kafka topics ==="
# Check for a sample topic (e.g., 'order-topic' from your setup; adjust if needed)
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -q "order-topic" || { echo "Kafka topic missing"; exit 1; }
echo "Kafka topic verified!"

echo "=== PoC stack is fully functional! ==="