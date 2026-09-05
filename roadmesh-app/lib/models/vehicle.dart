// ─── Vehicle Model ──────────────────────────────────────────────────────────

enum VehicleType {
  car,
  autoRickshaw,
  motorcycle,
  bus,
  truck,
  ambulance,
  bicycle,
  pedestrian,
  unknown;

  String get label {
    switch (this) {
      case VehicleType.car:
        return 'CAR';
      case VehicleType.autoRickshaw:
        return 'AUTO_RICKSHAW';
      case VehicleType.motorcycle:
        return 'MOTORCYCLE';
      case VehicleType.bus:
        return 'BUS';
      case VehicleType.truck:
        return 'TRUCK';
      case VehicleType.ambulance:
        return 'AMBULANCE';
      case VehicleType.bicycle:
        return 'BICYCLE';
      case VehicleType.pedestrian:
        return 'PEDESTRIAN';
      case VehicleType.unknown:
        return 'UNKNOWN';
    }
  }

  String get shortLabel {
    switch (this) {
      case VehicleType.car:
        return 'CAR';
      case VehicleType.autoRickshaw:
        return 'AUTO';
      case VehicleType.motorcycle:
        return 'BIKE';
      case VehicleType.bus:
        return 'BUS';
      case VehicleType.truck:
        return 'TRUCK';
      case VehicleType.ambulance:
        return 'EMS';
      case VehicleType.bicycle:
        return 'CYCLE';
      case VehicleType.pedestrian:
        return 'VRU';
      case VehicleType.unknown:
        return 'VEH';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car / Taxi';
      case VehicleType.autoRickshaw:
        return 'Auto Rickshaw (3W)';
      case VehicleType.motorcycle:
        return 'Two-Wheeler (Bike)';
      case VehicleType.bus:
        return 'Bus / Public Transit';
      case VehicleType.truck:
        return 'Commercial Truck';
      case VehicleType.ambulance:
        return 'Emergency Ambulance';
      case VehicleType.bicycle:
        return 'Bicycle / Cyclist';
      case VehicleType.pedestrian:
        return 'Pedestrian (VRU)';
      case VehicleType.unknown:
        return 'Generic Vehicle';
    }
  }

  String get categorySubtitle {
    switch (this) {
      case VehicleType.car:
        return 'Standard Passenger';
      case VehicleType.autoRickshaw:
        return 'Urban 3-Wheeler';
      case VehicleType.motorcycle:
        return 'Agile Two-Wheeler';
      case VehicleType.bus:
        return 'Public Transit';
      case VehicleType.truck:
        return 'Commercial Freight';
      case VehicleType.ambulance:
        return 'Emergency Priority';
      case VehicleType.bicycle:
        return 'Cyclist (VRU)';
      case VehicleType.pedestrian:
        return 'Pedestrian (VRU)';
      case VehicleType.unknown:
        return 'Generic Node';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.autoRickshaw:
        return '🛺';
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.bus:
        return '🚌';
      case VehicleType.truck:
        return '🚛';
      case VehicleType.ambulance:
        return '🚑';
      case VehicleType.bicycle:
        return '🚲';
      case VehicleType.pedestrian:
        return '🚶';
      case VehicleType.unknown:
        return '🚙';
    }
  }

  static VehicleType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CAR':
        return VehicleType.car;
      case 'AUTO_RICKSHAW':
      case 'AUTO':
      case 'RICKSHAW':
        return VehicleType.autoRickshaw;
      case 'MOTORCYCLE':
      case 'BIKE':
      case 'SCOOTER':
        return VehicleType.motorcycle;
      case 'BUS':
        return VehicleType.bus;
      case 'TRUCK':
        return VehicleType.truck;
      case 'AMBULANCE':
      case 'EMERGENCY':
        return VehicleType.ambulance;
      case 'BICYCLE':
      case 'CYCLE':
        return VehicleType.bicycle;
      case 'PEDESTRIAN':
      case 'WALKER':
        return VehicleType.pedestrian;
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
