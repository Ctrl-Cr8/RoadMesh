// ─── GPS Manager ──────────────────────────────────────────────────────────────
//
// Manages GPS Serial initialization, fix detection, and position parsing.
// Wraps TinyGPSPlus and exposes a clean GpsPosition struct.

#pragma once
#include <Arduino.h>
#include <TinyGPSPlus.h>
#include "config.h"

struct GpsPosition {
  double    lat;
  double    lng;
  double    speedKmh;
  double    headingDeg;
  float     hdop;
  uint32_t  satellites;
  bool      valid;
  unsigned long timestampMs;
};

class GpsManager {
public:
  GpsManager();

  /**
   * Initialize GPS serial port.
   * Call once in setup().
   */
  void begin();

  /**
   * Feed incoming serial bytes to TinyGPSPlus.
   * Call every loop iteration.
   */
  void update();

  /** @return true if a valid GPS fix is available. */
  bool hasFix() const;

  /** @return the latest GPS position. */
  GpsPosition getPosition() const;

  /** @return number of GPS sentences parsed since boot. */
  unsigned long getSentenceCount() const;

private:
  TinyGPSPlus _gps;
  bool        _hasFix = false;
  GpsPosition _lastPosition;
};
