// ─── Floating Map Dock (Right Vertical Controls) ─────────────────────────────
//
// Matches Images 1 & 2: Vertical control stack on right edge with:
// - Zoom In (+) & Zoom Out (-) in a combined pill
// - Hazard / V2X broadcast (💬)
// - Day / Night theme switcher (☀️ / 🌙)
// - 3D / 2D perspective toggle
// - Compass True North (🧭)
// - Recenter on Driver (▲)

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FloatingMapDock extends StatelessWidget {
  final bool isDark;
  final bool is3D;
  final bool isCameraLocked;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReportHazard;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggle3D;
  final VoidCallback onResetCompass;
  final VoidCallback onRecenter;

  const FloatingMapDock({
    super.key,
    required this.isDark,
    required this.is3D,
    required this.isCameraLocked,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReportHazard,
    required this.onToggleTheme,
    required this.onToggle3D,
    required this.onResetCompass,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xEE131C2E) : Colors.white;
    final iconColor = isDark ? Colors.white : AppColors.navTextDark;
    final borderColor = isDark ? Colors.white12 : AppColors.navBorderLight;
    final dividerColor = isDark ? Colors.white12 : AppColors.navBorderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Zoom In / Zoom Out Combined Pill
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: isDark ? AppColors.floatingPillShadowDark : AppColors.floatingPillShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockIconButton(
                icon: Icons.add_rounded,
                iconColor: iconColor,
                onTap: onZoomIn,
              ),
              Container(width: 24, height: 1, color: dividerColor),
              _DockIconButton(
                icon: Icons.remove_rounded,
                iconColor: iconColor,
                onTap: onZoomOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Hazard Report Button
        _StandaloneDockButton(
          bgColor: bgColor,
          borderColor: borderColor,
          isDark: isDark,
          icon: Icons.add_comment_rounded,
          iconColor: iconColor,
          onTap: onReportHazard,
        ),
        const SizedBox(height: 10),

        // 3. Day / Night Theme Switcher
        _StandaloneDockButton(
          bgColor: bgColor,
          borderColor: borderColor,
          isDark: isDark,
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          iconColor: isDark ? Colors.amber : iconColor,
          onTap: onToggleTheme,
        ),
        const SizedBox(height: 10),

        // 4. 3D / 2D Perspective Toggle
        _StandaloneDockButton(
          bgColor: bgColor,
          borderColor: borderColor,
          isDark: isDark,
          label: is3D ? '3D' : '2D',
          labelColor: is3D ? AppColors.navRouteGreen : iconColor,
          onTap: onToggle3D,
        ),
        const SizedBox(height: 10),

        // 5. Compass True North Needle
        _StandaloneDockButton(
          bgColor: bgColor,
          borderColor: borderColor,
          isDark: isDark,
          icon: Icons.explore_rounded,
          iconColor: Colors.redAccent,
          onTap: onResetCompass,
        ),
        const SizedBox(height: 10),

        // 6. Recenter on Driver (Navigation Arrow)
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCameraLocked
                ? (isDark ? AppColors.navPillDark : Colors.white)
                : AppColors.navRouteGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCameraLocked ? borderColor : AppColors.navRouteGreen,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isCameraLocked
                    ? Colors.black.withValues(alpha: 0.15)
                    : AppColors.navRouteGreen.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.navigation_rounded,
              size: 20,
              color: isCameraLocked ? iconColor : Colors.black,
            ),
            onPressed: onRecenter,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _StandaloneDockButton extends StatelessWidget {
  final Color bgColor;
  final Color borderColor;
  final bool isDark;
  final IconData? icon;
  final Color? iconColor;
  final String? label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _StandaloneDockButton({
    required this.bgColor,
    required this.borderColor,
    required this.isDark,
    this.icon,
    this.iconColor,
    this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: isDark ? AppColors.floatingPillShadowDark : AppColors.floatingPillShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: labelColor ?? Colors.white,
                  ),
                )
              : Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}
