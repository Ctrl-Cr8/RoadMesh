// ─── App Color Palette ────────────────────────────────────────────────────────
//
// Single source of truth for all colors in RoadMesh.
// Based on a deep-space dark theme with neon cyan/blue accents.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Backgrounds (Clean Daylight Navigation Aesthetic) ──────────────────────
  static const Color deepSpace    = Color(0xFFF8FAFC);   // Daylight page background
  static const Color surface      = Color(0xFFFFFFFF);   // Pure white card surface
  static const Color surfaceAlt   = Color(0xFFF1F5F9);   // Soft elevated card
  static const Color surfacePop   = Color(0xFFE2E8F0);   // Hovered/active chip

  // ─── Accent — Modern Automotive Blue ─────────────────────────────────────────
  static const Color cyberBlue    = Color(0xFF2563EB);   // Primary Automotive Blue CTA, active
  static const Color hyperBlue    = Color(0xFF1D4ED8);   // Deep royal blue accent
  static const Color neonPurple   = Color(0xFF6366F1);   // Indigo accent

  // ─── Risk Colors ────────────────────────────────────────────────────────────
  static const Color safeGreen    = Color(0xFF10B981);   // SAFE / connected emerald
  static const Color warningAmber = Color(0xFFF59E0B);   // CAUTION amber
  static const Color dangerRed    = Color(0xFFEF4444);   // DANGER red

  // ─── Text (High-contrast Daylight Hierarchy) ──────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);   // Primary dark slate
  static const Color textSecondary = Color(0xFF475569);   // Secondary slate
  static const Color textMuted     = Color(0xFF64748B);   // Muted slate
  static const Color textHint      = Color(0xFF94A3B8);   // Placeholder slate

  // ─── Glassmorphism & Borders ──────────────────────────────────────────────────
  static const Color glassWhite   = Color(0xFFFFFFFF);  // Pure white card
  static const Color glassBorder  = Color(0xFFE2E8F0);  // Soft border line
  static const Color glassBlue    = Color(0x142563EB);  // Subtle blue tint

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFEDF2F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF10B981)],
  );

  // ─── Shadows ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> cyanGlow({double opacity = 0.20, double blur = 18}) => [
    BoxShadow(
      color: cyberBlue.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 4),
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
      color: Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  // ─── Modern Navigation Palette (Reference Images) ──────────────────────────
  static const Color navRouteGreen   = Color(0xFF00C853); // Primary road polyline
  static const Color navRouteOrange  = Color(0xFFFF9100); // Moderate traffic
  static const Color navRouteRed     = Color(0xFFFF3D00); // Congestion / hazard
  static const Color navPillWhite    = Color(0xFFFFFFFF); // Floating card light
  static const Color navPillDark     = Color(0xFF151C2A); // Floating card dark
  static const Color navSpeedRedRing = Color(0xFFD50000); // Speed limit red circle
  static const Color navSpeedCamera  = Color(0xFFD50000); // Speed camera badge
  static const Color navLaneBg       = Color(0xD9141A28); // Lane guidance pill
  static const Color navArrowBlue    = Color(0xFF1E88E5); // Turn maneuver blue
  static const Color navGoGreen      = Color(0xFF00C853); // Big Go! button
  static const Color navModeActive   = Color(0xFF00E676); // Active transport chip
  static const Color navBgLight      = Color(0xFFF6F8FA); // Light navigation background
  static const Color navTextDark     = Color(0xFF1B2430); // Primary dark text
  static const Color navTextMutedLight = Color(0xFF6B7280); // Secondary light mode text
  static const Color navBorderLight  = Color(0xFFE5E7EB); // Border light mode

  static List<BoxShadow> floatingPillShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingPillShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 20,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];
}
