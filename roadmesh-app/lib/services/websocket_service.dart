// ─── WebSocket Communication Service ────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../config/constants.dart';

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

  final StreamController<NearbyUpdate> _nearbyController =
      StreamController.broadcast();
  final StreamController<bool> _connectionController =
      StreamController.broadcast();

  Stream<NearbyUpdate> get nearbyStream => _nearbyController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  /// Connect to the RoadMesh server.
  Future<void> connect({String? serverUrl}) async {
    final url = serverUrl ?? AppConstants.defaultWsUrl;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _connectionController.add(true);

      _channel!.stream.listen(
        (data) {
          _handleMessage(data.toString());
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect(url);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect(url);
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect(url);
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
          print('Registered as vehicle: $vehicleId');
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

          _nearbyController.add(NearbyUpdate(
            vehicles: vehicles,
            alerts: alerts,
          ));
          break;
      }
    } catch (e) {
      print('Error parsing message: $e');
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

  /// Send a heartbeat to keep the connection alive.
  void sendHeartbeat() {
    if (!_isConnected || _channel == null || vehicleId == null) return;

    final message = jsonEncode({
      'type': 'HEARTBEAT',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {'id': vehicleId},
    });

    _channel!.sink.add(message);
  }

  /// Schedule a reconnection attempt.
  void _scheduleReconnect(String url) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: AppConstants.reconnectDelayMs),
      () => connect(serverUrl: url),
    );
  }

  /// Disconnect from the server.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
    vehicleId = null;
  }

  void dispose() {
    disconnect();
    _nearbyController.close();
    _connectionController.close();
  }
}
