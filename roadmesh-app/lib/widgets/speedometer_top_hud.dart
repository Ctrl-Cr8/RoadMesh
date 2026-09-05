// ─── Speedometer Top HUD (Dual Speed Gauge) ──────────────────────────────────
//
// Matches Image 2: Overlapping dual-circle gauge with red speed limit ring (100)
// and white current speed circle (87) with speed camera icon & overspeed warning.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SpeedometerTopHud extends StatelessWidget {
  final double currentSpeed;
  final double speedLimit;
  final bool isDark;
  final VoidCallback? onTap;

  const SpeedometerTopHud({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
    this.isDark = false,
    this.onTap,
  });

  bool get isOverspeeding => currentSpeed > speedLimit && speedLimit > 0;

  @override
  Widget build(BuildContext context) {
    final speedInt = currentSpeed.round().clamp(0, 999);
    final limitInt = speedLimit.round().clamp(10, 200);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // 1. Red Speed Limit Ring (Background Circle)
          Transform.translate(
            offset: const Offset(-28, 0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navSpeedRedRing,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navSpeedRedRing.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$limitInt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // 2. Current Speed Circle (Foreground Overlapping Circle)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverspeeding
                  ? AppColors.dangerRed
                  : (isDark ? const Color(0xFF1E283A) : Colors.white),
              border: Border.all(
                color: isOverspeeding
                    ? Colors.white
                    : (isDark ? Colors.white24 : AppColors.navBorderLight),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOverspeeding
                      ? AppColors.dangerRed.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: isOverspeeding ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$speedInt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isOverspeeding
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.navTextDark),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 1),
                Icon(
                  Icons.camera_alt_rounded,
                  size: 11,
                  color: isOverspeeding
                      ? Colors.white
                      : (isDark ? Colors.white60 : AppColors.navTextMutedLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
