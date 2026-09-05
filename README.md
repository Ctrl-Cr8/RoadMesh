# 🚗 RoadMesh — 100% Smartphone-Based Cooperative Vehicle Awareness & V2X Platform

[![Server CI](https://github.com/mizhabas/major-project/actions/workflows/server-ci.yml/badge.svg)](https://github.com/mizhabas/major-project/actions/workflows/server-ci.yml)
[![Flutter CI](https://github.com/mizhabas/major-project/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/mizhabas/major-project/actions/workflows/flutter-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org)

**RoadMesh** is a real-time, **zero-hardware, 100% smartphone-based** Cooperative Vehicle Awareness and Collision Warning Platform designed specifically for high-density, mixed-traffic environments like Indian roads. Vehicles broadcast live smartphone telemetry over ultra-low-latency WebSockets, and the spatial AI prediction engine computes potential collision risks up to 10 seconds ahead—alerting drivers via real-time voice, haptics, and visual HUD warnings.

> **💡 Zero-Hardware V2X Paradigm**: Traditional V2X relies on expensive automotive DSRC/5G chips ($600+ / ₹50,000+). RoadMesh democratizes V2X safety by turning any regular Android/iOS smartphone into an intelligent connected vehicle node with zero extra hardware.

---

## 🌟 Key Features

- **📱 Pure Smartphone V2X (Zero Hardware)**: No aftermarket dongles, OBD units, or microcontrollers needed. Runs directly on drivers' existing smartphones.
- **⚡ Sub-Second Latency Telemetry**: Ultra-lightweight JSON telemetry payloads transmitted over high-speed WebSockets.
- **🧠 Geohash Spatial Indexing**: Precision 6 geohash grid lookup evaluating 9 neighboring cells for sub-millisecond nearby vehicle lookup without $O(N^2)$ bottlenecks.
- **🎯 Predictive Collision AI**: Trajectory projection and relative velocity dot-product Time-of-Closest-Approach (TCA) calculation up to 10 seconds ahead.
- **🎨 Glassmorphic HUD App**: Modern Flutter dark UI with Orbitron font, glassmorphic cards, animated radar, and custom particle background.
- **📊 Real-Time Admin Web Dashboard**: Interactive Leaflet.js map tracking all active vehicles, speeds, headings, and collision alerts.
- **🚸 Arduino V2I Smart Crossing**: Hardware Roadside Unit (RSU) integration for school zones and vulnerable road users.
- **🐳 One-Command Docker Setup**: Fully containerized stack with Nginx reverse proxy.
- **🧪 Comprehensive Test Suite**: Fully automated unit and integration tests passing.

---

## 🏗️ System Architecture

```mermaid
graph TB
    subgraph Clients["📱 Pure Physical Telemetry Clients"]
        M1["Flutter App (Driver 1 - Real GPS/Compass)"]
        M2["Flutter App (Driver 2 - Real GPS/Compass)"]
        ARD["Arduino UNO V2I School Beacon"]
    end

    subgraph Server["🖥️ RoadMesh Core (Docker)"]
        direction TB
        WS["WebSocket Server (/ws)"]
        VS["VehicleStore (In-Memory)"]
        SG["Geohash Spatial Grid"]
        CP["Collision Predictor Engine"]
        DASH["Admin Dashboard (/dashboard)"]
        API["REST API & /metrics"]
    end

    M1 -->|Live GPS JSON / WS| WS
    M2 -->|Live GPS JSON / WS| WS
    ARD -->|V2I Crosswalk Alert / WS| WS

    WS --> VS
    VS --> SG
    SG --> CP
    CP -->|Safety Alerts JSON| WS
    DASH --> WS
```

---

## 🚀 Quick Start (Docker)

Run the full stack (Server + Admin Dashboard + Nginx Proxy) in seconds:

```bash
docker-compose up -d --build
```

- **Admin Web Dashboard**: [`http://localhost/dashboard`](http://localhost/dashboard)
- **WebSocket Endpoint**: `ws://localhost/ws`

---

## 💻 Manual Component Setup

### 1. Backend Server (`roadmesh-server`)
```bash
cd roadmesh-server
npm install
npm test          # Run automated unit & integration tests
npm run dev       # Start dev server on http://localhost:3000
```

### 2. Flutter Mobile App (`roadmesh-app`)
```bash
cd roadmesh-app
flutter pub get
flutter run       # Launch on connected emulator/device
```

---

## 📚 Documentation Index

- 📖 [API & Protocol Reference](docs/API_REFERENCE.md) — WebSocket message formats & REST endpoints.
- 🐳 [Deployment Guide](docs/DEPLOYMENT.md) — Docker Compose details & environment variables.
- 📐 [Architecture Reference](docs/ARCHITECTURE.md) — Geohashing spatial grid and TCA collision calculation algorithms.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
