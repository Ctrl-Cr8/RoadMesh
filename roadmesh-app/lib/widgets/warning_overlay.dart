// ─── Warning Overlay Widget ───────────────────────────────────────────────────
//
// Glassmorphic slide-up alert card with color-coded left stripe,
// alert type icon, TTC countdown bar, and smooth slide animation.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';

class WarningOverlay extends StatelessWidget {
  final List<CollisionAlert> alerts;

  const WarningOverlay({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final topAlert = alerts.first;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(const AlwaysStoppedAnimation(0)),
      child: _AlertCard(alert: topAlert, extraCount: alerts.length - 1),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final CollisionAlert alert;
  final int extraCount;

  const _AlertCard({required this.alert, required this.extraCount});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final color = _riskColor(alert.riskLevel);
    final icon = _alertIcon(alert.alertType);
    final ttcProgress = (alert.timeToCollision / 10.0).clamp(0.0, 1.0);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface.withValues(alpha: 0.85),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left risk stripe
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _alertLabel(alert.alertType),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${alert.distance}m away · ${_bearingLabel(alert.bearing)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // TTC badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${alert.timeToCollision.toStringAsFixed(1)}s',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // TTC countdown bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TIME TO COLLISION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      alert.riskLevel.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ttcProgress,
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),

                            // Extra alerts count
                            if (widget.extraCount > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '+${widget.extraCount} more alert${widget.extraCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.red:    return AppColors.dangerRed;
      case RiskLevel.yellow: return AppColors.warningAmber;
      case RiskLevel.green:  return AppColors.safeGreen;
    }
  }

  IconData _alertIcon(AlertType type) {
    switch (type) {
      case AlertType.headOn:          return Icons.warning_rounded;
      case AlertType.rearEnd:         return Icons.directions_car_filled;
      case AlertType.overtake:        return Icons.compare_arrows_rounded;
      case AlertType.blindCorner:     return Icons.turn_right_rounded;
      case AlertType.laneMerge:       return Icons.merge_rounded;
      case AlertType.wrongWay:        return Icons.do_not_disturb_on_rounded;
      case AlertType.stoppedVehicle:  return Icons.pause_circle_filled;
      case AlertType.emergencyVehicle:return Icons.local_hospital_rounded;
      case AlertType.vulnerableRoadUser:return Icons.directions_walk_rounded;
    }
  }

  String _alertLabel(AlertType type) {
    switch (type) {
      case AlertType.headOn:          return 'HEAD-ON COLLISION';
      case AlertType.rearEnd:         return 'REAR-END RISK';
      case AlertType.overtake:        return 'OVERTAKE HAZARD';
      case AlertType.blindCorner:     return 'BLIND CORNER';
      case AlertType.laneMerge:       return 'LANE MERGE';
      case AlertType.wrongWay:        return 'WRONG-WAY VEHICLE';
      case AlertType.stoppedVehicle:  return 'STOPPED VEHICLE';
      case AlertType.emergencyVehicle:return 'EMERGENCY VEHICLE';
      case AlertType.vulnerableRoadUser:return 'PEDESTRIAN CROSSING';
    }
  }

  String _bearingLabel(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }
}
