// ─── WebSocket Communication Service ──────────────────────────────────────────
//
// Improvements over v1:
// - Exponential backoff reconnect (1→2→4→8→16→30s cap)
// - PING/PONG latency measurement
// - Connection quality tracking
// - AppLogger integration (no print() calls)

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../config/constants.dart';
import 'app_logger.dart';

class NearbyUpdate {
  final List<Vehicle> vehicles;
  final List<CollisionAlert> alerts;

  const NearbyUpdate({required this.vehicles, required this.alerts});
}

class WebSocketService {
  WebSocketChannel? _channel;
  String? vehicleId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;

  // Latency tracking
  int? _lastPingSentAt;
  int _latencyMs = 0;

  final StreamController<NearbyUpdate> _nearbyController =
      StreamController.broadcast();
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  final StreamController<int> _latencyController =
      StreamController.broadcast();

  Stream<NearbyUpdate> get nearbyStream => _nearbyController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get latencyStream => _latencyController.stream;
  bool get isConnected => _isConnected;
  int get latencyMs => _latencyMs;

  String _currentUrl = '';

  /// Connect to the RoadMesh server.
  Future<void> connect({String? serverUrl}) async {
    _currentUrl = serverUrl ?? AppConstants.defaultWsUrl;
    AppLogger.info('Connecting to WebSocket: $_currentUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_currentUrl));
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      AppLogger.info('WebSocket connected');

      _startPingTimer();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data.toString());
        },
        onDone: () {
          AppLogger.warning('WebSocket closed by server');
          _handleDisconnect();
        },
        onError: (error) {
          AppLogger.error('WebSocket error', error);
          _handleDisconnect();
        },
      );
    } catch (e) {
      AppLogger.error('WebSocket connection failed', e);
      _handleDisconnect();
    }
  }

  /// Handle incoming WebSocket messages.
  void _handleMessage(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'REGISTER':
          vehicleId = json['payload']?['id'] as String?;
          AppLogger.info('Registered as vehicle: $vehicleId');
          break;

        case 'NEARBY_VEHICLES':
          final payload = json['payload'] as Map<String, dynamic>;
          final vehicles = (payload['vehicles'] as List<dynamic>?)
                  ?.map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
                  .toList() ??
              [];
          final alerts = (payload['alerts'] as List<dynamic>?)
                  ?.map((a) => CollisionAlert.fromJson(a as Map<String, dynamic>))
                  .toList() ??
              [];
          _nearbyController.add(NearbyUpdate(vehicles: vehicles, alerts: alerts));
          break;

        case 'PONG':
          if (_lastPingSentAt != null) {
            _latencyMs = DateTime.now().millisecondsSinceEpoch - _lastPingSentAt!;
            _latencyController.add(_latencyMs);
            _lastPingSentAt = null;
            AppLogger.debug('Latency: ${_latencyMs}ms');
          }
          break;
      }
    } catch (e) {
      AppLogger.error('Error parsing WebSocket message', e);
    }
  }

  /// Send a position update to the server.
  void sendPositionUpdate({
    required double lat,
    required double lng,
    required double speed,
    required double heading,
    required String vehicleType,
  }) {
    if (!_isConnected || _channel == null) return;

    final message = jsonEncode({
      'type': 'POSITION_UPDATE',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'vehicleType': vehicleType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    });

    _channel!.sink.add(message);
  }

  /// Send a PING to measure latency.
  void _sendPing() {
    if (!_isConnected || _channel == null) return;
    _lastPingSentAt = DateTime.now().millisecondsSinceEpoch;
    _channel!.sink.add(jsonEncode({
      'type': 'PING',
      'timestamp': _lastPingSentAt,
      'payload': {'clientTime': _lastPingSentAt},
    }));
  }

  /// Start periodic pings.
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _sendPing());
  }

  /// Handle disconnection with exponential backoff.
  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _channel = null;
    _scheduleReconnect();
  }

  /// Schedule reconnection with exponential backoff (capped at 30s).
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _backoffDelay(_reconnectAttempts);
    _reconnectAttempts++;
    AppLogger.info('Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(
      Duration(seconds: delay),
      () => connect(serverUrl: _currentUrl),
    );
  }

  int _backoffDelay(int attempt) {
    // 1, 2, 4, 8, 16, 30, 30, 30...
    const delays = [1, 2, 4, 8, 16, 30];
    return delays[attempt.clamp(0, delays.length - 1)];
  }

  /// Send a heartbeat to keep the connection alive.
  void sendHeartbeat() {
    if (!_isConnected || _channel == null || vehicleId == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'HEARTBEAT',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {'id': vehicleId},
    }));
  }

  /// Disconnect from the server.
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
    vehicleId = null;
    _reconnectAttempts = 0;
    AppLogger.info('WebSocket disconnected');
  }

  void dispose() {
    disconnect();
    _nearbyController.close();
    _connectionController.close();
    _latencyController.close();
  }
}
