// ─── Driving Status Bar Widget ──────────────────────────────────────────────
//
// Top bar showing connection status, speed, heading, and nearby vehicle count.

import 'package:flutter/material.dart';
import '../models/alert.dart';

class DrivingStatusBar extends StatelessWidget {
  final bool isConnected;
  final double speed;
  final double heading;
  final int nearbyCount;
  final RiskLevel riskLevel;

  const DrivingStatusBar({
    super.key,
    required this.isConnected,
    required this.speed,
    required this.heading,
    required this.nearbyCount,
    required this.riskLevel,
  });

  String _headingToCompass(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE60A0E1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskLevel.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Connection indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
              boxShadow: [
                BoxShadow(
                  color: (isConnected
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336))
                      .withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Speed
          Text(
            '${speed.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            ' km/h',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),

          const Spacer(),

          // Heading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: const Color(0xFF00E5FF),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _headingToCompass(heading),
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Nearby count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: nearbyCount > 0
                  ? riskLevel.color.withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: nearbyCount > 0
                      ? riskLevel.color
                      : Colors.white.withOpacity(0.5),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$nearbyCount',
                  style: TextStyle(
                    color: nearbyCount > 0
                        ? riskLevel.color
                        : Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
