// ─── Warning Overlay Widget ─────────────────────────────────────────────────
//
// Bottom overlay showing active collision alerts with color-coded cards.

import 'package:flutter/material.dart';
import '../models/alert.dart';

class WarningOverlay extends StatelessWidget {
  final List<CollisionAlert> alerts;

  const WarningOverlay({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: alerts.take(3).map((alert) => _buildAlertCard(alert)).toList(),
    );
  }

  Widget _buildAlertCard(CollisionAlert alert) {
    final isRed = alert.riskLevel == RiskLevel.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: alert.riskLevel.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert.riskLevel.color.withOpacity(0.5),
          width: isRed ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.riskLevel.color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Alert icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: alert.riskLevel.color.withOpacity(0.2),
            ),
            child: Icon(
              alert.alertType.icon,
              color: alert.riskLevel.color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Alert text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.alertType.displayName,
                  style: TextStyle(
                    color: alert.riskLevel.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.distance.toStringAsFixed(0)}m away',
                  style: TextStyle(
                    color: alert.riskLevel.color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Time to collision
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: alert.riskLevel.color.withOpacity(isRed ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert.timeToCollision > 0
                  ? '${alert.timeToCollision.toStringAsFixed(0)}s'
                  : 'NOW',
              style: TextStyle(
                color: alert.riskLevel.color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
