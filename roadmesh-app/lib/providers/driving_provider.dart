// ─── Driving Session Provider ───────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import '../services/collision_service.dart';

class DrivingProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final WebSocketService _wsService = WebSocketService();
  final CollisionService _collisionService = CollisionService();

  // State
  bool _isDriving = false;
  bool _isConnected = false;
  Position? _currentPosition;
  double _currentSpeed = 0;
  double _currentHeading = 0;
  VehicleType _vehicleType = VehicleType.car;
  String _serverUrl = '';
  List<Vehicle> _nearbyVehicles = [];
  List<CollisionAlert> _activeAlerts = [];
  RiskLevel _currentRiskLevel = RiskLevel.green;

  StreamSubscription? _locationSub;
  StreamSubscription? _nearbySub;
  StreamSubscription? _connectionSub;

  // Getters
  bool get isDriving => _isDriving;
  bool get isConnected => _isConnected;
  Position? get currentPosition => _currentPosition;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;
  VehicleType get vehicleType => _vehicleType;
  List<Vehicle> get nearbyVehicles => _nearbyVehicles;
  List<CollisionAlert> get activeAlerts => _activeAlerts;
  RiskLevel get currentRiskLevel => _currentRiskLevel;
  String? get vehicleId => _wsService.vehicleId;

  // Setters
  set vehicleType(VehicleType type) {
    _vehicleType = type;
    notifyListeners();
  }

  set serverUrl(String url) {
    _serverUrl = url;
  }

  /// Start a driving session.
  Future<void> startDriving() async {
    if (_isDriving) return;

    try {
      // 1. Start location tracking
      await _locationService.startTracking();

      // 2. Connect to server
      await _wsService.connect(
        serverUrl: _serverUrl.isNotEmpty ? _serverUrl : null,
      );

      // 3. Listen to location updates
      _locationSub = _locationService.positionStream.listen((position) {
        _currentPosition = position;
        _currentSpeed = _locationService.getSpeedKmh(position);
        _currentHeading = position.heading;

        // Send position to server
        _wsService.sendPositionUpdate(
          lat: position.latitude,
          lng: position.longitude,
          speed: _currentSpeed,
          heading: _currentHeading,
          vehicleType: _vehicleType.label,
        );

        notifyListeners();
      });

      // 4. Listen to nearby vehicle updates
      _nearbySub = _wsService.nearbyStream.listen((update) {
        _nearbyVehicles = update.vehicles;
        _activeAlerts = update.alerts;

        // Update overall risk level
        if (update.alerts.isEmpty) {
          _currentRiskLevel = RiskLevel.green;
        } else {
          _currentRiskLevel = update.alerts.first.riskLevel;
        }

        // Process alerts (TTS + haptic)
        _collisionService.processAlerts(update.alerts);

        notifyListeners();
      });

      // 5. Listen to connection state
      _connectionSub = _wsService.connectionStream.listen((connected) {
        _isConnected = connected;
        notifyListeners();
      });

      _isDriving = true;
      notifyListeners();
    } catch (e) {
      print('Failed to start driving: $e');
      await stopDriving();
      rethrow;
    }
  }

  /// Stop the driving session.
  Future<void> stopDriving() async {
    _locationSub?.cancel();
    _nearbySub?.cancel();
    _connectionSub?.cancel();

    _locationService.stopTracking();
    _wsService.disconnect();
    await _collisionService.stop();

    _isDriving = false;
    _isConnected = false;
    _nearbyVehicles = [];
    _activeAlerts = [];
    _currentRiskLevel = RiskLevel.green;
    _currentSpeed = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    stopDriving();
    _locationService.dispose();
    _wsService.dispose();
    _collisionService.dispose();
    super.dispose();
  }
}
