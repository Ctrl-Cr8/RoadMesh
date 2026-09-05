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
  Position? get lastPosition => _lastPosition;
  final List<double> _speedBuffer = [];
  static const int _speedBufferSize = 3;

  // Kalman-like jump rejection threshold multiplier
  static const double _jumpMultiplier = 5.0;

  Stream<Position> get positionStream => _positionController.stream;

  /// Request location permission and start continuous GPS tracking from the user's real location.
  Future<void> startTracking() async {
    bool hasPermission = false;
    try {
      hasPermission = await _requestPermission();
    } catch (e) {
      AppLogger.warning('Permission check exception: $e');
    }

    if (!hasPermission) {
      AppLogger.warning('GPS permission not granted.');
      return;
    }

    // 1. Immediately fetch last known GPS position for instant 0ms lock
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        AppLogger.info('Retrieved real last known GPS position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        _handlePosition(lastKnown);
      }
    } catch (e) {
      AppLogger.warning('Failed to get last known GPS position: $e');
    }

    // 2. Actively request current high-accuracy fix in background
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 8),
      ),
    ).then((pos) {
      AppLogger.info('High-accuracy GPS fix acquired: ${pos.latitude}, ${pos.longitude}');
      _handlePosition(pos);
    }).catchError((e) {
      AppLogger.warning('Single GPS fix request timeout/error: $e');
    });

    // 3. Continuous real-time GPS stream (every 1 meter)
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1, // update every 1 meter of physical movement
    );

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (pos) {
          _handlePosition(pos);
        },
        onError: (e) {
          AppLogger.error('GPS stream error', e);
        },
      );
      AppLogger.info('GPS continuous tracking started (high accuracy)');
    } catch (e) {
      AppLogger.error('Failed to start GPS stream', e);
    }
  }

  /// Handle an incoming GPS position update with filtering.
  void _handlePosition(Position position) {
    if (_lastPosition != null) {
      final timeDelta = (position.timestamp.millisecondsSinceEpoch -
              _lastPosition!.timestamp.millisecondsSinceEpoch) /
          1000.0;

      // Only reject jumps if the interval is short (under 15s), last speed was > 0,
      // and this is not a jump from a coarse/stale fix to high accuracy GPS
      if (timeDelta > 0 && timeDelta < 15.0) {
        final lastSpeedMs = _lastPosition!.speed.clamp(0, 200.0);
        final maxExpectedDist = (lastSpeedMs * timeDelta * _jumpMultiplier) + 120;

        final actualDist = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (actualDist > maxExpectedDist && lastSpeedMs > 0 && actualDist < 10000) {
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
