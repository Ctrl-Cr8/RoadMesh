// ─── MQTT Client Implementation ───────────────────────────────────────────────

#include "mqtt_client.h"
#include <ArduinoJson.h>

static MqttClientManager* _instance = nullptr;

MqttClientManager::MqttClientManager()
    : _client(_wifiClient) {}

void MqttClientManager::begin(const String& vehicleId, MqttAlertCallback onAlert) {
  _vehicleId      = vehicleId;
  _alertCallback  = onAlert;
  _instance       = this;

  _client.setServer(MQTT_HOST, MQTT_PORT);
  _client.setKeepAlive(30);
  _client.setBufferSize(512);

  _client.setCallback([](const char* topic, byte* payload, unsigned int length) {
    if (_instance) {
      _instance->_onMessage(topic, payload, length);
    }
  });

  LOG("[MQTT] Client configured for " + String(MQTT_HOST) + ":" + String(MQTT_PORT));
}

void MqttClientManager::loop() {
  if (_client.connected()) {
    _client.loop();
    return;
  }

  unsigned long now = millis();
  unsigned long interval = MQTT_RECONNECT_INTERVAL_MS *
      min(1 << min(_reconnectAttempts, 4), 16); // Exponential backoff, max 16×

  if (now - _lastReconnectAttemptMs >= interval) {
    _lastReconnectAttemptMs = now;
    _connect();
  }
}

bool MqttClientManager::isConnected() const {
  return _client.connected();
}

void MqttClientManager::_connect() {
  LOGF("[MQTT] Connecting (attempt %d)...\n", _reconnectAttempts + 1);

  String clientId = "roadmesh-" + _vehicleId;
  if (_client.connect(clientId.c_str())) {
    _reconnectAttempts = 0;
    LOG("[MQTT] Connected successfully");

    // Subscribe to collision alerts for this vehicle
    String alertTopic = "roadmesh/nearby/" + _vehicleId;
    _client.subscribe(alertTopic.c_str());
    LOG("[MQTT] Subscribed to " + alertTopic);
  } else {
    _reconnectAttempts++;
    LOGF("[MQTT] Connection failed, rc=%d\n", _client.state());
  }
}

void MqttClientManager::publishPosition(const GpsPosition& pos) {
  if (!_client.connected()) return;

  StaticJsonDocument<256> doc;
  doc["lat"]         = pos.lat;
  doc["lng"]         = pos.lng;
  doc["speed"]       = pos.speedKmh;
  doc["heading"]     = pos.headingDeg;
  doc["vehicleType"] = VEHICLE_TYPE;
  doc["timestamp"]   = millis();

  char buf[256];
  serializeJson(doc, buf);

  String topic = "roadmesh/vehicles/" + _vehicleId + "/position";
  _client.publish(topic.c_str(), buf, false); // Not retained
  LOGF("[MQTT] Published to %s\n", topic.c_str());
}

void MqttClientManager::publishHeartbeat() {
  if (!_client.connected()) return;

  StaticJsonDocument<64> doc;
  doc["id"] = _vehicleId;

  char buf[64];
  serializeJson(doc, buf);

  _client.publish("roadmesh/heartbeat", buf);
}

void MqttClientManager::_onMessage(const char* topic, byte* payload, unsigned int length) {
  char msgBuf[512];
  unsigned int copyLen = min(length, (unsigned int)511);
  memcpy(msgBuf, payload, copyLen);
  msgBuf[copyLen] = '\0';

  LOG("[MQTT] Message on " + String(topic));
  LOGF("[MQTT] Payload: %s\n", msgBuf);

  if (_alertCallback) {
    _alertCallback(topic, msgBuf);
  }
}
