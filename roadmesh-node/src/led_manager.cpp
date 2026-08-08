// ─── LED Manager Implementation ───────────────────────────────────────────────

#include "led_manager.h"

LedManager::LedManager() {}

void LedManager::begin() {
  pinMode(LED_PIN, OUTPUT);
  _writePin(false);
  LOG("[LED] LED manager initialized");
}

void LedManager::setState(LedState state) {
  if (_state == state) return;
  _state = state;
  _ledOn = false;
  _blinkCount = 0;
  _lastToggleMs = 0;
  _applyState();
  LOGF("[LED] State changed to %d\n", (int)state);
}

void LedManager::_applyState() {
  switch (_state) {
    case LedState::IDLE:
      _blinkIntervalMs = 2000; break;
    case LedState::GPS_SEARCHING:
      _blinkIntervalMs = 800;  break;
    case LedState::CONNECTED:
      _blinkIntervalMs = 150;  break;  // Fast blink
    case LedState::WARNING:
      _blinkIntervalMs = 80;   break;  // Rapid blink
    case LedState::ERROR:
      _writePin(true);          // Solid on
      return;
  }
}

void LedManager::update() {
  if (_state == LedState::ERROR) return; // Solid on, nothing to toggle

  unsigned long now = millis();
  if (now - _lastToggleMs >= _blinkIntervalMs) {
    _ledOn = !_ledOn;
    _writePin(_ledOn);
    _lastToggleMs = now;
    _blinkCount++;

    // CONNECTED: double-blink pattern (2 fast blinks, then pause)
    if (_state == LedState::CONNECTED) {
      if (_blinkCount % 4 == 0) {
        _blinkIntervalMs = 800;  // Pause after double-blink
      } else {
        _blinkIntervalMs = 150;
      }
    }
  }
}

LedState LedManager::getState() const {
  return _state;
}

void LedManager::_writePin(bool on) {
  #if LED_ACTIVE_LOW
    digitalWrite(LED_PIN, on ? LOW : HIGH);
  #else
    digitalWrite(LED_PIN, on ? HIGH : LOW);
  #endif
}
