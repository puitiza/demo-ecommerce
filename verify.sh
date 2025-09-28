#!/usr/bin/env bash
set -e

echo "🔐 Fetching access token..."

JWT_TOKEN=$(docker exec -i server-gateway curl -s -X POST \
  "http://keycloak:8080/realms/demo-ecommerce/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=gateway-service" \
  -d "client_secret=3rElcTH0OSsRZmdw9ubeaf9Pob6D7Ake" \
  | jq -r '.access_token')

if [[ -z "$JWT_TOKEN" || "$JWT_TOKEN" == "null" ]]; then
  echo "❌ Failed to obtain token"
  exit 1
fi

echo "✅ Token OK"

echo ""
echo "🩺 Checking health endpoints..."

curl -fs http://localhost:8090/actuator/health >/dev/null && echo "✅ Gateway OK"
curl -fs http://localhost:8081/actuator/health >/dev/null && echo "✅ Product-Service OK"
curl -fs http://localhost:8082/actuator/health >/dev/null && echo "✅ Order-Service OK"
curl -fs http://localhost:8761/actuator/health >/dev/null && echo "✅ Discovery OK"
curl -fs http://localhost:8885/actuator/health >/dev/null && echo "✅ Config OK"

echo ""
echo "🚀 Testing Product API through Gateway..."

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  http://localhost:8090/product/test)

if [[ "$STATUS_CODE" == "200" ]]; then
  echo "✅ Product endpoint OK (HTTP 200)"
else
  echo "❌ Product endpoint FAILED (HTTP $STATUS_CODE)"
  exit 1
fi

echo ""
echo "🎉 VERIFY SUCCESSFUL"