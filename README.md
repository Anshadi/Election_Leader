# ⚡ ElectionLeader: Distributed High-Throughput Unique ID Engine & Consensus Matrix

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://www.oracle.com/java/)
[![Flutter Web](https://img.shields.io/badge/Flutter-Web%203.4%2B-02569B.svg)](https://flutter.dev/)
[![Apache Curator](https://img.shields.io/badge/Apache%20Curator-5.5.0-blue.svg)](https://curator.apache.org/)
[![Reactive Redis](https://img.shields.io/badge/Redis-Reactive%20Lettuce-red.svg)](https://lettuce.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Micrometer%20Metrics-purple.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Live%20Dashboards-orange.svg)](https://grafana.com/)

**ElectionLeader** is a production-grade, distributed 64-bit sortable unique ID generation and cluster consensus platform inspired by **Twitter Snowflake**, **Meituan Leaf**, and **Baidu UidGenerator**. 

It combines **Apache ZooKeeper leader election & dynamic node registration**, **double-buffered asynchronous Redis segment leasing**, **NTP clock drift protection**, and **Spring WebFlux non-blocking reactive APIs** paired with a sleek, tactile **Flutter Web Mission Control** dashboard.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    Client["Client / WebFlux REST API<br/>(/api/v1/id/next, /api/v1/id/batch)"]
    
    subgraph Manager ["Adaptive ID Manager & Observability"]
        Router["Dynamic Strategy Router<br/>(AUTO / IN_MEMORY / REDIS)"]
        Hdr["HdrHistogram & Micrometer<br/>(P50, P90, P99, P99.9 Latency SLA Tracker)"]
    end
    
    subgraph Strategies ["ID Generation Strategies"]
        Snowflake["Snowflake Strategy<br/>(Lock-free, 64-bit BitPacked, Clock Drift Guard)"]
        RedisSegment["Redis Segment Strategy<br/>(Double-Buffered Async Prefetch @ 20% Threshold)"]
    end

    subgraph Coordination ["Cluster Coordination & Failover"]
        ZK["Apache Curator ZooKeeper"]
        LeaderElection["Leader Election<br/>(Curator LeaderLatch)"]
        NodeRegistry["Dynamic Node Registry<br/>(Allocates NodeId 0-4095)"]
    end

    subgraph RedisStore ["Distributed Cache & Storage"]
        RedisRepo["RedisSegmentRepository<br/>(Atomic Range Leasing)"]
        Redis["Reactive Redis (Lettuce)"]
    end

    Client --> Router
    Router --> Hdr
    Router --> Snowflake
    Router --> RedisSegment
    
    Snowflake -.-> NodeRegistry
    RedisSegment --> RedisRepo
    RedisRepo --> Redis
    Router -.-> LeaderElection
    LeaderElection --> ZK
    NodeRegistry --> ZK
```

---

## 🔢 64-Bit Memory Allocation & Bit Packing

Generated IDs are strictly positive signed 64-bit integers (`long`), making them naturally sortable and optimized for B-Tree indexes in MySQL, PostgreSQL, and distributed storage engines.

| Field | Bit Length | Bit Range | Mask / Description |
|---|---|---|---|
| **Sign Bit** | 1 bit | `Bit 63` | Fixed `0` (Strictly positive signed `long`) |
| **Timestamp Delta** | 35 bits | `Bits 62..28` | Milliseconds elapsed from custom base epoch (`adaptive.epoch-millis`) |
| **Cluster Node ID** | 12 bits | `Bits 27..16` | Ephemeral sequential ID (0..4095) assigned dynamically by ZooKeeper |
| **Sequence Counter** | 16 bits | `Bits 15..0` | Monotonic counter supporting up to **65,536 IDs/ms per node** (~65.5M IDs/sec) |

---

## ✨ Key Engineering Features

1. **Apache ZooKeeper Cluster Coordination & Leader Election:**
   - Automatic ephemeral sequential node registration (`/election-leader/nodes/node-XXXX`) ensuring zero manual node ID assignment.
   - Curator `LeaderLatch` manages distributed leader election with instant standby failover.
   - Standalone fallback mode if ZooKeeper is unreachable.

2. **Double-Buffered Asynchronous Redis Segment Leasing:**
   - Atomic segment reservation via `RedisSegmentRepository`.
   - Asynchronously prefetches the next segment when remaining buffer capacity drops below 20% (`refillThresholdRatio = 0.2`).
   - Zero-latency buffer switching via $O(1)$ memory pointer swap without blocking HTTP request threads.

3. **NTP Clock Drift Guard:**
   - Detects backward clock adjustments. Minor drift ($\le 5	ext{ ms}$) triggers a lock-free spin-wait; major drift triggers automatic strategy failover to Redis Segment.

4. **Multi-Node Flutter Mission Control UI:**
   - **Tactile Server Rack Deck:** Live node matrix showing Node 1 (`:8001`), Node 2 (`:8002`), and Node 3 (`:8003`) with consensus roles (👑 Leader vs ⚡ Standby), round-trip ping SLAs, and last allocated sequence numbers.
   - **Target Node Switching:** One-click targeting to route global generator operations to specific nodes.
   - **Concurrent Broadcast Generator:** Fires parallel requests across all active nodes simultaneously and confirms 0% collision across the cluster.
   - **64-Bit Interactive Bit Memory Map:** Dissects any 64-bit ID into binary representations, shift formulas, and component values.
   - **HdrHistogram Telemetry:** Visualizes P50, P90, P99, and P99.9 latency SLA percentiles.
   - **Reactive Event Stream:** Monospaced CLI activity terminal logging cluster operations in real-time.

---

## 🚀 Quickstart & Running the Cluster

### 1. Start Infrastructure & Multi-Node Cluster
```bash
# Starts ZooKeeper, Redis, 3 Spring Boot Nodes, Prometheus, and Grafana
docker-compose up -d
```

### 2. Launch Flutter Web Frontend
```bash
cd frontend
flutter run -d chrome --web-port=5000
```

---

## 🌐 Endpoints & Service Port Map

| Component | Port / URL | Description |
|---|---|---|
| **Flutter Web Console** | `http://localhost:5000` | Mission Control dashboard |
| **Cluster Node 1 (Primary)** | `http://localhost:8001` | Spring Boot WebFlux Node 1 |
| **Cluster Node 2 (Worker)** | `http://localhost:8002` | Spring Boot WebFlux Node 2 |
| **Cluster Node 3 (Worker)** | `http://localhost:8003` | Spring Boot WebFlux Node 3 |
| **Grafana Telemetry** | `http://localhost:3000` | User: `admin` / Pass: `admin` |
| **Prometheus Scraper** | `http://localhost:9090` | Micrometer metrics collector |
| **Apache ZooKeeper** | `localhost:2181` | Leader election & node quorum |
| **Redis Lettuce Cache** | `localhost:6379` | Distributed segment range lease store |

---

## 📡 REST API Reference

### 1. Generate Next Single ID
```http
GET /api/v1/id/next
```
**Response (200 OK):**
```json
{
  "id": 1,
  "timestamp": 1789028080000,
  "dateTime": "2026-09-10T07:24:40Z",
  "nodeId": 0,
  "sequence": 1,
  "strategy": "REDIS_SEGMENT_DOUBLE_BUFFER"
}
```

### 2. Generate Batch of IDs
```http
GET /api/v1/id/batch?count=100
```
**Response (200 OK):**
```json
{
  "ids": [1025, 1026, 1027, ...],
  "count": 100,
  "durationMicros": 412.5,
  "strategy": "REDIS_SEGMENT_DOUBLE_BUFFER"
}
```

### 3. Decode 64-Bit ID Memory Map
```http
GET /api/v1/id/decode/{id}
```
**Response (200 OK):**
```json
{
  "id": 318729182371928371,
  "timestampDelta": 4749219,
  "absoluteTimestamp": 1789028080000,
  "dateTime": "2026-09-10T07:24:40Z",
  "nodeId": 1,
  "sequence": 42,
  "binary64Bit": "000001000110101110001100001100110000000000010000000000101010"
}
```

### 4. Cluster Consensus & Node Status
```http
GET /api/v1/cluster/status
```
**Response (200 OK):**
```json
{
  "nodeId": 0,
  "leader": true,
  "zookeeperConnected": true,
  "redisConnected": true,
  "activeStrategy": "REDIS_SEGMENT_DOUBLE_BUFFER",
  "epochMillis": 1789028080000,
  "registeredNodes": ["node-0000000000", "node-0000000001", "node-0000000002"]
}
```

### 5. Latency SLA Percentiles (HdrHistogram)
```http
GET /api/v1/metrics/latency
```
**Response (200 OK):**
```json
{
  "p50Micros": 18.0,
  "p90Micros": 45.0,
  "p99Micros": 120.0,
  "p999Micros": 350.0,
  "meanMicros": 22.4,
  "maxMicros": 890.0,
  "totalGenerated": 128450
}
```

---

## 🧪 Testing

```bash
# Run Java Backend Tests (BitPacker, Snowflake, Redis Segment, Adaptive Manager)
mvn clean test

# Run Flutter Unit & Widget Tests
cd frontend && flutter test

# Run Flutter Static Analysis
cd frontend && flutter analyze
```
