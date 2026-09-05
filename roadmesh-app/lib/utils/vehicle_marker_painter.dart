// ─── Vehicle Vector Marker Painter ─────────────────────────────────────────
//
// Generates compact, authentic top-down vector markers for all vehicle types
// (Car, Auto Rickshaw, Two-Wheeler, Bus, Truck, Ambulance, Bicycle, Pedestrian).
// Sized proportionally so multiple vehicles can fit cleanly on real road lanes.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';

class VehicleMarkerPainter {
  VehicleMarkerPainter._();

  // In-memory cache for zero-latency 60fps rendering
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Pre-warms and caches all nominal and alert vehicle icons.
  static Future<void> prewarmCache() async {
    for (final type in VehicleType.values) {
      if (type == VehicleType.unknown) continue;
      for (final risk in RiskLevel.values) {
        await getMarker(type: type, riskLevel: risk, isEgo: false);
      }
      await getMarker(type: type, riskLevel: RiskLevel.green, isEgo: true);
    }
  }

  /// Retrieves or renders a custom vehicle marker descriptor.
  static Future<BitmapDescriptor> getMarker({
    required VehicleType type,
    RiskLevel riskLevel = RiskLevel.green,
    bool isEgo = false,
  }) async {
    final cacheKey = '${type.name}_${riskLevel.name}_ego$isEgo';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final descriptor = await _renderMarker(
      type: type,
      riskLevel: riskLevel,
      isEgo: isEgo,
    );

    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _renderMarker({
    required VehicleType type,
    required RiskLevel riskLevel,
    required bool isEgo,
  }) async {
    // Proportional, lane-accurate canvas size (44px for Ego, 36px for nearby)
    final double canvasSize = isEgo ? 44.0 : 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize, canvasSize));
    final center = Offset(canvasSize / 2, canvasSize / 2);

    final themeColor = _getVehicleThemeColor(type);
    final alertColor = _getAlertColor(riskLevel, themeColor);

    // 1. Subtle Cockpit Backdrop / Base Halo
    if (isEgo) {
      _drawEgoHalo(canvas, center, alertColor);
    } else {
      _drawNearbyHalo(canvas, center, alertColor, riskLevel);
    }

    // 2. Render Authentic Top-Down Vehicle Silhouette
    switch (type) {
      case VehicleType.autoRickshaw:
        _drawAutoRickshaw(canvas, center);
        break;
      case VehicleType.motorcycle:
        _drawMotorcycle(canvas, center);
        break;
      case VehicleType.car:
        _drawCar(canvas, center, isEgo ? AppColors.cyberBlue : themeColor);
        break;
      case VehicleType.bus:
        _drawBus(canvas, center);
        break;
      case VehicleType.truck:
        _drawTruck(canvas, center);
        break;
      case VehicleType.ambulance:
        _drawAmbulance(canvas, center);
        break;
      case VehicleType.bicycle:
        _drawBicycle(canvas, center);
        break;
      case VehicleType.pedestrian:
        _drawPedestrian(canvas, center);
        break;
      case VehicleType.unknown:
        _drawCar(canvas, center, themeColor);
        break;
    }

    // 3. Crisp Forward Heading Indicator
    _drawHeadingTip(canvas, center, isEgo ? AppColors.cyberBlue : alertColor, isEgo);

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // ─── Color Resolvers ────────────────────────────────────────────────────────

