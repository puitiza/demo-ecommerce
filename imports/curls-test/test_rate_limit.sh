#!/bin/bash
# test_rate_limit_with_redis_inspect.sh
CLIENT_ID="gateway-service"
CLIENT_SECRET="3rElcTH0OSsRZmdw9ubeaf9Pob6D7Ake"
URL="http://localhost:8090/order/test"
REDIS_CONTAINER="redis"   # cambia si tu contenedor se llama distinto
REDIS_PATTERN="*request_rate_limiter*"

# Colores
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # reset

# Obtener JWT (igual que tu script original)
JWT_TOKEN=$(docker exec -i server-gateway curl -s -X POST \
  "http://keycloak:8080/realms/demo-ecommerce/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token')

if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
  echo -e "${RED}❌ Failed to retrieve token${NC}"
  exit 1
fi

echo "✅ Token retrieved (first 30 chars): ${JWT_TOKEN:0:30}..."
echo ""

# Mostrar keys en Redis antes
echo -e "${CYAN}📊 Redis keys (before requests):${NC}"
docker exec -i $REDIS_CONTAINER redis-cli keys "$REDIS_PATTERN" || true
echo ""

# --- Función que hace request y muestra headers (igual que el tuyo) ---
make_request() {
  local idx=$1
  RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/curl_body_$idx.txt \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -D /tmp/curl_headers_$idx.txt \
    "$URL")

  REMAINING=$(grep -i "X-RateLimit-Remaining" /tmp/curl_headers_$idx.txt | awk '{print $2}' | tr -d '\r')
  REPLENISH=$(grep -i "X-RateLimit-Replenish-Rate" /tmp/curl_headers_$idx.txt | awk '{print $2}' | tr -d '\r')
  BURST=$(grep -i "X-RateLimit-Burst-Capacity" /tmp/curl_headers_$idx.txt | awk '{print $2}' | tr -d '\r')

  if [[ "$RESPONSE" == "429" ]]; then
    COLOR=$RED
  elif [[ "$RESPONSE" == "200" && "$REMAINING" -le 2 ]]; then
    COLOR=$YELLOW
  else
    COLOR=$GREEN
  fi

  echo -e "${COLOR}Request $idx → $RESPONSE${NC}"
  echo "  [X-RateLimit-Remaining: ${REMAINING:-?}, X-RateLimit-Replenish-Rate: ${REPLENISH:-?}, X-RateLimit-Burst-Capacity: ${BURST:-?}]"
}

# Ejecutar 10 requests en paralelo
echo "🚀 Sending 10 requests in parallel..."
for i in {1..10}; do
  make_request $i &
done
wait

# Mostrar keys en Redis después
echo ""
echo -e "${CYAN}📊 Redis keys (after requests):${NC}"
KEYS_OUT=$(docker exec -i $REDIS_CONTAINER redis-cli keys "$REDIS_PATTERN" || true)
echo "$KEYS_OUT"
echo ""

# Inspeccionar cada key correctamente (GET para string, HGETALL para hash)
if [ -n "$KEYS_OUT" ]; then
  echo -e "${CYAN}🔍 Inspecting Redis keys:${NC}"
  echo "$KEYS_OUT" | while IFS= read -r key; do
    # skip empty
    [ -z "$key" ] && continue

    echo -e "${YELLOW}-- $key${NC}"
    # tipo
    TYPE=$(docker exec -i $REDIS_CONTAINER redis-cli type "$key" 2>/dev/null || echo "unknown")
    echo "  type: $TYPE"
    # ttl
    TTL=$(docker exec -i $REDIS_CONTAINER redis-cli ttl "$key" 2>/dev/null || echo "-")
    echo "  ttl (s): $TTL"

    if [ "$TYPE" = "string" ]; then
      VALUE=$(docker exec -i $REDIS_CONTAINER redis-cli get "$key" 2>/dev/null || echo "")
      # si es timestamp numeric y el key parece .timestamp, muestro fecha
      if [[ "$key" == *".timestamp" ]] && [[ "$VALUE" =~ ^[0-9]+$ ]]; then
        # intenta convertir a fecha legible (host debe soportar date -r)
        if date -r "$VALUE" >/dev/null 2>&1; then
          READABLE=$(date -r "$VALUE" +"%Y-%m-%d %H:%M:%S")
        else
          READABLE="$VALUE"
        fi
        echo "  value: $VALUE  (readable: $READABLE)"
      else
        echo "  value: $VALUE"
      fi
    elif [ "$TYPE" = "hash" ]; then
      echo "  hgetall:"
      docker exec -i $REDIS_CONTAINER redis-cli hgetall "$key"
    else
      echo "  (no inspector implemented for type: $TYPE)"
    fi
  done
else
  echo -e "${YELLOW}⚠️ No Redis keys matching pattern were found.${NC}"
fi