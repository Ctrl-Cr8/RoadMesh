// ─── App Color Palette ────────────────────────────────────────────────────────
//
// Single source of truth for all colors in RoadMesh.
// Based on a deep-space dark theme with neon cyan/blue accents.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Backgrounds ────────────────────────────────────────────────────────────
  static const Color deepSpace    = Color(0xFF070B14);   // Page background
  static const Color surface      = Color(0xFF0D1220);   // Card surface
  static const Color surfaceAlt   = Color(0xFF111827);   // Elevated card
  static const Color surfacePop   = Color(0xFF1A2235);   // Hovered/active card

  // ─── Accent — Cyan / Blue ───────────────────────────────────────────────────
  static const Color cyberBlue    = Color(0xFF00E5FF);   // Primary CTA, active
  static const Color hyperBlue    = Color(0xFF2979FF);   // Secondary / gradient end
  static const Color neonPurple   = Color(0xFF7C4DFF);   // Tertiary accent

  // ─── Risk Colors ────────────────────────────────────────────────────────────
  static const Color safeGreen    = Color(0xFF00E676);   // SAFE / connected
  static const Color warningAmber = Color(0xFFFFB300);   // CAUTION
  static const Color dangerRed    = Color(0xFFFF1744);   // DANGER / error

  // ─── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted     = Color(0xFF546E7A);
  static const Color textHint      = Color(0xFF37474F);

  // ─── Glassmorphism ───────────────────────────────────────────────────────────
  static const Color glassWhite   = Color(0x14FFFFFF);  // 8% white
  static const Color glassBorder  = Color(0x1FFFFFFF);  // 12% white border
  static const Color glassBlue    = Color(0x1400E5FF);  // tinted glass

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyberBlue, hyperBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF070B14), Color(0xFF0D1527), Color(0xFF070B14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
  );

  // ─── Shadows ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> cyanGlow({double opacity = 0.35, double blur = 24}) => [
    BoxShadow(
      color: cyberBlue.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> dangerGlow({double opacity = 0.45, double blur = 24}) => [
    BoxShadow(
      color: dangerRed.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0xFF000000).withValues(alpha: 0.4),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
