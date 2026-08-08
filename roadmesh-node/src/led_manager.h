// ─── LED Manager ─────────────────────────────────────────────────────────────
//
// LED state machine with non-blocking blink patterns.
// States: IDLE, GPS_SEARCHING, CONNECTED, WARNING, ERROR

#pragma once
#include <Arduino.h>
#include "config.h"

enum class LedState {
  IDLE,          // Off / slow heartbeat
  GPS_SEARCHING, // Slow pulse: searching for fix
  CONNECTED,     // Fast double-blink: sending data
  WARNING,       // Rapid blink: collision warning received
  ERROR,         // Solid on: critical error
};

class LedManager {
public:
  LedManager();
  void begin();
  void setState(LedState state);
  void update(); // Call every loop() iteration
  LedState getState() const;

private:
  LedState     _state = LedState::IDLE;
  bool         _ledOn = false;
  unsigned long _lastToggleMs = 0;
  int          _blinkCount = 0;
  unsigned long _blinkIntervalMs = 1000;

  void _applyState();
  void _writePin(bool on);
};
