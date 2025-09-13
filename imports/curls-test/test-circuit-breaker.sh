#!/bin/bash

# ============================
# 🔑 Keycloak config
# ============================
CLIENT_ID="gateway-service"
CLIENT_SECRET="3rElcTH0OSsRZmdw9ubeaf9Pob6D7Ake"

# ============================
# 🛡️ Get JWT dynamically (inside container)
# ============================
JWT_TOKEN=$(docker exec -i server-gateway curl -s -X POST \
  "http://keycloak:8080/realms/demo-ecommerce/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token')

if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
  echo "❌ Failed to get token from Keycloak"
  exit 1
fi

echo "✅ Token retrieved (first 30 chars): ${JWT_TOKEN:0:30}..."
echo -e "\n"

# ============================
# 🚀 Run tests (outside)
# ============================

echo "Test 1: Normal Case"
curl --location 'http://localhost:8090/order/test' --header "Authorization: Bearer $JWT_TOKEN"
echo -e "\n"

echo "Test 2: Simulate Failures (HTTP 500)"
for i in {1..6}; do
  curl --location 'http://localhost:8090/order/test?endpoint=test-error' --header "Authorization: Bearer $JWT_TOKEN"
  echo -e "\n"
  sleep 1
done

echo "Checking health after failures"
curl http://localhost:8082/actuator/health
echo -e "\n"

echo "Waiting 5 seconds for circuit breaker to transition to HALF_OPEN"
sleep 5

echo "Test 3: Simulate Slow Responses"
for i in {1..6}; do
  curl --location 'http://localhost:8090/order/test?endpoint=test-slow' --header "Authorization: Bearer $JWT_TOKEN"
  echo -e "\n"
  sleep 1
done

echo "Checking health after slow responses"
curl http://localhost:8082/actuator/health
echo -e "\n"

echo "Test 4: Simulate Product-Service Down"
echo "Please stop Product-Service manually, then press Enter to continue..."
read
for i in {1..6}; do
  curl --location 'http://localhost:8090/order/test' --header "Authorization: Bearer $JWT_TOKEN"
  echo -e "\n"
  sleep 1
done

echo "Checking health after service down"
curl http://localhost:8082/actuator/health
echo -e "\n"

echo "Test 5: Recovery"
echo "Please restart Product-Service, wait 5 seconds, then press Enter..."
read
curl --location 'http://localhost:8090/order/test' --header "Authorization: Bearer $JWT_TOKEN"
echo -e "\n"

echo "Final health check"
curl http://localhost:8082/actuator/health