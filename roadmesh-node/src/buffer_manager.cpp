// ─── Buffer Manager Implementation ───────────────────────────────────────────

#include "buffer_manager.h"

BufferManager::BufferManager() {}

bool BufferManager::begin() {
  if (!LittleFS.begin(true)) {
    LOG("[FS] LittleFS Mount Failed");
    return false;
  }
  LOG("[FS] LittleFS Mounted Successfully");
  return true;
}

bool BufferManager::savePosition(const GpsPosition& pos) {
  if (_count >= BUFFER_MAX_ENTRIES) {
    LOG("[FS] Buffer full, dropping position");
    return false;
  }

  File file = LittleFS.open(BUFFER_FILE_PATH, FILE_APPEND);
  if (!file) {
    LOG("[FS] Failed to open buffer file for writing");
    return false;
  }

  StaticJsonDocument<128> doc;
  doc["lat"] = pos.lat;
  doc["lng"] = pos.lng;
  doc["speed"] = pos.speedKmh;
  doc["heading"] = pos.headingDeg;
  doc["ts"] = pos.timestampMs;

  serializeJson(doc, file);
  file.println();
  file.close();

  _count++;
  LOGF("[FS] Position buffered (count=%d)\n", _count);
  return true;
}

int BufferManager::getBufferedCount() {
  return _count;
}

void BufferManager::clearBuffer() {
  if (LittleFS.exists(BUFFER_FILE_PATH)) {
    LittleFS.remove(BUFFER_FILE_PATH);
  }
  _count = 0;
  LOG("[FS] Buffer cleared");
}
