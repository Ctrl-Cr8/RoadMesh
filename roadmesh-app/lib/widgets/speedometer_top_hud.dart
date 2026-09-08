// ─── Speedometer Top HUD (Vehicle Speed Readout) ─────────────────────────
//
// Clean floating vehicle speedometer displaying real driving speed in km/h.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SpeedometerTopHud extends StatelessWidget {
  final double currentSpeed;
  final bool isDark;
  final VoidCallback? onTap;

  const SpeedometerTopHud({
    super.key,
    required this.currentSpeed,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final speedInt = currentSpeed.round().clamp(0, 999);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E283A) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white24 : AppColors.navBorderLight,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
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
                color: isDark ? Colors.white : AppColors.navTextDark,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'km/h',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: isDark ? Colors.white60 : AppColors.navTextMutedLight,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
