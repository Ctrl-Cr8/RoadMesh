// ─── Buffer Manager (LittleFS Offline Buffer) ───────────────────────────────
//
// Buffer GPS positions locally when WiFi/MQTT is disconnected.
// Flushes buffered positions to MQTT when connection is restored.

#pragma once
#include <Arduino.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include "config.h"
#include "gps_manager.h"

class BufferManager {
public:
  BufferManager();
  bool begin();
  bool savePosition(const GpsPosition& pos);
  int getBufferedCount();
  void clearBuffer();

private:
  int _count = 0;
};
