# RoadMesh

**Cooperative Vehicle Awareness Platform**

A hybrid Mobile and IoT-based platform that enables nearby vehicles to communicate in real time, improving road safety through cooperative awareness.

## Architecture

```
┌─────────────────┐     WebSocket     ┌────────────────────┐     MQTT      ┌─────────────────┐
│  Flutter Mobile  │ ◄──────────────► │  RoadMesh Server   │ ◄───────────► │  ESP32 IoT Node │
│  Application     │                  │  (Node.js + TS)    │               │  (GPS + WiFi)   │
└─────────────────┘                  └────────────────────┘               └─────────────────┘
```

## Project Structure

| Directory | Description |
|-----------|-------------|
| `roadmesh-server/` | Backend server (Node.js + TypeScript + WebSocket + MQTT) |
| `roadmesh-app/` | Flutter mobile application |
| `roadmesh-node/` | ESP32 IoT firmware (PlatformIO) |
| `tools/` | Vehicle simulator for demos |

## Quick Start

### Backend Server

```bash
cd roadmesh-server
npm install
npm run dev
```

### Vehicle Simulator

```bash
# Start the server first, then:
node tools/simulator.js
```

### Mobile App

```bash
cd roadmesh-app
flutter pub get
flutter run
```

## Communication Protocol

All clients share a common JSON protocol over WebSocket (mobile) or MQTT (IoT):

```json
{
  "type": "POSITION_UPDATE",
  "payload": {
    "lat": 10.0261,
    "lng": 76.3125,
    "speed": 45.2,
    "heading": 180.0,
    "vehicleType": "CAR",
    "timestamp": 1706400000000
  }
}
```

## Features

- **Real-time vehicle tracking** — GPS-based position sharing
- **Spatial indexing** — Geohash-based efficient nearby vehicle lookups
- **Collision prediction** — Forward trajectory projection with risk classification
- **Multi-protocol** — WebSocket (mobile) + MQTT (IoT) with shared vehicle store
- **Voice & visual alerts** — Color-coded warnings with TTS support
