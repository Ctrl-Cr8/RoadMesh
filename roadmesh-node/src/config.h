// ─── RoadMesh Node Configuration ─────────────────────────────────────────────
//
// All compile-time constants in one place.
// Override per PlatformIO environment (see platformio.ini).

#pragma once

// ─── WiFi ─────────────────────────────────────────────────────────────────────
#ifndef WIFI_SSID
  #define WIFI_SSID "YourWiFiSSID"
#endif

#ifndef WIFI_PASSWORD
  #define WIFI_PASSWORD "YourWiFiPassword"
#endif

// ─── MQTT ─────────────────────────────────────────────────────────────────────
#ifndef MQTT_HOST
  #define MQTT_HOST "192.168.1.100"
#endif

#ifndef MQTT_PORT
  #define MQTT_PORT 1883
#endif

// ─── GPS (Hardware Serial 2 on ESP32: RX=16, TX=17) ─────────────────────────
#define GPS_SERIAL      Serial2
#define GPS_BAUD        9600
#define GPS_RX_PIN      16
#define GPS_TX_PIN      17

// ─── LED Indicator ────────────────────────────────────────────────────────────
#define LED_PIN         2         // Built-in LED on most ESP32 boards
#define LED_ACTIVE_LOW  false     // Set true if LED is active LOW (inverted)

// ─── Buzzer ───────────────────────────────────────────────────────────────────
#define BUZZER_PIN      4

// ─── Timing ───────────────────────────────────────────────────────────────────
#define GPS_UPDATE_INTERVAL_MS     1000   // How often to publish GPS (ms)
#define MQTT_RECONNECT_INTERVAL_MS 5000   // MQTT reconnect cooldown (ms)
#define WIFI_RECONNECT_INTERVAL_MS 15000  // WiFi reconnect cooldown (ms)
#define HEARTBEAT_INTERVAL_MS      30000  // Heartbeat publish interval (ms)

// ─── Offline Buffer ───────────────────────────────────────────────────────────
#define BUFFER_FILE_PATH "/gps_buffer.json"
#define BUFFER_MAX_ENTRIES 100

// ─── Vehicle Type ─────────────────────────────────────────────────────────────
// Override per environment
#ifndef VEHICLE_TYPE
  #define VEHICLE_TYPE "CAR"
#endif

// ─── Debug ────────────────────────────────────────────────────────────────────
#ifdef DEBUG
  #define LOG(msg)    Serial.println(msg)
  #define LOGF(...)   Serial.printf(__VA_ARGS__)
#else
  #define LOG(msg)
  #define LOGF(...)
#endif
