// ─── Turn-by-Turn Navigation Banner Widget ────────────────────────────────────
//
// Floating cockpit card showing the active turn maneuver, next street,
// distance countdown, remaining trip distance, and ETA.
// Clean daylight white theme matching the reference Images.

import 'package:flutter/material.dart';
import '../navigation/navigation_route.dart';
import '../theme/app_colors.dart';

class NavigationBanner extends StatelessWidget {
  final ActiveNavigationRoute route;
  final NavigationStep currentStep;
  final double distanceToNextTurn;
  final VoidCallback onCancel;

  const NavigationBanner({
    super.key,
    required this.route,
    required this.currentStep,
    required this.distanceToNextTurn,
    required this.onCancel,
  });

  String _formatManeuverDistance(double meters) {
    if (meters >= 1000) {
      return 'In ${(meters / 1000).toStringAsFixed(1)} km';
    }
    return 'In ${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Maneuver Arrow Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cyberBlue.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.cyberBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              currentStep.maneuver.icon,
              color: AppColors.cyberBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Maneuver Distance & Street Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatManeuverDistance(distanceToNextTurn),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentStep.instruction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ETA & Trip Remaining
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                route.formattedDuration,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.safeGreen,
                ),
              ),
              Text(
                route.formattedDistance,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Cancel Route Button
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textMuted,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
