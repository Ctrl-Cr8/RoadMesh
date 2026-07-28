// ─── Collision Alert Service ────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../models/alert.dart';

class CollisionService {
  final FlutterTts _tts = FlutterTts();
  Timer? _cooldownTimer;
  bool _canSpeak = true;
  String? _lastSpokenAlert;

  CollisionService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Process a list of alerts and trigger appropriate warnings.
  Future<void> processAlerts(List<CollisionAlert> alerts) async {
    if (alerts.isEmpty) return;

    // Get the highest priority alert
    final topAlert = alerts.first; // Already sorted by priority from server

    // Trigger haptic feedback for RED alerts
    if (topAlert.riskLevel == RiskLevel.red) {
      _triggerHaptic();
    }

    // Speak the voice alert (with cooldown to avoid spam)
    await _speakAlert(topAlert);
  }

  /// Speak a voice alert with cooldown.
  Future<void> _speakAlert(CollisionAlert alert) async {
    if (!_canSpeak) return;

    final alertText = alert.voiceAlert;

    // Don't repeat the same alert
    if (alertText == _lastSpokenAlert) return;

    _lastSpokenAlert = alertText;
    _canSpeak = false;

    await _tts.speak(alertText);

    // Cooldown: wait 3 seconds before speaking again
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      _canSpeak = true;
    });
  }

  /// Trigger haptic feedback.
  Future<void> _triggerHaptic() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      // Pattern: vibrate 200ms, pause 100ms, vibrate 200ms
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  /// Stop any ongoing TTS.
  Future<void> stop() async {
    await _tts.stop();
    _cooldownTimer?.cancel();
    _canSpeak = true;
    _lastSpokenAlert = null;
  }

  void dispose() {
    stop();
    _tts.stop();
  }
}
