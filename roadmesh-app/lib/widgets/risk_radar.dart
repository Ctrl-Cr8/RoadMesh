// ─── Risk Radar Widget ────────────────────────────────────────────────────────
//
// Circular radar showing nearby vehicles as dots at their bearing angle
// and distance from center. Rotates with the driver's heading.
// Used as an overlay on the driving screen.

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';

class RiskRadar extends StatefulWidget {
  final List<Vehicle> nearbyVehicles;
  final List<CollisionAlert> alerts;
  final double heading;
  final double radiusMeters; // World radius represented by the widget

  const RiskRadar({
    super.key,
    required this.nearbyVehicles,
    required this.alerts,
    required this.heading,
    this.radiusMeters = 300,
  });

  @override
  State<RiskRadar> createState() => _RiskRadarState();
}

class _RiskRadarState extends State<RiskRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface.withValues(alpha: 0.85),
            border: Border.all(color: AppColors.cyberBlue.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyberBlue.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _sweepController,
            builder: (_, __) {
              return CustomPaint(
                painter: _RadarPainter(
                  vehicles: widget.nearbyVehicles,
                  alerts: widget.alerts,
                  heading: widget.heading,
                  sweepAngle: _sweepController.value * 2 * math.pi,
                  radiusMeters: widget.radiusMeters,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<Vehicle> vehicles;
  final List<CollisionAlert> alerts;
  final double heading;
  final double sweepAngle;
  final double radiusMeters;

  _RadarPainter({
    required this.vehicles,
    required this.alerts,
    required this.heading,
    required this.sweepAngle,
    required this.radiusMeters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw range rings (2 rings)
    for (double r = 0.33; r <= 1.0; r += 0.33) {
      ringPaint.color = AppColors.cyberBlue.withValues(alpha: 0.15);
      canvas.drawCircle(center, radius * r, ringPaint);
    }

    // Draw cross-hairs
    ringPaint.color = AppColors.cyberBlue.withValues(alpha: 0.1);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ringPaint,
    );

    // Sweep gradient arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          AppColors.cyberBlue.withValues(alpha: 0),
          AppColors.cyberBlue.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.8,
      0.8,
      true,
      sweepPaint,
    );

    // Draw ego vehicle (center dot)
    final egoPaint = Paint()
      ..color = AppColors.cyberBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, egoPaint);

    // Draw nearby vehicles as dots
    for (final vehicle in vehicles) {
      final alert = alerts.where((a) => a.vehicleId == vehicle.id).firstOrNull;
      final riskColor = _riskColor(alert?.riskLevel);

      // Convert bearing to canvas angle (0 = North = up = -π/2)
      final bearing = alert?.bearing.toDouble() ?? 0.0;
      final canvasAngle = (bearing - 90 + (heading * -1)) * math.pi / 180;

      // Scale distance to pixels
      final distPx = ((alert?.distance ?? radiusMeters) / radiusMeters).clamp(0.1, 0.9) * radius;

      final dotX = center.dx + math.cos(canvasAngle) * distPx;
      final dotY = center.dy + math.sin(canvasAngle) * distPx;

      // Glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        6,
        Paint()..color = riskColor.withValues(alpha: 0.2),
      );
      // Dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        3,
        Paint()..color = riskColor,
      );
    }

    // N indicator
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: AppColors.cyberBlue.withValues(alpha: 0.7),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius + 2),
    );
  }

  Color _riskColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.red:    return AppColors.dangerRed;
      case RiskLevel.yellow: return AppColors.warningAmber;
      default:               return AppColors.safeGreen;
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.sweepAngle != sweepAngle ||
      old.vehicles.length != vehicles.length ||
      old.alerts.length != alerts.length;
}
