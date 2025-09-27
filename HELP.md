# 🛒 Demo E-Commerce (Minimal PoC)

Minimal **Spring Boot Microservices PoC** with **production-like integrations**:

* **Gateway + Eureka + Config Server** (Service Discovery + Centralized Config)
* **Keycloak** for OAuth2 (JWT validation, M2M)
* **Circuit Breaker (Resilience-4j)** with fallback
* **Kafka + Zookeeper** for async events
* **Observability**: OpenTelemetry Collector + Jaeger
* **Monitoring**: Prometheus + Grafana
* **Logging**: Loki + Promtail (structured logs in Grafana)
* **Caching + Rate Limiting**: Redis (Gateway `RequestRateLimiter`)
* **CI-ready**: SonarQube + Jacoco + Integration Tests (Testcontainers)
* **API Docs**: Spring REST Docs auto-packaged in JARs

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant O as Order-Service
    participant P as Product-Service
    participant K as Kafka
    C ->> G: Request (JWT)
    G ->> O: Forward (JWT + TraceID)
    O ->> P: Call with CircuitBreaker
    P -->> O: Response (slow/error triggers fallback)
    O ->> K: Publish Event
````

---

## 🔗 Request Flow with TraceID + JWT

### Example: `GET /order/test`

### 1️⃣ Client → Gateway

* JWT validated (`JwtAuthenticationToken`)
* TraceID generated
* Redis-based rate-limit applied

### 2️⃣ Gateway → Order-Service

* Routed via **Eureka**
* TraceID + JWT propagated
* Config fetched dynamically from **Config Server**

### 3️⃣ Order-Service

* JWT validated
* Calls **Product-Service** through RestTemplate
* Protected with **CircuitBreaker (Resilience-4j)**
* Fallback executed on errors/slowness
* Publishes event to **Kafka**

### 4️⃣ Product-Service

* JWT validated
* Returns response (or error/slow to trigger breaker)

✅ **Validated in PoC:**

* TraceID automatically propagated (via OpenTelemetry)
* JWT validated in each hop (Gateway, Order-Service, Product-Service)
* CircuitBreaker + fallback working
* Kafka events traced (even fallback events)
* Rate-Limiter enforced with Redis
* Config Server centralizes configs

---

## 🔗 End-to-End Trace

```text
Client
   |
   v
Gateway-Service
   ├── JWT validated
   ├── Rate-Limit applied (Redis-based)
   └── Calls Order-Service (TraceID + JWT forwarded)
            |
            v
     Order-Service
        ├── JWT validated
        ├── Calls Product-Service via RestTemplate
        │       ├── Protected by CircuitBreaker (Resilience4j)
        │       └── Fallback on errors/slow responses
        └── Publishes event to Kafka
            |
            v
        Kafka → Observed in Jaeger (trace spans) + Grafana Loki (logs)
```

✅ **Validated in PoC**

* Rate-Limiting active on Gateway (`RequestRateLimiter` + Redis)
* CircuitBreaker on Order-Service for Product-Service calls
* TraceID propagation end-to-end
* JWT validated in each hop
* Kafka events published even in fallback
* Observability with Jaeger

## 🔑 Keycloak Setup

If the Keycloak Admin Console (HTTPS) is not accessible, initialize manually:

```bash
  docker exec -it keycloak-server /bin/bash
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
exit
```

Or run:

```bash
  ./imports/init-keycloak.sh
```

### 📍 URLs & Realms

* Eureka → [http://localhost:8761](http://localhost:8761)
* Keycloak → [http://localhost:8080/admin](http://localhost:8080/admin)
* Gateway → [http://localhost:8090](http://localhost:8090)
* Order-Service → [http://localhost:8082](http://localhost:8082)
* Product-Service → [http://localhost:8081](http://localhost:8081)
* Jaeger → [http://localhost:16686](http://localhost:16686)
*
* **Realm imports in `docker-compose.yml`**:

    * `master-realm.json` → configures master realm with `sslRequired=NONE` (HTTP allowed).
    * `demo-ecommerce-realm.json` → preloads realm with clients (`gateway-service`, `order-service`, `product-service`)
      and roles.
    * *Note*: users are not exported, but **M2M tokens** are enough for the PoC.

---

## 🔑 Keycloak Setup

Keycloak runs with **realm imports** (preconfigured):

* `master-realm.json` → disables SSL requirement (`sslRequired=NONE`)
* `demo-ecommerce-realm.json` → preloads:

    * Clients: `gateway-service`, `order-service`, `product-service`
    * Roles for demo usage
    * M2M tokens enabled (users not exported)

Test JWT fetch:

```bash
./imports/curls-test/test-circuit-breaker.sh
```

---

## 🧪 Get an Access Token

From inside the `server-gateway` container:

```bash
  docker exec -it server-gateway bash

  curl -X POST 'http://keycloak:8080/realms/demo-ecommerce/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d 'client_id=gateway-service' \
  -d 'client_secret=****'
```

---

## 🧪 Test Scripts

### 1️⃣ Circuit Breaker

Simulate slow/error responses in **Product-Service** to trigger fallback:

```bash
  ./imports/curls-test/test-circuit-breaker.sh
```

✅ Expected: fallback triggered, event still published to Kafka.

---

### 2️⃣ Rate Limiter

Send 10 parallel requests through Gateway → Order-Service:

```bash
  ./imports/curls-test/test-rate-limit.sh
```

✅ Expected:

* `200 OK` until tokens exhausted
* `429 Too Many Requests` when limit exceeded
* Headers returned:

    * `X-RateLimit-Remaining`
    * `X-RateLimit-Replenish-Rate`
    * `X-RateLimit-Burst-Capacity`

🔎 Redis keys are created under `request_rate_limiter:*`, verifying that **state is stored in Redis, not memory**.


---

## 📐 Quality & Docs

* **SonarQube** → [http://localhost:9000](http://localhost:9000)

    * Token auto-generated via `init.sh`
    * `sonar-analysis` container runs `./gradlew clean test integrationTest jacocoTestReport sonar`
* **Jacoco** merges **unit + integration tests**
* **Spring Rest Docs** auto-packaged inside microservice JARs under `/docs`

---

## 📊 Observability & Monitoring

* **Traces**: Jaeger UI → [http://localhost:16686](http://localhost:16686)
* **Metrics**:

    * Prometheus → [http://localhost:9090](http://localhost:9090)
    * Grafana → [http://localhost:3000](http://localhost:3000) → Dashboard `Spring Boot Statistics (4701)`
* **Logging**:

    * Loki → [http://localhost:3100](http://localhost:3100)
    * Logs ingested by **Promtail** from all containers
    * Searchable in Grafana Explore

Metrics include:

* HTTP Requests per second
* Latency (P95/P99)
* JVM Pools (Heap/Non-Heap)
* Active Threads
* CPU & Memory

---

## 🚀 Running the Project

Rebuild and start fresh:

```bash
    docker-compose down -v && docker image prune -f && docker-compose up --build
```