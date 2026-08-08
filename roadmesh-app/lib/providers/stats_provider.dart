// ─── Stats Provider ────────────────────────────────────────────────────────────
//
// Tracks session metrics: distance driven, speed history, alert counts.
// Persists session count via SharedPreferences.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alert.dart';

class SessionStats {
  final double totalDistanceMeters;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final Duration duration;
  final int redAlerts;
  final int yellowAlerts;
  final List<double> speedHistory; // sampled every 5s

  const SessionStats({
    required this.totalDistanceMeters,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.duration,
    required this.redAlerts,
    required this.yellowAlerts,
    required this.speedHistory,
  });
}

class StatsProvider extends ChangeNotifier {
  // Session tracking
  DateTime? _sessionStart;
  double _totalDistanceMeters = 0;
  double _maxSpeedKmh = 0;
  double _avgSpeedKmh = 0;
  int _speedReadingCount = 0;
  double _speedSum = 0;
  int _redAlerts = 0;
  int _yellowAlerts = 0;
  final List<double> _speedHistory = [];
  Position? _lastPosition;

  Timer? _samplingTimer;

  bool get isSessionActive => _sessionStart != null;

  void startSession() {
    _sessionStart = DateTime.now();
    _totalDistanceMeters = 0;
    _maxSpeedKmh = 0;
    _avgSpeedKmh = 0;
    _speedReadingCount = 0;
    _speedSum = 0;
    _redAlerts = 0;
    _yellowAlerts = 0;
    _speedHistory.clear();
    _lastPosition = null;

    // Sample speed every 5 seconds for the chart
    _samplingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _speedHistory.add(_avgSpeedKmh);
      if (_speedHistory.length > 60) {
        _speedHistory.removeAt(0); // Keep last 5 minutes
      }
      notifyListeners();
    });
  }

  void recordPosition(Position position, double speedKmh) {
    if (_lastPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _totalDistanceMeters += delta;
    }
    _lastPosition = position;

    if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
    _speedSum += speedKmh;
    _speedReadingCount++;
    _avgSpeedKmh = _speedSum / _speedReadingCount;

    notifyListeners();
  }

  void recordAlerts(List<CollisionAlert> alerts) {
    for (final alert in alerts) {
      if (alert.riskLevel == RiskLevel.red) {
        _redAlerts++;
      } else if (alert.riskLevel == RiskLevel.yellow) {
        _yellowAlerts++;
      }
    }
    notifyListeners();
  }

  void endSession() {
    _samplingTimer?.cancel();
    _samplingTimer = null;
    notifyListeners();
  }

  SessionStats? get currentStats {
    if (_sessionStart == null) return null;
    return SessionStats(
      totalDistanceMeters: _totalDistanceMeters,
      maxSpeedKmh: _maxSpeedKmh,
      avgSpeedKmh: _avgSpeedKmh,
      duration: DateTime.now().difference(_sessionStart!),
      redAlerts: _redAlerts,
      yellowAlerts: _yellowAlerts,
      speedHistory: List.from(_speedHistory),
    );
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    super.dispose();
  }
}
