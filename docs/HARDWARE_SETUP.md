# RoadMesh ESP32 IoT Node Hardware Setup Guide

This guide describes how to assemble, wire, configure, and flash the ESP32 hardware module for RoadMesh.

---

## 🛠️ Hardware Requirements

| Component | Quantity | Description |
|---|---|---|
| **ESP32 Development Board** | 1 | DOIT ESP32 DevKit v1 (30-pin or 38-pin) |
| **u-blox NEO-6M GPS Module** | 1 | Includes external ceramic patch antenna |
| **Piezo Passive Buzzer** | 1 | 3.3V / 5V compliant |
| **LED Indicators** | 3 | Green, Yellow, Red (3mm or 5mm) |
| **Resistors** | 3 | 220Ω (for LEDs) |
| **Breadboard & Wires** | 1 set | Jumper wires (M-M, M-F) |

---

## ⚡ Pinout & Wiring Diagram

```
       ESP32 DevKit                  NEO-6M GPS Module
     ┌──────────────┐                 ┌─────────────┐
     │          3V3 ├─────────────────┤ VCC         │
     │          GND ├─────────────────┤ GND         │
     │      GPIO 16 ├─────────────────┤ TX          │  (ESP32 RX2)
     │      GPIO 17 ├─────────────────┤ RX          │  (ESP32 TX2)
     └──────────────┘                 └─────────────┘

       ESP32 DevKit                  Peripherals
     ┌──────────────┐                 ┌─────────────┐
     │      GPIO 25 ├──[ 220Ω ]───────┤ Green LED   │  (Connected Status)
     │      GPIO 26 ├──[ 220Ω ]───────┤ Yellow LED  │  (GPS Fix Searching)
     │      GPIO 27 ├──[ 220Ω ]───────┤ Red LED     │  (Collision Warning)
     │      GPIO 32 ├─────────────────┤ Buzzer (+)  │  (Audible Alert)
     │          GND ├─────────────────┤ Common GND  │
     └──────────────┘                 └─────────────┘
```

> [!CAUTION]
> **Serial Connection Note:** Use `HardwareSerial(2)` (pins 16 & 17) on ESP32. Do NOT use `SoftwareSerial` as it drops bytes at 9600 baud during WiFi transfers.

---

## 🚀 Flashing Firmware with PlatformIO

1. Install [VS Code](https://code.visualstudio.com/) and the **PlatformIO IDE** extension.
2. Open the `roadmesh-node` folder in VS Code.
3. Edit `platformio.ini` to set your WiFi credentials and MQTT server IP:
   ```ini
   build_flags =
       -DWIFI_SSID=\"YourWiFiSSID\"
       -DWIFI_PASSWORD=\"YourWiFiPassword\"
       -DMQTT_HOST=\"192.168.1.100\"
   ```
4. Connect your ESP32 board via Micro-USB.
5. Click **PlatformIO: Build** and then **PlatformIO: Upload**.
6. Open **Serial Monitor** at **115200 baud** to view real-time telemetry logs.
