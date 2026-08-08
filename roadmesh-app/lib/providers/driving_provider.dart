// ─── Driving Session Provider ─────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import '../services/collision_service.dart';
import '../services/battery_service.dart';
import '../services/app_logger.dart';

class DrivingProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final WebSocketService _wsService = WebSocketService();
  final CollisionService _collisionService = CollisionService();
  final BatteryService _batteryService = BatteryService();

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
  int _latencyMs = 0;

  StreamSubscription? _locationSub;
  StreamSubscription? _nearbySub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _latencySub;

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
  int get latencyMs => _latencyMs;
  bool get isLowBattery => _batteryService.isLowBattery;

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

    AppLogger.info('Starting driving session');

    try {
      // 1. Start battery monitoring
      await _batteryService.start();

      // 2. Start location tracking
      await _locationService.startTracking();

      // 3. Connect to server
      await _wsService.connect(
        serverUrl: _serverUrl.isNotEmpty ? _serverUrl : null,
      );

      // 4. Listen to location updates
      _locationSub = _locationService.positionStream.listen((position) {
        _currentPosition = position;
        _currentSpeed = _locationService.getSpeedKmh(position);
        _currentHeading = position.heading < 0 ? 0 : position.heading;

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

      // 5. Listen to nearby vehicle updates
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

      // 6. Listen to connection state
      _connectionSub = _wsService.connectionStream.listen((connected) {
        _isConnected = connected;
        notifyListeners();
      });

      // 7. Listen to latency
      _latencySub = _wsService.latencyStream.listen((ms) {
        _latencyMs = ms;
        notifyListeners();
      });

      _isDriving = true;
      notifyListeners();
      AppLogger.info('Driving session started');
    } catch (e) {
      AppLogger.error('Failed to start driving session', e);
      await stopDriving();
      rethrow;
    }
  }

  /// Stop the driving session.
  Future<void> stopDriving() async {
    AppLogger.info('Stopping driving session');

    _locationSub?.cancel();
    _nearbySub?.cancel();
    _connectionSub?.cancel();
    _latencySub?.cancel();

    _locationService.stopTracking();
    _wsService.disconnect();
    await _collisionService.stop();
    _batteryService.stop();

    _isDriving = false;
    _isConnected = false;
    _nearbyVehicles = [];
    _activeAlerts = [];
    _currentRiskLevel = RiskLevel.green;
    _currentSpeed = 0;
    _latencyMs = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    stopDriving();
    _locationService.dispose();
    _wsService.dispose();
    _collisionService.dispose();
    _batteryService.dispose();
    super.dispose();
  }
}
