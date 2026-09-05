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

  /// Renders road-anchored speed camera callout badge matching Image 2
  static Future<BitmapDescriptor> getSpeedCameraMarker({
    int speedLimit = 100,
    String note = 'You often skip it • Stay alert!',
  }) async {
    const key = 'speed_camera_marker';
    if (_cache.containsKey(key)) return _cache[key]!;

    const double width = 160.0;
    const double height = 75.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. Red camera bubble pill at top
    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 4, 76, 32),
      const Radius.circular(16),
    );
    final bubblePaint = Paint()..color = const Color(0xFFD50000);
    canvas.drawRRect(bubbleRect, bubblePaint);

    // Camera Icon (white circle + dot)
    canvas.drawCircle(const Offset(58, 20), 7, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(58, 20), 4, Paint()..color = const Color(0xFFD50000));

    // Speed limit text inside red bubble
    final speedSpan = TextSpan(
      text: '$speedLimit',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        fontFamily: 'Inter',
      ),
    );
    final speedPainter = TextPainter(
      text: speedSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    speedPainter.paint(canvas, const Offset(72, 11));

    // Little triangular pointer pointing down
    final pointer = Path()
      ..moveTo(76, 36)
      ..lineTo(84, 36)
      ..lineTo(80, 42)
      ..close();
    canvas.drawPath(pointer, bubblePaint);

    // 2. Note text underneath: "You often skip it • Stay alert!"
    final noteSpan = TextSpan(
      text: note,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
    final notePainter = TextPainter(
      text: noteSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: width);
    final noteOffset = Offset((width - notePainter.width) / 2, 46);

    // Translucent dark pill backing for note
    final noteBgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(width / 2, 53),
        width: notePainter.width + 12,
        height: 18,
      ),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      noteBgRect,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    notePainter.paint(canvas, noteOffset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Renders circular red radar hazard ripples matching Image 1
  static Future<BitmapDescriptor> getHazardRippleMarker() async {
    const key = 'hazard_ripple_marker';
    if (_cache.containsKey(key)) return _cache[key]!;

    const double size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    const center = Offset(size / 2, size / 2);

    // Outer glow
    canvas.drawCircle(
      center,
      30,
      Paint()..color = const Color(0x33FF1744),
    );
    // Mid ripple ring
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0x88FF1744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Inner pulse ring
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = const Color(0xCCFF1744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Center core disc
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFFFF1744),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _renderMarker({
    required VehicleType type,
    required RiskLevel riskLevel,
    required bool isEgo,
  }) async {
    // Proportional, lane-accurate canvas size (88px for Ego 3D Car, 44px for nearby)
    final double canvasSize = isEgo ? 88.0 : 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize, canvasSize));
    final center = Offset(canvasSize / 2, canvasSize / 2);

    final themeColor = _getVehicleThemeColor(type);
    final alertColor = _getAlertColor(riskLevel, themeColor);

    if (isEgo) {
      if (type == VehicleType.car || type == VehicleType.unknown) {
        _draw3DMetallicSedan(canvas, center);
      } else {
        _drawEgoCleanVehicle(canvas, center, type);
      }
    } else {
      // Nearby mesh vehicles
      _drawNearbyVehicle(canvas, center, type, riskLevel, alertColor);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // ─── Color Resolvers ────────────────────────────────────────────────────────

  static Color _getVehicleThemeColor(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return const Color(0xFF2563EB); // Modern Automotive Blue
      case VehicleType.autoRickshaw:
        return const Color(0xFFFFD600); // Iconic Indian Auto Yellow
      case VehicleType.motorcycle:
        return const Color(0xFFFF6D00); // Flame Orange
      case VehicleType.bus:
        return const Color(0xFF2563EB); // Transit Blue
      case VehicleType.truck:
        return const Color(0xFFFF9800); // Industrial Amber
      case VehicleType.ambulance:
        return const Color(0xFFEF4444); // Emergency Red
      case VehicleType.bicycle:
        return const Color(0xFF10B981); // Emerald Green
      case VehicleType.pedestrian:
        return const Color(0xFFEC4899); // Magenta Pink
      case VehicleType.unknown:
        return const Color(0xFF2563EB);
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

  // ─── 3D Realistic Metallic Blue Car (Image 1) ──────────────────────────────

  /// Renders a photorealistic 3D metallic blue sedan directly on the map matching Image 1
  static void _draw3DMetallicSedan(Canvas canvas, Offset c) {
    // 1. Soft Realistic Ground Drop Shadow on Asphalt
    final shadowRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 3.0), width: 35.0, height: 68.0),
      const Radius.circular(15.0),
    );
    canvas.drawRRect(
      shadowRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // 2. Aerodynamic Side Wing Mirrors
    final mirrorPaint = Paint()..color = const Color(0xFF1D4ED8);
    // Left mirror
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx - 18.0, c.dy - 10.0), width: 4.5, height: 7.0),
        const Radius.circular(2.0),
      ),
      mirrorPaint,
    );
    // Right mirror
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + 18.0, c.dy - 10.0), width: 4.5, height: 7.0),
        const Radius.circular(2.0),
      ),
      mirrorPaint,
    );

    // 3. Main Streamlined Metallic Blue Car Body Shell
    final bodyPath = Path();
    // Front bumper / nose (rounded sleek curve)
    bodyPath.moveTo(c.dx - 11.0, c.dy - 30.0);
    bodyPath.quadraticBezierTo(c.dx, c.dy - 32.5, c.dx + 11.0, c.dy - 30.0);
    // Right front headlight & fender
    bodyPath.quadraticBezierTo(c.dx + 16.0, c.dy - 26.0, c.dx + 16.5, c.dy - 15.0);
    // Right door waistline (subtle sleek taper)
    bodyPath.quadraticBezierTo(c.dx + 15.5, c.dy, c.dx + 16.5, c.dy + 14.0);
    // Right muscular rear haunch
    bodyPath.quadraticBezierTo(c.dx + 17.5, c.dy + 25.0, c.dx + 14.5, c.dy + 30.5);
    // Rear bumper (wide, planted stance)
    bodyPath.quadraticBezierTo(c.dx, c.dy + 33.0, c.dx - 14.5, c.dy + 30.5);
    // Left rear haunch
    bodyPath.quadraticBezierTo(c.dx - 17.5, c.dy + 25.0, c.dx - 16.5, c.dy + 14.0);
    // Left door waistline
    bodyPath.quadraticBezierTo(c.dx - 15.5, c.dy, c.dx - 16.5, c.dy - 15.0);
    // Left front fender
    bodyPath.quadraticBezierTo(c.dx - 16.0, c.dy - 26.0, c.dx - 11.0, c.dy - 30.0);
    bodyPath.close();

    // Metallic Blue Shader (Matching the vibrant sports blue sedan in Image 1)
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx - 17.0, c.dy),
        Offset(c.dx + 17.0, c.dy),
        const [
          Color(0xFF1E3A8A), // deep sapphire edge shadow
          Color(0xFF2563EB), // rich metallic blue
          Color(0xFF3B82F6), // bright gloss highlight spine
          Color(0xFF1D4ED8), // royal blue right body
        ],
        const [0.0, 0.35, 0.72, 1.0],
      );
    canvas.drawPath(bodyPath, bodyPaint);

    // Subtle edge highlight on top surface
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 4. Front Hood Character Lines (Creases)
    final creasePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(c.dx - 6.0, c.dy - 28.0), Offset(c.dx - 8.0, c.dy - 15.0), creasePaint);
    canvas.drawLine(Offset(c.dx + 6.0, c.dy - 28.0), Offset(c.dx + 8.0, c.dy - 15.0), creasePaint);

    // 5. Front Windshield (Dark Tinted Curved Glass with Specular Reflection)
    final windshieldPath = Path()
      ..moveTo(c.dx - 11.5, c.dy - 12.0)
      ..quadraticBezierTo(c.dx, c.dy - 14.0, c.dx + 11.5, c.dy - 12.0)
      ..lineTo(c.dx + 13.0, c.dy - 1.0)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - 13.0, c.dy - 1.0)
      ..close();
    canvas.drawPath(windshieldPath, Paint()..color = const Color(0xFF1E293B));

    // Specular Reflection Streak (Daylight Glare from Reference Images)
    final glarePath = Path()
      ..moveTo(c.dx - 9.0, c.dy - 11.0)
      ..lineTo(c.dx - 2.0, c.dy - 12.5)
      ..lineTo(c.dx + 3.0, c.dy - 1.5)
      ..lineTo(c.dx - 4.0, c.dy - 1.5)
      ..close();
    canvas.drawPath(glarePath, Paint()..color = const Color(0x55BAE6FD));

    // 6. Panoramic Dark Sunroof Panel
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 7.5), width: 22.0, height: 13.0),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(roofRect, Paint()..color = const Color(0xFF0F172A));

    // Subtle roof glass gloss
    canvas.drawLine(
      Offset(c.dx - 7.0, c.dy + 3.0),
      Offset(c.dx + 7.0, c.dy + 3.0),
      Paint()..color = const Color(0x22FFFFFF)..strokeWidth = 1.0,
    );

    // 7. Rear Tinted Windshield
    final rearGlassPath = Path()
      ..moveTo(c.dx - 12.5, c.dy + 15.5)
      ..quadraticBezierTo(c.dx, c.dy + 15.0, c.dx + 12.5, c.dy + 15.5)
      ..lineTo(c.dx + 11.0, c.dy + 23.5)
      ..quadraticBezierTo(c.dx, c.dy + 24.5, c.dx - 11.0, c.dy + 23.5)
      ..close();
    canvas.drawPath(rearGlassPath, Paint()..color = const Color(0xFF1E293B));

    // 8. Rear Trunk Lid & Integrated Spoiler Lip
    canvas.drawLine(
      Offset(c.dx - 10.0, c.dy + 29.5),
      Offset(c.dx + 10.0, c.dy + 29.5),
      Paint()..color = const Color(0x44FFFFFF)..strokeWidth = 1.0,
    );

    // 9. Modern Rear LED Taillight Bar (Vibrant Red)
    final tailLightPath = Path()
      ..moveTo(c.dx - 13.5, c.dy + 30.5)
      ..quadraticBezierTo(c.dx, c.dy + 32.5, c.dx + 13.5, c.dy + 30.5)
      ..lineTo(c.dx + 12.5, c.dy + 32.0)
      ..quadraticBezierTo(c.dx, c.dy + 33.5, c.dx - 12.5, c.dy + 32.0)
      ..close();
    canvas.drawPath(tailLightPath, Paint()..color = const Color(0xFFEF4444));

    // 10. Front Xenon LED Headlights (Pure White with Subtle Halo)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx - 11.0, c.dy - 28.5), width: 5.0, height: 2.4),
        const Radius.circular(1.0),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + 11.0, c.dy - 28.5), width: 5.0, height: 2.4),
        const Radius.circular(1.0),
      ),
      Paint()..color = Colors.white,
    );
  }

  // ─── Ego Clean Vehicle (Motorcycle, Rickshaw, etc.) ────────────────────────

  static void _drawEgoCleanVehicle(Canvas canvas, Offset center, VehicleType type) {
    // Soft realistic ground shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 2.0),
      18.0,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    switch (type) {
      case VehicleType.autoRickshaw:
        _drawAutoRickshaw(canvas, center);
        break;
      case VehicleType.motorcycle:
        _drawMotorcycle(canvas, center);
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
      case VehicleType.car:
      case VehicleType.unknown:
        _draw3DMetallicSedan(canvas, center);
        break;
    }
  }

  // ─── Nearby Mesh Vehicles ──────────────────────────────────────────────────

  static void _drawNearbyVehicle(
    Canvas canvas,
    Offset center,
    VehicleType type,
    RiskLevel risk,
    Color alertColor,
  ) {
    final isAlert = risk != RiskLevel.green;

    // Contact shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 1.5),
      12.0,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // If collision alert is active, draw alert halo
    if (isAlert) {
      canvas.drawCircle(
        center,
        17.0,
        Paint()
          ..color = alertColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        17.0,
        Paint()
          ..color = alertColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    switch (type) {
      case VehicleType.autoRickshaw:
        _drawAutoRickshaw(canvas, center);
        break;
      case VehicleType.motorcycle:
        _drawMotorcycle(canvas, center);
        break;
      case VehicleType.car:
      case VehicleType.unknown:
        _drawCar(canvas, center, const Color(0xFF2563EB));
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
    }

    if (isAlert) {
      final tipPath = Path()
        ..moveTo(center.dx, center.dy - 20)
        ..lineTo(center.dx + 4, center.dy - 15)
        ..lineTo(center.dx - 4, center.dy - 15)
        ..close();
      canvas.drawPath(tipPath, Paint()..color = alertColor);
    }
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
    canvas.drawRect(glassRect, Paint()..color = const Color(0x8893C5FD));

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
