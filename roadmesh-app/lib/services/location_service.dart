// ─── Location Tracking Service ──────────────────────────────────────────────

import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionSub;
  final StreamController<Position> _controller = StreamController.broadcast();

  Stream<Position> get positionStream => _controller.stream;
  Position? lastPosition;

  /// Request location permissions if not already granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start continuous GPS tracking.
  Future<void> startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1, // Update every 1 meter
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        lastPosition = position;
        _controller.add(position);
      },
      onError: (error) {
        print('Location error: $error');
      },
    );
  }

  /// Stop GPS tracking.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Get the current position once.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  /// Get calculated speed in km/h.
  double getSpeedKmh(Position position) {
    // Geolocator returns speed in m/s
    final speedMs = position.speed;
    if (speedMs < 0) return 0;
    return speedMs * 3.6; // m/s → km/h
  }

  void dispose() {
    stopTracking();
    _controller.close();
  }
}
