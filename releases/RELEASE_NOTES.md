# RoadMesh v1.0.0 — Production Release Notes

**Date**: September 2026  
**Binary**: `roadmesh-v1.0.0.apk`  
**Size**: 24.0 MB  
**Checksum (SHA-256)**: See `roadmesh-v1.0.0.apk.sha256`

---

## What's New in v1.0.0

### 1. Zero-Hardware Smartphone V2X Core
- Real-time GPS and compass telemetry streaming over low-latency WebSockets.
- Dynamic Time-to-Closest-Approach (TCA) collision prediction engine computing relative velocity vectors up to 10 seconds ahead.
- Spatial Geohash indexing (Precision 6) querying 9 neighboring cells with sub-millisecond response times.

### 2. Streamlined Vehicle Speedometer HUD
- Removed road speed limit classifications, speed limiter sensors, and false overspeeding alarms.
- Floating circular HUD showing actual GPS driving speed in `km/h`.
- Adaptive day/night visual themes.

### 3. Tactical Geospatial Operations Console
- High-contrast tactical Leaflet.js map tracking all active vehicles.
- Real-time device inspector table with speeds, bearings, and risk ratings.
- Zero-focus visual styling with clean status cards.

### 4. Robust Samsung Galaxy (One UI) ADB Support
- Upgraded `./master.sh` with automatic `-t -d` test package flags and `--no-streaming` fallback for reliable USB installs across Samsung devices.

---

## Installation

```bash
# Connect Android phone via USB and run:
adb install -r -d releases/roadmesh-v1.0.0.apk
adb shell am start -n com.example.roadmesh_app/.MainActivity
```
