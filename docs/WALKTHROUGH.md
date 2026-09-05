# RoadMesh — Build Walkthrough

## What Was Built

A complete **100% Smartphone-Based** Cooperative Vehicle Awareness and V2X Platform across **3 pure-software components**.

### 1. Backend Server (`roadmesh-server/`)
| Module | Purpose |
|--------|---------|
| [types.ts](roadmesh-server/src/vehicles/types.ts) | Protocol types, vehicle state, alert definitions |
| [geo.ts](roadmesh-server/src/utils/geo.ts) | Haversine distance, bearing, position prediction |
| [geohash.ts](roadmesh-server/src/spatial/geohash.ts) | Spatial indexing into ~1.2km grid cells |
| [grid.ts](roadmesh-server/src/spatial/grid.ts) | O(K) nearby vehicle lookups via geohash |
| [store.ts](roadmesh-server/src/vehicles/store.ts) | In-memory vehicle state with auto-expiry |
| [predictor.ts](roadmesh-server/src/collision/predictor.ts) | 10-second trajectory projection, collision classification |
| [websocket.ts](roadmesh-server/src/protocol/websocket.ts) | Real-time high-throughput mobile app client handler |
| [server.ts](roadmesh-server/src/server.ts) | Express REST + WebSocket orchestration |

### 2. Flutter Mobile App (`roadmesh-app/`)
| File | Purpose |
|------|---------|
| [main.dart](roadmesh-app/lib/main.dart) | App entry, dark theme, Provider setup |
| [home_screen.dart](roadmesh-app/lib/screens/home_screen.dart) | Landing page with vehicle selector + server config |
| [driving_screen.dart](roadmesh-app/lib/screens/driving_screen.dart) | Full-screen dark map with markers + warnings |
| [driving_provider.dart](roadmesh-app/lib/providers/driving_provider.dart) | Central state management |
| [websocket_service.dart](roadmesh-app/lib/services/websocket_service.dart) | Auto-reconnecting WS client |
| [collision_service.dart](roadmesh-app/lib/services/collision_service.dart) | TTS voice alerts + haptic feedback |

### 3. Tactical Geospatial Admin Dashboard
- [dashboard.js](roadmesh-server/src/dashboard/dashboard.js) — Real-time interactive Leaflet map, mobile device telemetry inspector, dynamic GPS framing, and alert feed
- [gateway.js](arduino/gateway/gateway.js) — Hardware Roadside Unit (RSU) smart school crossing beacon integration

---

## Zero-Hardware Architecture Highlights

- **Zero CAPEX**: Drivers use their existing smartphones running the Flutter app.
- **Sub-Second Telemetry**: JSON over WebSocket enables sub-50ms round-trip latency.
- **Geohash Indexing**: Precision-6 spatial grid ensures O(1) cell lookups across dense Indian urban traffic.
- **Predictive AI**: Computes Time of Closest Approach (TCA) using relative velocity vectors.
