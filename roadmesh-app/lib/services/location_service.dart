// ─── Location Service ─────────────────────────────────────────────────────────
//
// GPS tracking with:
// - GPS jump detection (rejects implausible position changes)
// - Exponential speed smoothing (rolling average over 3 readings)
// - High-accuracy continuous tracking
// - Proper permission request flow

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'app_logger.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Position? _lastPosition;
  final List<double> _speedBuffer = [];
  static const int _speedBufferSize = 3;

  // Kalman-like jump rejection threshold multiplier
  static const double _jumpMultiplier = 5.0;

  Stream<Position> get positionStream => _positionController.stream;

  /// Request location permission and start continuous GPS tracking.
  Future<void> startTracking() async {
    final permission = await _requestPermission();
    if (!permission) {
      throw Exception('Location permission denied. Please enable it in Settings.');
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,         // Get every update
      timeLimit: null,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _handlePosition,
      onError: (e) => AppLogger.error('GPS stream error', e),
    );

    AppLogger.info('GPS tracking started (high accuracy)');
  }

  /// Handle an incoming GPS position update with filtering.
  void _handlePosition(Position position) {
    if (_lastPosition != null) {
      final timeDelta = (position.timestamp.millisecondsSinceEpoch -
              _lastPosition!.timestamp.millisecondsSinceEpoch) /
          1000.0;

      if (timeDelta > 0) {
        // Compute expected max distance based on last known speed
        final lastSpeedMs = _lastPosition!.speed.clamp(0, 200.0);
        final maxExpectedDist = (lastSpeedMs * timeDelta * _jumpMultiplier) + 50;

        final actualDist = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (actualDist > maxExpectedDist && lastSpeedMs > 0) {
          AppLogger.warning(
            'GPS jump rejected: ${actualDist.toStringAsFixed(0)}m in ${timeDelta.toStringAsFixed(1)}s '
            '(max expected: ${maxExpectedDist.toStringAsFixed(0)}m)',
          );
          return; // Reject the jump
        }
      }
    }

    // Smooth speed via rolling average
    _speedBuffer.add(position.speed.clamp(0, 200.0) * 3.6); // m/s → km/h
    if (_speedBuffer.length > _speedBufferSize) {
      _speedBuffer.removeAt(0);
    }

    _lastPosition = position;
    _positionController.add(position);
  }

  /// Get the smoothed speed in km/h from the rolling average.
  double getSpeedKmh(Position position) {
    if (_speedBuffer.isEmpty) return 0;
    final sum = _speedBuffer.reduce((a, b) => a + b);
    return sum / _speedBuffer.length;
  }

  /// Stop GPS tracking.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _speedBuffer.clear();
    _lastPosition = null;
    AppLogger.info('GPS tracking stopped');
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }

  // ─── Permission Helpers ───────────────────────────────────────────────────

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location services disabled on device');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warning('Location permission denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.error('Location permission permanently denied');
      return false;
    }

    AppLogger.info('Location permission granted: $permission');
    return true;
  }
}
