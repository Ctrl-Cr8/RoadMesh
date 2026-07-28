# RoadMesh — Build Walkthrough

## What Was Built

A complete Cooperative Vehicle Awareness Platform across **4 components** and **38 source files**.

### Backend Server (`roadmesh-server/`)
| Module | Purpose |
|--------|---------|
| [types.ts](roadmesh-server/src/vehicles/types.ts) | Protocol types, vehicle state, alert definitions |
| [geo.ts](roadmesh-server/src/utils/geo.ts) | Haversine distance, bearing, position prediction |
| [geohash.ts](roadmesh-server/src/spatial/geohash.ts) | Spatial indexing into ~1.2km grid cells |
| [grid.ts](roadmesh-server/src/spatial/grid.ts) | O(K) nearby vehicle lookups via geohash |
| [store.ts](roadmesh-server/src/vehicles/store.ts) | In-memory vehicle state with auto-expiry |
| [predictor.ts](roadmesh-server/src/collision/predictor.ts) | 10-second trajectory projection, collision classification |
| [websocket.ts](roadmesh-server/src/protocol/websocket.ts) | Mobile client handler |
| [mqtt.ts](roadmesh-server/src/protocol/mqtt.ts) | Embedded MQTT broker for IoT nodes |
| [server.ts](roadmesh-server/src/server.ts) | Express + WS + MQTT orchestration |

### Flutter Mobile App (`roadmesh-app/`)
| File | Purpose |
|------|---------|
| [main.dart](roadmesh-app/lib/main.dart) | App entry, dark theme, Provider setup |
| [home_screen.dart](roadmesh-app/lib/screens/home_screen.dart) | Landing page with vehicle selector + server config |
| [driving_screen.dart](roadmesh-app/lib/screens/driving_screen.dart) | Full-screen dark map with markers + warnings |
| [driving_provider.dart](roadmesh-app/lib/providers/driving_provider.dart) | Central state management |
| [websocket_service.dart](roadmesh-app/lib/services/websocket_service.dart) | Auto-reconnecting WS client |
| [collision_service.dart](roadmesh-app/lib/services/collision_service.dart) | TTS voice alerts + haptic feedback |

### ESP32 Firmware (`roadmesh-node/`)
- [main.cpp](roadmesh-node/src/main.cpp) — WiFi + GPS + MQTT + LED/buzzer alerts

### Demo Tools
- [simulator.js](tools/simulator.js) — 4 scenario simulations (head-on, blind corner, overtaking, emergency)

---

## Verification Results

### ✅ Backend Server
- TypeScript compiles with **0 errors**
- Server starts: HTTP `:3000`, WebSocket `/ws`, MQTT `:1883`
- Health endpoint responds correctly
- Stale vehicle cleanup runs

### ✅ Vehicle Simulator
- 4 simulated vehicles connected via WebSocket
- Vehicles registered with unique IDs
- Nearby vehicle detection working (Vehicle D detected Vehicle C)
- Clean disconnect and cleanup on exit

### ⏳ Flutter App
- All source files created, requires **Flutter SDK installation** to build

---

## Next Steps

1. **Install Flutter SDK**: `brew install --cask flutter` then `flutter doctor`
2. **Add Google Maps API key** to Android manifest and iOS config
3. **Run Flutter app**: `cd roadmesh-app && flutter pub get && flutter run`
4. **Demo**: Start server → run simulator → open app on phone
