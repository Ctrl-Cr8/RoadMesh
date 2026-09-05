// ─── Driving Status Bar Widget ───────────────────────────────────────────────
//
// Glassmorphic floating pill showing:
// - Connection status dot (pulsing green/red)
// - Current speed (large Orbitron number)
// - Heading compass
// - Nearby vehicle count badge

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';

class DrivingStatusBar extends StatefulWidget {
  final bool isConnected;
  final double speed;
  final double heading;
  final int nearbyCount;
  final RiskLevel riskLevel;
  final VehicleType? vehicleType;
  final VoidCallback? onCompassTap;
  final VoidCallback? onConnectionTap;

  const DrivingStatusBar({
    super.key,
    required this.isConnected,
    required this.speed,
    required this.heading,
    required this.nearbyCount,
    required this.riskLevel,
    this.vehicleType,
    this.onCompassTap,
    this.onConnectionTap,
  });

  @override
  State<DrivingStatusBar> createState() => _DrivingStatusBarState();
}

class _DrivingStatusBarState extends State<DrivingStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _dotAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.surface.withValues(alpha: 0.85),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                // ─── Connection dot & Status (Tappable to reconnect) ────────────
                GestureDetector(
                  onTap: widget.onConnectionTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _dotAnim,
                        builder: (_, __) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isConnected
                                ? AppColors.safeGreen.withValues(alpha: _dotAnim.value)
                                : AppColors.dangerRed.withValues(alpha: _dotAnim.value),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isConnected
                                        ? AppColors.safeGreen
                                        : AppColors.dangerRed)
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isConnected ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: widget.isConnected ? AppColors.safeGreen : AppColors.dangerRed,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                Container(width: 1, height: 18, color: AppColors.glassBorder),
                const SizedBox(width: 10),

                // ─── Speed ───────────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.speed.toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        'km/h',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                if (widget.vehicleType != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyberBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.cyberBlue.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.vehicleType!.icon, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          widget.vehicleType!.shortLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyberBlue,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(width: 12),

                // ─── Compass heading (Tappable to reset North) ──────────────────
                GestureDetector(
                  onTap: widget.onCompassTap,
                  child: _CompassBadge(heading: widget.heading),
                ),

                const SizedBox(width: 8),

                // ─── Nearby count badge ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.nearbyCount > 0
                        ? AppColors.cyberBlue.withValues(alpha: 0.15)
                        : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.nearbyCount > 0
                          ? AppColors.cyberBlue.withValues(alpha: 0.4)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 11,
                        color: widget.nearbyCount > 0
                            ? AppColors.cyberBlue
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.nearbyCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.nearbyCount > 0
                              ? AppColors.cyberBlue
                              : AppColors.textMuted,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Compass Badge ────────────────────────────────────────────────────────────

class _CompassBadge extends StatelessWidget {
  final double heading;

  const _CompassBadge({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.glassWhite,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass needle
          Transform.rotate(
            angle: heading * (3.14159 / 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Container(
                  width: 2,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Center dot
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
