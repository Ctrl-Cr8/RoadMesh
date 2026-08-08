// ─── GPS Manager Implementation ───────────────────────────────────────────────

#include "gps_manager.h"

GpsManager::GpsManager() {}

void GpsManager::begin() {
  GPS_SERIAL.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  LOG("[GPS] Serial initialized on pins RX=" + String(GPS_RX_PIN) + " TX=" + String(GPS_TX_PIN));
}

void GpsManager::update() {
  while (GPS_SERIAL.available() > 0) {
    _gps.encode(GPS_SERIAL.read());
  }

  if (_gps.location.isValid() && _gps.location.isUpdated()) {
    _hasFix = true;
    _lastPosition = {
      .lat         = _gps.location.lat(),
      .lng         = _gps.location.lng(),
      .speedKmh    = _gps.speed.isValid() ? _gps.speed.kmph() : 0.0,
      .headingDeg  = _gps.course.isValid() ? _gps.course.deg() : 0.0,
      .hdop        = _gps.hdop.isValid() ? (float)_gps.hdop.hdop() : 99.9f,
      .satellites  = _gps.satellites.isValid() ? _gps.satellites.value() : 0,
      .valid       = true,
      .timestampMs = millis(),
    };
  }
}

bool GpsManager::hasFix() const {
  return _hasFix;
}

GpsPosition GpsManager::getPosition() const {
  return _lastPosition;
}

unsigned long GpsManager::getSentenceCount() const {
  return _gps.sentencesWithFix();
}
