// ─── Battery Service ──────────────────────────────────────────────────────────
//
// Wraps battery_plus to provide battery level as a stream.
// Used by LocationService for adaptive tracking frequency.

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'app_logger.dart';

class BatteryService {
  final Battery _battery = Battery();
  final StreamController<int> _levelController =
      StreamController<int>.broadcast();

  int _currentLevel = 100;
  Timer? _pollTimer;

  Stream<int> get levelStream => _levelController.stream;
  int get currentLevel => _currentLevel;

  /// Whether the battery is considered low (affects GPS frequency).
  bool get isLowBattery => _currentLevel < 30;

  /// Start polling battery level every 60 seconds.
  Future<void> start() async {
    try {
      _currentLevel = await _battery.batteryLevel;
      _levelController.add(_currentLevel);
      AppLogger.info('Battery: $_currentLevel%');
    } catch (e) {
      AppLogger.warning('Battery level not available on this platform/environment: $e');
      _currentLevel = 100;
      _levelController.add(_currentLevel);
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        _currentLevel = await _battery.batteryLevel;
        _levelController.add(_currentLevel);
        AppLogger.debug('Battery poll: $_currentLevel%');
      } catch (e) {
        // Silently ignore periodic poll errors on platforms without battery API
      }
    });
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stop();
    _levelController.close();
  }
}
