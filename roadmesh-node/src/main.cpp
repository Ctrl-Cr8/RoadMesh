// ─── RoadMesh ESP32 IoT Node (Modular Refactor) ───────────────────────────────

#include <Arduino.h>
#include <WiFi.h>
#include "config.h"
#include "gps_manager.h"
#include "led_manager.h"
#include "mqtt_client.h"
#include "buffer_manager.h"

GpsManager        gpsManager;
LedManager        ledManager;
MqttClientManager mqttManager;
BufferManager     bufferManager;

String vehicleId;
unsigned long lastPositionUpdateMs = 0;

void handleAlert(const char* topic, const char* payload) {
  LOG("[ALERT] Inbound warning received");
  ledManager.setState(LedState::WARNING);
  tone(BUZZER_PIN, 2000, 300); // 2kHz beep for 300ms
}

void setup() {
  Serial.begin(115200);
  LOG("\n╔═══════════════════════════════════════╗");
  LOG("║   🚗 RoadMesh ESP32 Node v1.0.0      ║");
  LOG("╚═══════════════════════════════════════╝\n");

  ledManager.begin();
  gpsManager.begin();
  bufferManager.begin();

  // Generate vehicle ID from MAC address
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char idBuf[32];
  snprintf(idBuf, sizeof(idBuf), "esp32-%02x%02x%02x%02x%02x%02x",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  vehicleId = String(idBuf);
  LOG("[NODE] Vehicle ID: " + vehicleId);

  // WiFi setup
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  ledManager.setState(LedState::GPS_SEARCHING);

  mqttManager.begin(vehicleId, handleAlert);
}

void loop() {
  ledManager.update();
  gpsManager.update();

  if (WiFi.status() == WL_CONNECTED) {
    mqttManager.loop();

    if (mqttManager.isConnected()) {
      ledManager.setState(LedState::CONNECTED);
    } else {
      ledManager.setState(LedState::GPS_SEARCHING);
    }
  } else {
    ledManager.setState(LedState::ERROR);
  }

  // Periodic position publication
  unsigned long now = millis();
  if (now - lastPositionUpdateMs >= GPS_UPDATE_INTERVAL_MS) {
    lastPositionUpdateMs = now;

    if (gpsManager.hasFix()) {
      GpsPosition pos = gpsManager.getPosition();
      if (mqttManager.isConnected()) {
        mqttManager.publishPosition(pos);
      } else {
        bufferManager.savePosition(pos);
      }
    }
  }
}
