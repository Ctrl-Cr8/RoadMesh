// ─── Configuration Constants ────────────────────────────────────────────────

class AppConstants {
  // Server
  static const String defaultServerHost = '10.0.2.2'; // Android emulator → localhost
  static const int defaultServerPort = 3000;
  static String get defaultWsUrl => 'ws://$defaultServerHost:$defaultServerPort/ws';

  // Timing
  static const int positionUpdateIntervalMs = 1000;
  static const int reconnectDelayMs = 3000;
  static const int vehicleExpiryMs = 8000;

  // Map
  static const double defaultZoom = 16.0;
  static const double defaultLat = 10.0261;
  static const double defaultLng = 76.3125;

  // Safety
  static const double nearbyRadiusMeters = 500.0;
  static const double redAlertDistanceMeters = 30.0;
  static const double yellowAlertDistanceMeters = 80.0;

  // UI
  static const double mapPadding = 50.0;
}
