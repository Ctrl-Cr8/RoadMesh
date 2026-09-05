# RoadMesh Deployment & Containerization Guide

This guide covers running the complete RoadMesh stack using Docker Compose.

---

## 🐳 One-Command Deployment

Run the entire platform (Server, Simulator REST Engine, Admin Dashboard, Nginx Reverse Proxy) with a single command:

```bash
docker-compose up -d --build
```

### Accessing Services

| Service | URL | Description |
|---|---|---|
| **Nginx Main Entry** | `http://localhost/` | Proxies dashboard, WS, and simulator |
| **Admin Dashboard** | `http://localhost/dashboard` | Real-time map & vehicle tracking UI |
| **WebSocket Endpoint** | `ws://localhost/ws` | Mobile app telemetry endpoint |
| **Simulator Control UI** | `http://localhost/sim/` | Scenario engine browser controller |
| **Metrics Endpoint** | `http://localhost:3000/metrics` | Prometheus metrics |

---

## 🛠️ Environment Variables Reference

| Variable | Default | Description |
|---|---|---|
| `HTTP_PORT` | `3000` | Server HTTP & WebSocket port |
| `NEARBY_RADIUS_METERS` | `500` | Geohash spatial query radius |
| `VEHICLE_TIMEOUT_MS` | `10000` | Stale vehicle eviction timeout |
| `COLLISION_HORIZON_SEC` | `10` | Trajectory prediction lookahead horizon |
| `RATE_LIMIT_MAX` | `1000` | Max requests per minute per IP |
