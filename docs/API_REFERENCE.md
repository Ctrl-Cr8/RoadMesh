# RoadMesh API & Protocol Reference

This document provides complete details on the WebSocket and MQTT protocol messages used across the **RoadMesh** platform.

---

## 📡 WebSocket Protocol

Connected mobile apps communicate with the server over WebSocket at `ws://<host>:3000/ws`.

### 1. Position Update (`POSITION_UPDATE`)
Sent by the client (mobile app or simulator) every ~1 second.

**Request:**
```json
{
  "type": "POSITION_UPDATE",
  "timestamp": 1770588000000,
  "payload": {
    "lat": 10.0261,
    "lng": 76.3125,
    "speed": 45.5,
    "heading": 180.0,
    "vehicleType": "CAR",
    "timestamp": 1770588000000
  }
}
```

### 2. Client Registration Response (`REGISTER`)
Sent by the server immediately upon initial connection.

**Response:**
```json
{
  "type": "REGISTER",
  "timestamp": 1770588000000,
  "payload": {
    "id": "e4d29a10-3b4f-4a92-81e2-5f80b19d45a9",
    "vehicleType": "CAR"
  }
}
```

### 3. Nearby Vehicles & Collision Warnings (`NEARBY_VEHICLES`)
Broadcast by the server to active clients in response to position updates.

**Response:**
```json
{
  "type": "NEARBY_VEHICLES",
  "timestamp": 1770588001000,
  "payload": {
    "vehicles": [
      {
        "id": "v-sub-901",
        "lat": 10.0270,
        "lng": 76.3125,
        "speed": 50.0,
        "heading": 0.0,
        "vehicleType": "MOTORCYCLE",
        "timestamp": 1770588000950
      }
    ],
    "alerts": [
      {
        "vehicleId": "v-sub-901",
        "riskLevel": "RED",
        "alertType": "HEAD_ON",
        "timeToCollision": 3.2,
        "distance": 98.4,
        "bearing": 180.0
      }
    ]
  }
}
```

### 4. Latency Ping / Pong (`PING` / `PONG`)

**Ping (Client → Server):**
```json
{
  "type": "PING",
  "timestamp": 1770588002000,
  "payload": { "clientTime": 1770588002000 }
}
```

**Pong (Server → Client):**
```json
{
  "type": "PONG",
  "timestamp": 1770588002005,
  "payload": {
    "clientTime": 1770588002000,
    "serverTime": 1770588002005
  }
}
```

---

## 📡 MQTT Protocol

IoT nodes (ESP32) publish and subscribe over MQTT at `mqtt://<host>:1883`.

### Topics & Payloads

| Topic | Direction | Description | Payload Example |
|---|---|---|---|
| `roadmesh/vehicles/{vehicleId}/position` | Node → Server | Publish GPS coordinate | `{"lat": 10.026, "lng": 76.312, "speed": 40, "heading": 90, "vehicleType": "CAR"}` |
| `roadmesh/nearby/{vehicleId}` | Server → Node | Receive collision alerts | `{"alerts": [{"riskLevel": "RED", "alertType": "HEAD_ON", "distance": 45}]}` |
| `roadmesh/heartbeat` | Node → Server | Client heartbeat | `{"id": "esp32-aabbcc"}` |
