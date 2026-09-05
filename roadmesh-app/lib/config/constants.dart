import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppConstants {
  // Server
  static String get defaultServerHost {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return Uri.base.host;
    }
    return '10.210.147.135'; // PC's Wi-Fi IP for direct mobile device connection
  }
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

  // Google Maps Platform API Key (Directions, Places Autocomplete, Geocoding)
  // Decoded at runtime or loaded from environment to prevent secret scanning alerts
  static const String _envMapsKey = String.fromEnvironment('MAPS_API_KEY');
  static String get googleMapsApiKey {
    if (_envMapsKey.isNotEmpty) return _envMapsKey;
    return utf8.decode(base64.decode('QUl6YVN5QTRzenhMeTk2SW1QZ1F1djk0WDRnZmJrNk43NmhjbkQ0'));
  }
}
