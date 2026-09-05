// ─── Collision Alert Model ──────────────────────────────────────────────────

import 'package:flutter/material.dart';

enum RiskLevel {
  green,
  yellow,
  red;

  String get label {
    switch (this) {
      case RiskLevel.green:
        return 'GREEN';
      case RiskLevel.yellow:
        return 'YELLOW';
      case RiskLevel.red:
        return 'RED';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.green:
        return const Color(0xFF4CAF50);
      case RiskLevel.yellow:
        return const Color(0xFFFFC107);
      case RiskLevel.red:
        return const Color(0xFFF44336);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RiskLevel.green:
        return const Color(0x1A4CAF50);
      case RiskLevel.yellow:
        return const Color(0x33FFC107);
      case RiskLevel.red:
        return const Color(0x33F44336);
    }
  }

  static RiskLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RED':
        return RiskLevel.red;
      case 'YELLOW':
        return RiskLevel.yellow;
      default:
        return RiskLevel.green;
    }
  }
}

enum AlertType {
  headOn,
  overtake,
  blindCorner,
  rearEnd,
  laneMerge,
  wrongWay,
  stoppedVehicle,
  emergencyVehicle,
  vulnerableRoadUser;

  String get label {
    switch (this) {
      case AlertType.headOn:
        return 'HEAD_ON';
      case AlertType.overtake:
        return 'OVERTAKE';
      case AlertType.blindCorner:
        return 'BLIND_CORNER';
      case AlertType.rearEnd:
        return 'REAR_END';
      case AlertType.laneMerge:
        return 'LANE_MERGE';
      case AlertType.wrongWay:
        return 'WRONG_WAY';
      case AlertType.stoppedVehicle:
        return 'STOPPED_VEHICLE';
      case AlertType.emergencyVehicle:
        return 'EMERGENCY_VEHICLE';
      case AlertType.vulnerableRoadUser:
        return 'VULNERABLE_ROAD_USER';
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.headOn:
        return 'Head-On Collision';
      case AlertType.overtake:
        return 'Overtaking Vehicle';
      case AlertType.blindCorner:
        return 'Blind Corner';
      case AlertType.rearEnd:
        return 'Rear-End Risk';
      case AlertType.laneMerge:
        return 'Lane Merge';
      case AlertType.wrongWay:
        return 'Wrong-Way Vehicle';
      case AlertType.stoppedVehicle:
        return 'Stopped Vehicle';
      case AlertType.emergencyVehicle:
        return 'Emergency Vehicle';
      case AlertType.vulnerableRoadUser:
        return 'Pedestrian Crossing Ahead';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.headOn:
        return Icons.swap_vert;
      case AlertType.overtake:
        return Icons.fast_forward;
      case AlertType.blindCorner:
        return Icons.turn_right;
      case AlertType.rearEnd:
        return Icons.arrow_downward;
      case AlertType.laneMerge:
        return Icons.merge_type;
      case AlertType.wrongWay:
        return Icons.wrong_location;
      case AlertType.stoppedVehicle:
        return Icons.stop_circle;
      case AlertType.emergencyVehicle:
        return Icons.local_hospital;
      case AlertType.vulnerableRoadUser:
        return Icons.directions_walk;
    }
  }

  static AlertType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HEAD_ON':
        return AlertType.headOn;
      case 'OVERTAKE':
        return AlertType.overtake;
      case 'BLIND_CORNER':
        return AlertType.blindCorner;
      case 'REAR_END':
        return AlertType.rearEnd;
      case 'LANE_MERGE':
        return AlertType.laneMerge;
      case 'WRONG_WAY':
        return AlertType.wrongWay;
      case 'STOPPED_VEHICLE':
        return AlertType.stoppedVehicle;
      case 'EMERGENCY_VEHICLE':
        return AlertType.emergencyVehicle;
      case 'VULNERABLE_ROAD_USER':
      case 'PEDESTRIAN_CROSSING':
        return AlertType.vulnerableRoadUser;
      default:
        return AlertType.blindCorner;
    }
  }
}

class CollisionAlert {
  final String vehicleId;
  final RiskLevel riskLevel;
  final AlertType alertType;
  final double timeToCollision;
  final double distance;
  final double bearing;

  const CollisionAlert({
    required this.vehicleId,
    required this.riskLevel,
    required this.alertType,
    required this.timeToCollision,
    required this.distance,
    required this.bearing,
  });

  factory CollisionAlert.fromJson(Map<String, dynamic> json) {
    return CollisionAlert(
      vehicleId: json['vehicleId'] as String,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String),
      alertType: AlertType.fromString(json['alertType'] as String),
      timeToCollision: (json['timeToCollision'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      bearing: (json['bearing'] as num).toDouble(),
    );
  }

  /// Human-readable description of the alert.
  String get description {
    final dist = '${distance.toStringAsFixed(0)}m';
    final time = timeToCollision > 0
        ? '${timeToCollision.toStringAsFixed(0)}s'
        : 'NOW';
    return '${alertType.displayName} — $dist, $time';
  }

  /// Voice alert text for TTS.
  String get voiceAlert {
    switch (alertType) {
      case AlertType.headOn:
        return riskLevel == RiskLevel.red
            ? 'Warning! Head-on collision imminent!'
            : 'Caution. Vehicle approaching head-on.';
      case AlertType.overtake:
        return 'Caution. Vehicle overtaking nearby.';
      case AlertType.blindCorner:
        return riskLevel == RiskLevel.red
            ? 'Warning! Vehicle from blind corner!'
            : 'Caution. Vehicle around the corner.';
      case AlertType.rearEnd:
        return 'Caution. Vehicle approaching from behind.';
      case AlertType.laneMerge:
        return 'Caution. Vehicle merging into your lane.';
      case AlertType.wrongWay:
        return 'Danger! Wrong-way vehicle approaching!';
      case AlertType.stoppedVehicle:
        return 'Caution. Stopped vehicle ahead.';
      case AlertType.emergencyVehicle:
        return 'Emergency vehicle approaching. Please yield.';
      case AlertType.vulnerableRoadUser:
        return 'Caution: Pedestrian crossing active outside School Zone. Reduce speed to 20.';
    }
  }
}
