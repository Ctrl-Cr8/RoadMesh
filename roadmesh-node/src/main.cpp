// ─── RoadMesh ESP32 IoT Node ─────────────────────────────────────────────────
//
// Embedded vehicle awareness node with:
// - NEO-6M GPS module on Serial2 (RX=16, TX=17)
// - MQTT communication to RoadMesh server
// - Status LEDs (Green=connected, Yellow=GPS fix, Red=warning)
// - Buzzer for collision alerts
//
// Hardware Connections:
//   GPS Module:  RX → GPIO 16, TX → GPIO 17
//   Green LED:   GPIO 25
//   Yellow LED:  GPIO 26
//   Red LED:     GPIO 27
//   Buzzer:      GPIO 32

#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <TinyGPSPlus.h>
#include <ArduinoJson.h>

// ─── Configuration ──────────────────────────────────────────────────────────

// WiFi (can be overridden via build_flags)
#ifndef WIFI_SSID
#define WIFI_SSID "RoadMesh"
#endif

#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD "roadmesh123"
#endif

// MQTT Server
#ifndef MQTT_SERVER
#define MQTT_SERVER "192.168.1.100"
#endif

#ifndef MQTT_PORT
#define MQTT_PORT 1883
#endif

// Hardware Pins
#define GPS_RX_PIN 16
#define GPS_TX_PIN 17
#define LED_GREEN 25
#define LED_YELLOW 26
#define LED_RED 27
#define BUZZER_PIN 32

// Timing
#define POSITION_UPDATE_MS 500
#define GPS_BAUD 9600

// Vehicle
#define VEHICLE_TYPE "CAR"

// ─── Global Objects ─────────────────────────────────────────────────────────

TinyGPSPlus gps;
WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);

// Vehicle ID (generated from ESP32 MAC address)
String vehicleId;
String positionTopic;
String nearbyTopic;

// State
unsigned long lastPositionUpdate = 0;
bool hasGPSFix = false;
bool isWarning = false;
unsigned long warningStartTime = 0;

// ─── Setup ──────────────────────────────────────────────────────────────────

void setupPins() {
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // All LEDs off, buzzer off
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_YELLOW, LOW);
  digitalWrite(LED_RED, LOW);
  digitalWrite(BUZZER_PIN, LOW);
}

void generateVehicleId() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  char id[18];
  snprintf(id, sizeof(id), "esp32-%02x%02x%02x%02x%02x%02x",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  vehicleId = String(id);

  positionTopic = "roadmesh/vehicles/" + vehicleId + "/position";
  nearbyTopic = "roadmesh/nearby/" + vehicleId;

  Serial.println("Vehicle ID: " + vehicleId);
}

void setupWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    // Blink yellow LED while connecting
    digitalWrite(LED_YELLOW, !digitalRead(LED_YELLOW));
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    digitalWrite(LED_YELLOW, LOW);
    digitalWrite(LED_GREEN, HIGH);
  } else {
    Serial.println("\nWiFi connection FAILED!");
    digitalWrite(LED_RED, HIGH);
  }
}

// ─── MQTT ───────────────────────────────────────────────────────────────────

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Parse nearby vehicle response
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  // Parse JSON for alerts
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, message);

  if (error) {
    Serial.print("JSON parse error: ");
    Serial.println(error.c_str());
    return;
  }

  // Check for collision alerts
  JsonArray alerts = doc["alerts"];
  bool hasRedAlert = false;

  for (JsonVariant alert : alerts) {
    String riskLevel = alert["riskLevel"].as<String>();
    String alertType = alert["alertType"].as<String>();
    float distance = alert["distance"].as<float>();

    Serial.printf("[ALERT] %s: %s (%.0fm away)\n",
                  riskLevel.c_str(), alertType.c_str(), distance);

    if (riskLevel == "RED") {
      hasRedAlert = true;
    }
  }

  // Update warning state
  if (hasRedAlert) {
    isWarning = true;
    warningStartTime = millis();
    digitalWrite(LED_RED, HIGH);
    tone(BUZZER_PIN, 2000, 300); // 2kHz beep for 300ms
  } else {
    isWarning = false;
    digitalWrite(LED_RED, LOW);
    noTone(BUZZER_PIN);
  }

  int vehicleCount = doc["vehicles"].size();
  if (vehicleCount > 0) {
    Serial.printf("[INFO] %d nearby vehicle(s)\n", vehicleCount);
  }
}

void reconnectMQTT() {
  while (!mqtt.connected()) {
    Serial.print("Connecting to MQTT...");

    if (mqtt.connect(vehicleId.c_str())) {
      Serial.println("connected!");
      mqtt.subscribe(nearbyTopic.c_str());
      Serial.println("Subscribed to: " + nearbyTopic);
      digitalWrite(LED_GREEN, HIGH);
    } else {
      Serial.printf("failed (rc=%d), retrying in 3s...\n", mqtt.state());
      digitalWrite(LED_GREEN, LOW);
      delay(3000);
    }
  }
}

// ─── GPS ────────────────────────────────────────────────────────────────────

void publishPosition() {
  if (!gps.location.isValid()) {
    hasGPSFix = false;
    return;
  }

  hasGPSFix = true;

  JsonDocument doc;
  doc["lat"] = gps.location.lat();
  doc["lng"] = gps.location.lng();
  doc["speed"] = gps.speed.kmph();
  doc["heading"] = gps.course.deg();
  doc["vehicleType"] = VEHICLE_TYPE;
  doc["timestamp"] = millis(); // Ideally system time, using uptime for demo

  char buffer[256];
  serializeJson(doc, buffer);

  if (mqtt.publish(positionTopic.c_str(), buffer)) {
    // Blink green LED briefly to show transmission
    digitalWrite(LED_GREEN, LOW);
    delay(50);
    digitalWrite(LED_GREEN, HIGH);
  }
}

// ─── Main ───────────────────────────────────────────────────────────────────

void setup() {
  Serial.begin(115200);
  Serial2.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  Serial.println();
  Serial.println("╔═══════════════════════════════════════╗");
  Serial.println("║   🚗 RoadMesh Node v1.0.0             ║");
  Serial.println("║   ESP32 Vehicle Awareness Module       ║");
  Serial.println("╚═══════════════════════════════════════╝");
  Serial.println();

  setupPins();
  generateVehicleId();
  setupWiFi();

  mqtt.setServer(MQTT_SERVER, MQTT_PORT);
  mqtt.setCallback(mqttCallback);
  mqtt.setBufferSize(1024);
}

void loop() {
  // Read GPS data
  while (Serial2.available() > 0) {
    gps.encode(Serial2.read());
  }

  // Ensure MQTT connection
  if (!mqtt.connected()) {
    reconnectMQTT();
  }
  mqtt.loop();

  // Periodic position update
  unsigned long now = millis();
  if (now - lastPositionUpdate >= POSITION_UPDATE_MS) {
    lastPositionUpdate = now;
    publishPosition();

    // Update GPS fix LED
    digitalWrite(LED_YELLOW, hasGPSFix ? HIGH : LOW);
  }

  // Auto-clear warning after 5 seconds
  if (isWarning && millis() - warningStartTime > 5000) {
    isWarning = false;
    digitalWrite(LED_RED, LOW);
    noTone(BUZZER_PIN);
  }
}