  static Color _getVehicleThemeColor(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return const Color(0xFF00E5FF); // Cyber Cyan
      case VehicleType.autoRickshaw:
        return const Color(0xFFFFD600); // Iconic Indian Auto Yellow
      case VehicleType.motorcycle:
        return const Color(0xFFFF6D00); // Electric Flame Orange
      case VehicleType.bus:
        return const Color(0xFF2979FF); // Transit Blue
      case VehicleType.truck:
        return const Color(0xFFFFAB00); // Industrial Amber
      case VehicleType.ambulance:
        return const Color(0xFFFF1744); // Emergency Red
      case VehicleType.bicycle:
        return const Color(0xFF76FF03); // Lime Green
      case VehicleType.pedestrian:
        return const Color(0xFFFF4081); // Neon Pink
      case VehicleType.unknown:
        return const Color(0xFF90CAF9);
    }
  }

  static Color _getAlertColor(RiskLevel risk, Color fallback) {
    switch (risk) {
      case RiskLevel.red:
        return AppColors.dangerRed;
      case RiskLevel.yellow:
        return AppColors.warningAmber;
      case RiskLevel.green:
        return fallback;
    }
  }

  // ─── Base Halos ─────────────────────────────────────────────────────────────

  static void _drawEgoHalo(Canvas canvas, Offset center, Color color) {
    // Subtle cockpit circular disc
    final discPaint = Paint()
      ..color = const Color(0xDD070E1B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 17, discPaint);

    // Fine neon cyan rim
    final ringPaint = Paint()
      ..color = AppColors.cyberBlue.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, 17, ringPaint);
  }

  static void _drawNearbyHalo(Canvas canvas, Offset center, Color color, RiskLevel risk) {
    final isAlert = risk != RiskLevel.green;

    // Cockpit disc
    final discPaint = Paint()
      ..color = const Color(0xDD090D18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, discPaint);

    // Fine colored ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: isAlert ? 1.0 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAlert ? 2.0 : 1.2;
    canvas.drawCircle(center, 14, ringPaint);
  }

  static void _drawHeadingTip(Canvas canvas, Offset center, Color color, bool isEgo) {
    final tipY = isEgo ? 3.0 : 2.5;
    final notchPath = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx + 3.2, tipY + 4.8)
      ..lineTo(center.dx - 3.2, tipY + 4.8)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(notchPath, paint);
  }

  // ─── 1. AUTO RICKSHAW (3-Wheeler) ──────────────────────────────────────────
  // Proportional Indian 3-wheeler: single front tire, yellow canopy, green rear.
  static void _drawAutoRickshaw(Canvas canvas, Offset c) {
    final tirePaint = Paint()..color = const Color(0xFF1E1E1E);

    // Front single wheel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy - 8.5), width: 2.2, height: 4.5),
        const Radius.circular(1),
      ),
      tirePaint,
    );

    // Rear dual wheels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx - 6.5, c.dy + 6.0), width: 2.4, height: 5.0),
        const Radius.circular(1),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + 6.5, c.dy + 6.0), width: 2.4, height: 5.0),
        const Radius.circular(1),
      ),
      tirePaint,
    );

    // Auto rickshaw body (pointed front, wide rear)
    final bodyPath = Path();
    bodyPath.moveTo(c.dx, c.dy - 8);
    bodyPath.lineTo(c.dx + 5.5, c.dy - 1);
    bodyPath.lineTo(c.dx + 6.0, c.dy + 7);
    bodyPath.lineTo(c.dx - 6.0, c.dy + 7);
    bodyPath.lineTo(c.dx - 5.5, c.dy - 1);
    bodyPath.close();

    // Dark green rear bottom cowl
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF00695C));

    // Golden Yellow Canopy
    final canopyPath = Path();
    canopyPath.moveTo(c.dx, c.dy - 6.5);
    canopyPath.lineTo(c.dx + 4.5, c.dy - 0.5);
    canopyPath.lineTo(c.dx + 5.0, c.dy + 5.0);
    canopyPath.lineTo(c.dx - 5.0, c.dy + 5.0);
    canopyPath.lineTo(c.dx - 4.5, c.dy - 0.5);
    canopyPath.close();

    canvas.drawPath(canopyPath, Paint()..color = const Color(0xFFFFD600));

    // Black windshield visor
    final windshield = Rect.fromCenter(center: Offset(c.dx, c.dy - 2), width: 7.0, height: 2.0);
    canvas.drawRect(windshield, Paint()..color = const Color(0xDD0D1117));
  }

  // ─── 2. TWO-WHEELER (Motorcycle / Scooter) ─────────────────────────────────
  // Slim agile profile: front tire, handlebar, fuel tank, rider helmet, rear tire.
  static void _drawMotorcycle(Canvas canvas, Offset c) {
    final tirePaint = Paint()..color = const Color(0xFF1E1E1E);

    // Front tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy - 8.0), width: 2.0, height: 5.0),
        const Radius.circular(1),
      ),
      tirePaint,
    );

    // Rear tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 8.0), width: 2.2, height: 5.0),
        const Radius.circular(1),
      ),
      tirePaint,
    );

    // Handlebar
    final barPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(c.dx - 4.5, c.dy - 4.5), Offset(c.dx + 4.5, c.dy - 4.5), barPaint);

    // Bike body (Neon Orange)
    final tankPath = Path();
    tankPath.moveTo(c.dx, c.dy - 6);
    tankPath.lineTo(c.dx + 2.5, c.dy - 1);
    tankPath.lineTo(c.dx + 1.8, c.dy + 3);
    tankPath.lineTo(c.dx - 1.8, c.dy + 3);
    tankPath.lineTo(c.dx - 2.5, c.dy - 1);
    tankPath.close();
    canvas.drawPath(tankPath, Paint()..color = const Color(0xFFFF6D00));

    // Rider helmet
    canvas.drawCircle(Offset(c.dx, c.dy), 2.8, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c.dx, c.dy), radius: 2.5),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF10172A),
    );
  }

  // ─── 3. CAR / TAXI ─────────────────────────────────────────────────────────
  // Sleek compact sedan: windshield, roof, side mirrors, headlights.
  static void _drawCar(Canvas canvas, Offset c, Color color) {
    // Car body chassis
    final bodyRect = Rect.fromCenter(center: c, width: 10.0, height: 18.0);
    final bodyPaint = Paint()..color = color;
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(2.5)), bodyPaint);

    // Dark tinted cabin
    final cabinRect = Rect.fromCenter(center: Offset(c.dx, c.dy), width: 7.5, height: 9.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabinRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF070F1E),
    );

    // Front windshield tint
    final glassRect = Rect.fromCenter(center: Offset(c.dx, c.dy - 2.5), width: 6.5, height: 2.5);
    canvas.drawRect(glassRect, Paint()..color = const Color(0x8800E5FF));

    // Dual headlights
    final lightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(c.dx - 3.2, c.dy - 8.5), 0.8, lightPaint);
    canvas.drawCircle(Offset(c.dx + 3.2, c.dy - 8.5), 0.8, lightPaint);
  }

  // ─── 4. BUS / PUBLIC TRANSIT ───────────────────────────────────────────────
  // Elongated transit bus with passenger window strips.
  static void _drawBus(Canvas canvas, Offset c) {
    final busRect = Rect.fromCenter(center: c, width: 11.5, height: 24.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect, const Radius.circular(2.5)),
      Paint()..color = const Color(0xFF2979FF),
    );

    // Front windshield
    final windshield = Rect.fromCenter(center: Offset(c.dx, c.dy - 8.5), width: 9.0, height: 3.0);
    canvas.drawRect(windshield, Paint()..color = const Color(0xCC051838));

    // Window slits
    final sidePaint = Paint()..color = const Color(0xCC051838);
    canvas.drawRect(Rect.fromLTWH(c.dx - 4.8, c.dy - 4.5, 1.2, 13), sidePaint);
    canvas.drawRect(Rect.fromLTWH(c.dx + 3.6, c.dy - 4.5, 1.2, 13), sidePaint);
  }

  // ─── 5. COMMERCIAL TRUCK ───────────────────────────────────────────────────
  // Cab + cargo bed with industrial amber styling.
  static void _drawTruck(Canvas canvas, Offset c) {
    // Front cab
    final cabRect = Rect.fromCenter(center: Offset(c.dx, c.dy - 7.5), width: 11.0, height: 6.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFFFAB00),
    );

    // Cargo container bed
    final cargoRect = Rect.fromCenter(center: Offset(c.dx, c.dy + 3.5), width: 12.0, height: 13.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cargoRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFFF8F00),
    );
  }

  // ─── 6. EMERGENCY AMBULANCE ────────────────────────────────────────────────
  // White vehicle with bold Red Cross (+) and roof strobes.
  static void _drawAmbulance(Canvas canvas, Offset c) {
    final ambRect = Rect.fromCenter(center: c, width: 11.0, height: 20.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ambRect, const Radius.circular(2.5)),
      Paint()..color = Colors.white,
    );

    // Red Cross on roof
    final crossPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy + 1), width: 5.5, height: 1.8), crossPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy + 1), width: 1.8, height: 5.5), crossPaint);

    // Roof emergency strobes (Blue & Red)
    canvas.drawCircle(Offset(c.dx - 3.0, c.dy - 8.0), 1.1, Paint()..color = const Color(0xFF2979FF));
    canvas.drawCircle(Offset(c.dx + 3.0, c.dy - 8.0), 1.1, crossPaint);
  }

  // ─── 7. BICYCLE / CYCLIST ──────────────────────────────────────────────────
  static void _drawBicycle(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = const Color(0xFF76FF03)
      ..strokeWidth = 1.4;

    canvas.drawCircle(Offset(c.dx, c.dy - 6.5), 2.0, paint);
    canvas.drawCircle(Offset(c.dx, c.dy + 6.5), 2.0, paint);
    canvas.drawLine(Offset(c.dx, c.dy - 4.5), Offset(c.dx, c.dy + 4.5), paint);
    canvas.drawCircle(Offset(c.dx, c.dy), 2.0, Paint()..color = Colors.white);
  }

  // ─── 8. PEDESTRIAN (VRU) ───────────────────────────────────────────────────
  static void _drawPedestrian(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      7.5,
      Paint()
        ..color = const Color(0xFFFF4081)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(c.dx, c.dy - 3), 1.6, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(c.dx, c.dy - 1.5),
      Offset(c.dx, c.dy + 3.5),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.3,
    );
  }
}
