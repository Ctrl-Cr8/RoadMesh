// ─── Navigation Route & Maneuver Models ───────────────────────────────────────
//
// Represents destinations, turn-by-turn maneuvers, and navigation polylines.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ManeuverType {
  straight,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  uTurn,
  roundabout,
  merge,
  fork,
  offRamp,
  onRamp,
  arrive,
}

extension ManeuverTypeExtension on ManeuverType {
  IconData get icon {
    switch (this) {
      case ManeuverType.straight:
        return Icons.straight_rounded;
      case ManeuverType.turnLeft:
        return Icons.turn_left_rounded;
      case ManeuverType.turnRight:
        return Icons.turn_right_rounded;
      case ManeuverType.slightLeft:
        return Icons.turn_slight_left_rounded;
      case ManeuverType.slightRight:
        return Icons.turn_slight_right_rounded;
      case ManeuverType.uTurn:
        return Icons.u_turn_left_rounded;
      case ManeuverType.roundabout:
        return Icons.roundabout_left_rounded;
      case ManeuverType.merge:
        return Icons.merge_type_rounded;
      case ManeuverType.fork:
        return Icons.fork_right_rounded;
      case ManeuverType.offRamp:
        return Icons.ramp_right_rounded;
      case ManeuverType.onRamp:
        return Icons.merge_rounded;
      case ManeuverType.arrive:
        return Icons.flag_rounded;
    }
  }

  String get instructionPrefix {
    switch (this) {
      case ManeuverType.straight:
        return 'Continue straight on';
      case ManeuverType.turnLeft:
        return 'Turn left onto';
      case ManeuverType.turnRight:
        return 'Turn right onto';
      case ManeuverType.slightLeft:
        return 'Keep left onto';
      case ManeuverType.slightRight:
        return 'Keep right onto';
      case ManeuverType.uTurn:
        return 'Make a U-turn at';
      case ManeuverType.roundabout:
        return 'Take the roundabout to';
      case ManeuverType.merge:
        return 'Merge onto';
      case ManeuverType.fork:
        return 'Keep right at the fork onto';
      case ManeuverType.offRamp:
        return 'Take the exit onto';
      case ManeuverType.onRamp:
        return 'Take the ramp onto';
      case ManeuverType.arrive:
        return 'Arrive at destination';
    }
  }

  static ManeuverType fromOsrm(String? type, String? modifier) {
    if (type == 'arrive') return ManeuverType.arrive;
    if (type == 'roundabout' || type == 'rotary') return ManeuverType.roundabout;
    if (type == 'merge') return ManeuverType.merge;
    if (type == 'fork') return ManeuverType.fork;
    if (type == 'off ramp') return ManeuverType.offRamp;
    if (type == 'on ramp') return ManeuverType.onRamp;

    final mod = (modifier ?? '').toLowerCase();
    if (mod.contains('uturn')) return ManeuverType.uTurn;
    if (mod.contains('slight left')) return ManeuverType.slightLeft;
    if (mod.contains('left')) return ManeuverType.turnLeft;
    if (mod.contains('slight right')) return ManeuverType.slightRight;
    if (mod.contains('right')) return ManeuverType.turnRight;
    return ManeuverType.straight;
  }

  static ManeuverType fromGoogle(String? maneuver, String? htmlInstruction) {
    final m = (maneuver ?? '').toLowerCase();
    final h = (htmlInstruction ?? '').toLowerCase();

    if (m.contains('arrive') || h.contains('arrive') || h.contains('destination')) {
      return ManeuverType.arrive;
    }
    if (m.contains('roundabout') || h.contains('roundabout') || h.contains('rotary')) {
      return ManeuverType.roundabout;
    }
    if (m.contains('u-turn') || m.contains('uturn') || h.contains('u-turn')) {
      return ManeuverType.uTurn;
    }
    if (m.contains('slight-left') || m.contains('slight left') || h.contains('slight left')) {
      return ManeuverType.slightLeft;
    }
    if (m.contains('slight-right') || m.contains('slight right') || h.contains('slight right')) {
      return ManeuverType.slightRight;
    }
    if (m.contains('left') || h.contains('turn left')) {
      return ManeuverType.turnLeft;
    }
    if (m.contains('right') || h.contains('turn right')) {
      return ManeuverType.turnRight;
    }
    if (m.contains('merge') || h.contains('merge')) {
      return ManeuverType.merge;
    }
    if (m.contains('fork') || h.contains('fork')) {
      return ManeuverType.fork;
    }
    if (m.contains('ramp') || h.contains('ramp') || h.contains('exit')) {
      return ManeuverType.offRamp;
    }
    return ManeuverType.straight;
  }
}

class NavigationStep {
  final String instruction;
  final String streetName;
  final double distanceMeters;
  final ManeuverType maneuver;
  final LatLng location;

  const NavigationStep({
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
    required this.maneuver,
    required this.location,
  });
}

class NavDestination {
  final String id;
  final String title;
  final String subtitle;
  final LatLng location;
  final IconData icon;
  final double? distanceFromUserMeters;

  const NavDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    this.icon = Icons.place_rounded,
    this.distanceFromUserMeters,
  });

  String? get formattedProximity {
    if (distanceFromUserMeters == null) return null;
    if (distanceFromUserMeters! >= 1000) {
      return '${(distanceFromUserMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceFromUserMeters!.toStringAsFixed(0)} m';
  }
}

class ActiveNavigationRoute {
  final NavDestination destination;
  final List<LatLng> polylinePoints;
  final List<NavigationStep> steps;
  final double totalDistanceMeters;
  final int estimatedSeconds;

  const ActiveNavigationRoute({
    required this.destination,
    required this.polylinePoints,
    required this.steps,
    required this.totalDistanceMeters,
    required this.estimatedSeconds,
  });

  String get formattedDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.toStringAsFixed(0)} m';
  }

  String get formattedDuration {
    final minutes = (estimatedSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMin = minutes % 60;
      return '${hours}h ${remainingMin}m';
    }
    return '$minutes min';
  }
}
