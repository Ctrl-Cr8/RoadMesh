// ─── Maneuver Top HUD (Turn-by-Turn Card) ────────────────────────────────────
//
// Matches Image 2: Clean floating card at top-left showing next turn maneuver
// arrow in vibrant blue, distance remaining to turn (e.g. "110 m"), and road name.

import 'package:flutter/material.dart';
import '../navigation/navigation_route.dart';
import '../theme/app_colors.dart';

class ManeuverTopHud extends StatelessWidget {
  final NavigationStep step;
  final double distanceToTurnMeters;
  final bool isDark;
  final VoidCallback? onCancel;

  const ManeuverTopHud({
    super.key,
    required this.step,
    required this.distanceToTurnMeters,
    this.isDark = false,
    this.onCancel,
  });

  String get _formattedDistance {
    if (distanceToTurnMeters >= 1000) {
      return '${(distanceToTurnMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceToTurnMeters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xEE131C2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.navTextDark;
    final subColor = isDark ? AppColors.textMuted : AppColors.navTextMutedLight;
    final borderColor = isDark ? Colors.white12 : AppColors.navBorderLight;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isDark ? AppColors.floatingPillShadowDark : AppColors.floatingPillShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vibrant Blue Turn Arrow
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.navArrowBlue.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              step.maneuver.icon,
              color: AppColors.navArrowBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),

          // Distance and Road Name
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formattedDistance,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.streetName.isNotEmpty ? step.streetName : 'Ahead',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subColor,
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
