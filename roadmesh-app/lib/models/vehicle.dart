// ─── Vehicle Model ──────────────────────────────────────────────────────────

enum VehicleType {
  car,
  truck,
  motorcycle,
  bus,
  ambulance,
  unknown;

  String get label {
    switch (this) {
      case VehicleType.car:
        return 'CAR';
      case VehicleType.truck:
        return 'TRUCK';
      case VehicleType.motorcycle:
        return 'MOTORCYCLE';
      case VehicleType.bus:
        return 'BUS';
      case VehicleType.ambulance:
        return 'AMBULANCE';
      case VehicleType.unknown:
        return 'UNKNOWN';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.truck:
        return '🚛';
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.bus:
        return '🚌';
      case VehicleType.ambulance:
        return '🚑';
      case VehicleType.unknown:
        return '🚙';
    }
  }

  static VehicleType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CAR':
        return VehicleType.car;
      case 'TRUCK':
        return VehicleType.truck;
      case 'MOTORCYCLE':
        return VehicleType.motorcycle;
      case 'BUS':
        return VehicleType.bus;
      case 'AMBULANCE':
        return VehicleType.ambulance;
      default:
        return VehicleType.unknown;
    }
  }
}

class Vehicle {
  final String id;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final VehicleType vehicleType;
  final int timestamp;

  const Vehicle({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.vehicleType,
    required this.timestamp,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      vehicleType: VehicleType.fromString(json['vehicleType'] as String? ?? 'UNKNOWN'),
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'vehicleType': vehicleType.label,
      'timestamp': timestamp,
    };
  }

  /// Check if this vehicle data is stale.
  bool get isStale {
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age > 8000; // 8 seconds
  }

  /// Get speed in a display-friendly format.
  String get speedDisplay => '${speed.toStringAsFixed(0)} km/h';

  /// Get heading as compass direction.
  String get headingDisplay {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    return 'NW';
  }
}
