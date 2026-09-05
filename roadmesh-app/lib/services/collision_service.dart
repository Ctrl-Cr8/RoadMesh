// ─── Collision Alert Service ──────────────────────────────────────────────────
//
// Improvements:
// - Alert deduplication (don't re-announce same alert within 5 seconds)
// - Priority TTS queue: RED interrupts YELLOW
// - flutter_tts configured for clarity (slower rate, clear voice)
// - Haptic feedback: single vibration for YELLOW, triple-pulse for RED
// - AppLogger integration

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../models/alert.dart';
import 'app_logger.dart';

class CollisionService {
  final FlutterTts _tts = FlutterTts();
  bool _isTtsReady = false;
  bool _isSpeaking = false;

  // Deduplication: alertType → last announced timestamp
  final Map<AlertType, int> _lastAnnouncedAt = {};
  static const int _dedupWindowMs = 5000;

  // Track current risk level to avoid redundant haptics
  RiskLevel _lastHapticLevel = RiskLevel.green;

  CollisionService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.38);   // Slower for clarity while driving
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.95);        // Slightly lower pitch — authoritative
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      AppLogger.error('TTS error: $msg');
    });
    _isTtsReady = true;
    AppLogger.info('TTS initialized');
  }

  /// Process a new batch of alerts from the server.
  void processAlerts(List<CollisionAlert> alerts) {
    if (alerts.isEmpty) {
      _lastHapticLevel = RiskLevel.green;
      return;
    }

    // Find highest priority alert
    final topAlert = alerts.first;

    // Haptic feedback (don't repeat same level)
    if (topAlert.riskLevel != _lastHapticLevel) {
      _triggerHaptic(topAlert.riskLevel);
      _lastHapticLevel = topAlert.riskLevel;
    }

    // TTS deduplication
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastAnnouncedAt[topAlert.alertType] ?? 0;

    if (now - lastTime < _dedupWindowMs) {
      AppLogger.debug('Alert deduped: ${topAlert.alertType} (${now - lastTime}ms ago)');
      return;
    }

    // RED alerts interrupt current speech; YELLOW waits
    if (topAlert.riskLevel == RiskLevel.red || !_isSpeaking) {
      _announceAlert(topAlert);
      _lastAnnouncedAt[topAlert.alertType] = now;
    }
  }

  Future<void> _announceAlert(CollisionAlert alert) async {
    if (!_isTtsReady) return;

    // Stop current speech if announcing RED
    if (alert.riskLevel == RiskLevel.red && _isSpeaking) {
      await _tts.stop();
    }

    _isSpeaking = true;
    AppLogger.info('TTS: ${alert.voiceAlert}');
    await _tts.speak(alert.voiceAlert);
  }

  Future<void> _triggerHaptic(RiskLevel level) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    switch (level) {
      case RiskLevel.yellow:
        // Single medium pulse
        await Vibration.vibrate(duration: 300, amplitude: 80);
        break;
      case RiskLevel.red:
        // Triple strong pulse
        await Vibration.vibrate(
          pattern: [0, 300, 150, 300, 150, 400],
          intensities: [0, 255, 0, 255, 0, 255],
        );
        break;
      case RiskLevel.green:
        break;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _lastAnnouncedAt.clear();
    _lastHapticLevel = RiskLevel.green;
  }

  void dispose() {
    stop();
    _tts.stop();
  }
}
