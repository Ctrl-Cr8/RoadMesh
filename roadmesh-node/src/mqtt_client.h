// ─── MQTT Client ─────────────────────────────────────────────────────────────
//
// Wraps PubSubClient with:
// - Auto-reconnect with backoff
// - Publish helper for position JSON
// - Subscription callback dispatch

#pragma once
#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include "config.h"
#include "gps_manager.h"

// Callback for incoming MQTT alerts
typedef void (*MqttAlertCallback)(const char* topic, const char* payload);

class MqttClientManager {
public:
  MqttClientManager();

  /**
   * Initialize MQTT client.
   * @param vehicleId  UUID string to use as client ID and topic path
   * @param onAlert    Called when a collision warning arrives
   */
  void begin(const String& vehicleId, MqttAlertCallback onAlert);

  /**
   * Maintain connection. Call every loop() iteration.
   */
  void loop();

  /** @return true if currently connected to broker. */
  bool isConnected() const;

  /**
   * Publish a GPS position update to roadmesh/vehicles/{vehicleId}/position
   */
  void publishPosition(const GpsPosition& pos);

  /**
   * Publish a heartbeat message.
   */
  void publishHeartbeat();

private:
  WiFiClient        _wifiClient;
  PubSubClient      _client;
  String            _vehicleId;
  MqttAlertCallback _alertCallback = nullptr;

  unsigned long _lastReconnectAttemptMs = 0;
  int           _reconnectAttempts = 0;

  void _connect();
  void _onMessage(const char* topic, byte* payload, unsigned int length);
};
