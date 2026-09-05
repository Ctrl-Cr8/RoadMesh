// ─── Driving Screen (V2X Navigation Cockpit) ──────────────────────────────────
//
// Full-featured Google Maps automotive navigation cockpit:
// - Turn-by-turn routing with glowing polylines and next maneuver HUD
// - V2X Radar Detection Range configurable from 0m (OFF) to 300m
// - Multi-layer map views (Friendly Road, Terrain, Satellite, Dark Tactical)
// - Live Google Traffic layer toggle and 2D/3D perspective camera controls
// - Real-time speed limit badge and overspeed alerts
// - Instant camera re-center and compass North orientation

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/driving_provider.dart';
import '../models/alert.dart';
import '../models/vehicle.dart';
import '../navigation/navigation_route.dart';
import '../navigation/route_service.dart';
import '../widgets/warning_overlay.dart';
import '../widgets/radar_range_dialog.dart';
import '../widgets/map_layer_sheet.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/maneuver_top_hud.dart';
import '../widgets/speedometer_top_hud.dart';
import '../widgets/geoposition_share_banner.dart';
import '../widgets/lane_guidance_overlay.dart';
import '../widgets/floating_map_dock.dart';
import '../widgets/nav_floating_pill_bar.dart';
import '../theme/app_colors.dart';
import '../utils/vehicle_marker_painter.dart';
import 'home_screen.dart';

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _riskPulseController;

  // Cached vector descriptors
  final Map<String, BitmapDescriptor> _markerCache = {};

  // Camera follow state & programmatic animation lock guard
  bool _isCameraFollowLocked = true;
  bool _isProgrammaticCameraMove = false;

  // Off-route tracking & auto-rerouting guards
  int _offRouteTicks = 0;
  DateTime _lastRerouteTime = DateTime.fromMillisecondsSinceEpoch(0);
  String _currentLocationDisplayName = 'Your Current Location';
  LatLng? _lastGeocodedPos;

  // Map layer controls
  MapType _currentMapType = MapType.normal;
  bool _isDarkStyleActive = false; // Default to crisp light navigation theme as in Image 1
  bool _isTrafficEnabled = false;
  bool _is3DMode = true;
  bool _showGeopositionBanner = true;
  bool _isMapReady = false;

  // V2X Radar Detection Range in Meters (0 = OFF, up to 300m)
  int _radarRangeMeters = 300;

  // Active turn-by-turn navigation state
  ActiveNavigationRoute? _activeRoute;
  int _currentStepIndex = 0;
  bool _isCalculatingRoute = false;

  // Dropped Pin destination from map tap/long-press
  NavDestination? _droppedPinDestination;

  // Road speed limit in km/h (automatically detected from road classification)
  double _speedLimitKmh = 40.0;
  bool _showSpeedLimitSign = true;
  bool _isAutoSpeedLimit = true;
  String _currentSpeedZoneName = 'Local Road';

  // Google Maps Clean Daytime Light style JSON (Apple / Yandex / 2GIS aesthetic)
  static const String _lightMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#edf1f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "on"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#334155"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#ffffff"}, {"weight": 3}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#e2e8f0"}]},
    {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#cce8cf"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#cbd5e1"}, {"weight": 1.5}]},
    {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road.arterial", "elementType": "geometry.stroke", "stylers": [{"color": "#94a3b8"}, {"weight": 2.0}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#fed7aa"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#f97316"}, {"weight": 2.5}]},
    {"featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#cbd5e1"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#93c5fd"}]}
  ]
  ''';

  // Google Maps Dark/Night style JSON
  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
    {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
    {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
    {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
    {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
    {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
  ]
  ''';

  static const LatLng _defaultCenter = LatLng(10.0538, 76.6193);

  @override
  void initState() {
    super.initState();
    _speedLimitKmh = 40.0;
    _currentSpeedZoneName = 'Local Road';

    _riskPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _warmUpAllVehicleMarkers();
  }

  @override
  void dispose() {
    _riskPulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Safely animates camera programmatically without accidentally triggering manual drag unlock.
  Future<void> _animateCameraProgrammatically(CameraUpdate update, {bool keepFollowLocked = true}) async {
    if (_mapController == null) return;
    if (keepFollowLocked) {
      _isProgrammaticCameraMove = true;
      if (!_isCameraFollowLocked) {
        setState(() {
          _isCameraFollowLocked = true;
        });
      }
    }
    await _mapController!.animateCamera(update);
  }

  /// Finds the closest projected point and segment heading on a polyline to given coordinate.
  (LatLng, double, double) _findNearestRouteProjection(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return (point, 0.0, 0.0);
    if (polyline.length == 1) {
      final d = RouteService.distanceBetween(point, polyline[0]);
      return (polyline[0], 0.0, d);
    }

    double minDistance = double.infinity;
    LatLng closestProjection = polyline[0];
    double closestHeading = 0.0;

    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];

      final dLat = p2.latitude - p1.latitude;
      final dLng = p2.longitude - p1.longitude;
      final segLengthSq = (dLat * dLat) + (dLng * dLng);

      LatLng proj;
      if (segLengthSq < 1e-12) {
        proj = p1;
      } else {
        final t = (((point.latitude - p1.latitude) * dLat) +
                ((point.longitude - p1.longitude) * dLng)) /
            segLengthSq;
        final clampedT = t.clamp(0.0, 1.0);
        proj = LatLng(
          p1.latitude + (clampedT * dLat),
          p1.longitude + (clampedT * dLng),
        );
      }

      final dist = RouteService.distanceBetween(point, proj);
      if (dist < minDistance) {
        minDistance = dist;
        closestProjection = proj;
        closestHeading = (math.atan2(dLng, dLat) * 180 / math.pi) % 360;
      }
    }

    return (closestProjection, closestHeading, minDistance);
  }

  /// Resolves the car's real physical GPS position, heading, and driving speed.
  (LatLng, double, double) _resolveCarTelemetry(DrivingProvider provider) {
    if (provider.currentPosition == null) {
      return (
        _defaultCenter,
        provider.currentHeading > 0 ? provider.currentHeading : 0.0,
        0.0,
      );
    }

    final realGps = LatLng(
      provider.currentPosition!.latitude,
      provider.currentPosition!.longitude,
    );
    final speed = provider.currentSpeed;
    double heading = provider.currentHeading;

    // Periodically reverse-geocode to update origin address name
    _maybeUpdateLocationName(realGps);

    if (_activeRoute != null && _activeRoute!.polylinePoints.isNotEmpty) {
      final (nearestPoint, segmentHeading, distMeters) =
          _findNearestRouteProjection(realGps, _activeRoute!.polylinePoints);

      // Clean road-snapping if driver is within 25m of route line
      if (distMeters <= 25.0) {
        _offRouteTicks = 0;
        if (heading <= 0) {
          heading = segmentHeading;
        }
        return (nearestPoint, heading, speed);
      }

      // If driver is more than 45m away from the route, trigger automatic rerouting
      if (distMeters > 45.0) {
        _checkOffRouteAndReroute(realGps);
      }

      return (realGps, heading, speed);
    }

    return (realGps, heading, speed);
  }

  void _checkOffRouteAndReroute(LatLng realGps) {
    _offRouteTicks++;
    if (_offRouteTicks >= 3 && !_isCalculatingRoute) {
      final now = DateTime.now();
      if (now.difference(_lastRerouteTime).inSeconds > 6) {
        _lastRerouteTime = now;
        _offRouteTicks = 0;
        _triggerReroute(realGps);
      }
    }
  }

  Future<void> _triggerReroute(LatLng realGps) async {
    if (_activeRoute == null || _isCalculatingRoute) return;
    final dest = _activeRoute!.destination;

    setState(() {
      _isCalculatingRoute = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Off route • Recalculating route to ${dest.title}...',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    try {
      final newRoute = await RouteService.calculateRoute(
        origin: realGps,
        destination: dest,
      );

      if (!mounted) return;

      final activeRoadName = newRoute.steps.isNotEmpty ? newRoute.steps[0].streetName : dest.title;

      setState(() {
        _activeRoute = newRoute;
        _currentStepIndex = 0;
        _isCalculatingRoute = false;
        _currentSpeedZoneName = activeRoadName;
        if (_isAutoSpeedLimit) {
          _speedLimitKmh = RouteService.getDesignatedSpeedLimit(activeRoadName);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _maybeUpdateLocationName(LatLng pos) {
    if (_lastGeocodedPos != null &&
        RouteService.distanceBetween(_lastGeocodedPos!, pos) < 150.0) {
      return;
    }
    _lastGeocodedPos = pos;
    RouteService.reverseGeocode(pos).then((dest) {
      if (mounted && dest.title.isNotEmpty && dest.title != 'Selected Location' && dest.title != 'Dropped Pin') {
        setState(() {
          _currentLocationDisplayName = dest.title;
        });
      }
    }).catchError((_) {});
  }

  Future<void> _handleShareLocation(DrivingProvider provider) async {
    LatLng? pos = provider.currentPosition != null
        ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
        : null;

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquiring GPS fix for sharing...'),
          duration: Duration(seconds: 2),
        ),
      );
      try {
        final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        pos = LatLng(fix.latitude, fix.longitude);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not acquire GPS position to share.')),
          );
        }
        return;
      }
    }

    final mapLink = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    final shareText = '📍 My live location on RoadMesh Navigation:\n$mapLink';
    // ignore: deprecated_member_use
    Share.share(shareText, subject: 'Live RoadMesh Geoposition');
  }

  /// Pre-warms custom vector markers for all vehicle categories.
  Future<void> _warmUpAllVehicleMarkers() async {
    for (final type in VehicleType.values) {
      if (type == VehicleType.unknown) continue;

      for (final risk in RiskLevel.values) {
        final key = '${type.name}_${risk.name}_egoFalse';
        _markerCache[key] = await VehicleMarkerPainter.getMarker(
          type: type,
          riskLevel: risk,
          isEgo: false,
        );
      }

      final egoKey = '${type.name}_green_egoTrue';
      _markerCache[egoKey] = await VehicleMarkerPainter.getMarker(
        type: type,
        riskLevel: RiskLevel.green,
        isEgo: true,
      );
    }

    // Warm up Speed Camera & Hazard Ripple markers
    _markerCache['speed_camera'] = await VehicleMarkerPainter.getSpeedCameraMarker(
      speedLimit: _speedLimitKmh.toInt(),
      note: 'You often skip it • Stay alert!',
    );
    _markerCache['hazard_ripple'] = await VehicleMarkerPainter.getHazardRippleMarker();

    if (mounted) {
      setState(() {});
    }
  }

  /// Calculates geodesic distance between two coordinates in meters.
  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  /// Builds custom vector markers for driver, peers, destination flag, and speed cameras.
  Set<Marker> _buildMarkers(DrivingProvider provider) {
    final markers = <Marker>{};

    final (carPos, carHeading, carSpeed) = _resolveCarTelemetry(provider);

    // 1. Ego (Driver) Custom Vehicle Marker (ALWAYS guaranteed to be present)
    final egoKey = '${provider.vehicleType.name}_green_egoTrue';
    final egoIcon = _markerCache[egoKey] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);

    markers.add(
      Marker(
        markerId: const MarkerId('ego'),
        position: carPos,
        icon: egoIcon,
        rotation: carHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 999, // ALWAYS on top of route polylines and nearby vehicles!
        infoWindow: InfoWindow(
          title: '${provider.vehicleType.icon} Your ${provider.vehicleType.displayName}',
          snippet:
              '${carSpeed.toStringAsFixed(0)} km/h • Heading: ${carHeading.toStringAsFixed(0)}° • V2X Active',
        ),
      ),
    );

    // 2. Real Nearby Peers (Filtered by V2X Radar Range: 0 to 300m)
    if (_radarRangeMeters > 0) {
      for (final vehicle in provider.nearbyVehicles) {
        final dist = _distanceBetween(carPos.latitude, carPos.longitude, vehicle.lat, vehicle.lng);
        if (dist > _radarRangeMeters) continue;

        final alert = provider.activeAlerts
            .where((a) => a.vehicleId == vehicle.id)
            .firstOrNull;

        final risk = alert?.riskLevel ?? RiskLevel.green;
        final key = '${vehicle.vehicleType.name}_${risk.name}_egoFalse';

        final icon = _markerCache[key] ??
            BitmapDescriptor.defaultMarkerWithHue(
              risk == RiskLevel.red
                  ? BitmapDescriptor.hueRed
                  : (risk == RiskLevel.yellow
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueGreen),
            );

        markers.add(
          Marker(
            markerId: MarkerId(vehicle.id),
            position: LatLng(vehicle.lat, vehicle.lng),
            icon: icon,
            rotation: vehicle.heading,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: risk == RiskLevel.red ? 90 : (risk == RiskLevel.yellow ? 80 : 50),
            infoWindow: InfoWindow(
              title: '${vehicle.vehicleType.icon} ${vehicle.vehicleType.displayName}',
              snippet:
                  'Speed: ${vehicle.speed.toStringAsFixed(0)} km/h • Bearing: ${vehicle.heading.toStringAsFixed(0)}°',
              onTap: () => _showVehicleDetailSheet(vehicle, alert),
            ),
          ),
        );
      }
    }

    // 3. Destination Pin (Active Route or Dropped Pin)
    if (_activeRoute != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('nav_destination'),
          position: _activeRoute!.destination.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: _activeRoute!.destination.title,
            snippet: 'Destination • ${_activeRoute!.formattedDistance}',
          ),
        ),
      );
    } else if (_droppedPinDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropped_pin_destination'),
          position: _droppedPinDestination!.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: _droppedPinDestination!.title,
            snippet: _droppedPinDestination!.subtitle,
          ),
        ),
      );
    }

    // 4. On-Road Speed Camera Alert Marker (Image 2)
    if (_activeRoute != null && _activeRoute!.polylinePoints.isNotEmpty) {
      final cameraIdx = math.min(10, _activeRoute!.polylinePoints.length - 1);
      final cameraPos = _activeRoute!.polylinePoints[cameraIdx];
      final cameraIcon = _markerCache['speed_camera'];
      if (cameraIcon != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('nav_speed_camera'),
            position: cameraPos,
            icon: cameraIcon,
            anchor: const Offset(0.5, 0.85),
            zIndexInt: 95,
          ),
        );
      }
    }

    // 5. Radar Hazard Ripple (Image 1)
    if (provider.activeAlerts.isNotEmpty && _markerCache['hazard_ripple'] != null) {
      final alertVehicle = provider.nearbyVehicles
          .where((v) => v.id == provider.activeAlerts.first.vehicleId)
          .firstOrNull;
      if (alertVehicle != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('hazard_ripple'),
            position: LatLng(alertVehicle.lat, alertVehicle.lng),
            icon: _markerCache['hazard_ripple']!,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 60,
          ),
        );
      }
    }

    return markers;
  }

  /// Builds navigation route polylines with forward green tracking anchored directly to the vehicle.
  Set<Polyline> _buildPolylines(LatLng carPos) {
    if (_activeRoute == null || _activeRoute!.polylinePoints.isEmpty) {
      return const <Polyline>{};
    }

    final fullPoints = _activeRoute!.polylinePoints;
    final polylines = <Polyline>{};

    // Find the closest point index on the route to the car's current position
    int closestIdx = 0;
    double minD = double.infinity;
    for (int i = 0; i < fullPoints.length; i++) {
      final d = RouteService.distanceBetween(carPos, fullPoints[i]);
      if (d < minD) {
        minD = d;
        closestIdx = i;
      }
    }

    // Remaining forward route points: begins AT the car and tracks forward
    final remainingPoints = <LatLng>[carPos];
    for (int i = closestIdx + 1; i < fullPoints.length; i++) {
      remainingPoints.add(fullPoints[i]);
    }
    if (remainingPoints.length < 2) {
      remainingPoints.add(_activeRoute!.destination.location);
    }

    // 1. Glow underlay polyline (vibrant navigation green - tracks dynamically with car)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('nav_route_glow'),
        points: remainingPoints,
        color: AppColors.navRouteGreen.withValues(alpha: 0.35),
        width: 14,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    // 2. Primary core green route line (moving along with car)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('nav_route_core'),
        points: remainingPoints,
        color: AppColors.navRouteGreen,
        width: 7,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    // 3. Traveled portion behind the car (subtle dimmed gray)
    if (closestIdx > 0) {
      final passedPoints = fullPoints.sublist(0, closestIdx + 1);
      passedPoints.add(carPos);
      polylines.add(
        Polyline(
          polylineId: const PolylineId('nav_route_passed'),
          points: passedPoints,
          color: Colors.grey.withValues(alpha: 0.35),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    return polylines;
  }

  /// Clean map view: zero hardcoded circles!
  Set<Circle> _buildCircles(DrivingProvider provider) => const <Circle>{};

  /// Smoothly follows the driver in 2D/3D perspective (zoom 19.3 when navigating, 17.5 in free drive).
  void _followDriver(DrivingProvider provider, LatLng carPos, double carHeading) {
    if (!_isCameraFollowLocked || _mapController == null) return;

    final targetZoom = _activeRoute != null ? 19.3 : 17.5;

    _animateCameraProgrammatically(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: carPos,
          zoom: targetZoom,
          bearing: carHeading,
          tilt: _is3DMode ? 38.0 : 0.0,
        ),
      ),
      keepFollowLocked: true,
    );
  }

  /// Re-centers the camera smoothly onto the driver and locks tracking.
  void _recenterOnDriver(DrivingProvider provider) {
    final (carPos, carHeading, _) = _resolveCarTelemetry(provider);
    final targetZoom = _activeRoute != null ? 19.3 : 17.5;

    _animateCameraProgrammatically(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: carPos,
          zoom: targetZoom,
          bearing: carHeading,
          tilt: _is3DMode ? 38.0 : 0.0,
        ),
      ),
      keepFollowLocked: true,
    );
  }

  /// Resets map orientation directly to True North (0°).
  void _resetCompassNorth(DrivingProvider provider) {
    final (carPos, _, _) = _resolveCarTelemetry(provider);

    _animateCameraProgrammatically(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: carPos,
          zoom: 17.5,
          bearing: 0.0,
          tilt: 0.0,
        ),
      ),
      keepFollowLocked: false,
    );
  }

  void _zoomIn() {
    _animateCameraProgrammatically(CameraUpdate.zoomIn(), keepFollowLocked: false);
  }

  void _zoomOut() {
    _animateCameraProgrammatically(CameraUpdate.zoomOut(), keepFollowLocked: false);
  }

  void _toggleDayNightTheme() {
    setState(() {
      _isDarkStyleActive = !_isDarkStyleActive;
    });
    if (_mapController != null && _currentMapType == MapType.normal) {
      try {
        // ignore: deprecated_member_use
        _mapController!.setMapStyle(_isDarkStyleActive ? _darkMapStyle : _lightMapStyle);
      } catch (_) {}
    }
  }

  void _toggle3DMode(DrivingProvider provider) {
    setState(() {
      _is3DMode = !_is3DMode;
    });
    _recenterOnDriver(provider);
  }

  void _reportHazard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDarkStyleActive ? const Color(0xFF131C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'REPORT ROAD HAZARD',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _isDarkStyleActive ? Colors.white : AppColors.navTextDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _hazardOption(Icons.camera_alt_rounded, 'Speed Camera', Colors.red),
                _hazardOption(Icons.warning_amber_rounded, 'Road Hazard', Colors.orange),
                _hazardOption(Icons.traffic_rounded, 'Traffic Jam', Colors.amber),
                _hazardOption(Icons.car_crash_rounded, 'Accident', Colors.redAccent),
                _hazardOption(Icons.local_police_rounded, 'Police / Radar', Colors.blue),
                _hazardOption(Icons.construction_rounded, 'Road Works', Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _hazardOption(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 18),
                const SizedBox(width: 8),
                Text('Hazard reported to V2X Mesh: $label'),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _isDarkStyleActive ? Colors.white : AppColors.navTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStepByStepSheet() {
    if (_activeRoute == null || _activeRoute!.steps.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDarkStyleActive ? const Color(0xFF131C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TURN-BY-TURN DIRECTIONS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _isDarkStyleActive ? Colors.white : AppColors.navTextDark,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _activeRoute!.steps.length,
                separatorBuilder: (_, __) => Divider(
                  color: _isDarkStyleActive ? Colors.white12 : AppColors.navBorderLight,
                ),
                itemBuilder: (context, idx) {
                  final s = _activeRoute!.steps[idx];
                  return ListTile(
                    leading: Icon(s.maneuver.icon, color: AppColors.navArrowBlue),
                    title: Text(
                      s.instruction,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isDarkStyleActive ? Colors.white : AppColors.navTextDark,
                      ),
                    ),
                    subtitle: Text(
                      '${s.distanceMeters.round()} m • ${s.streetName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDarkStyleActive ? AppColors.textMuted : AppColors.navTextMutedLight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the V2X Radar Range configuration dialog (0m to 300m).
  void _openRadarRangeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => RadarRangeDialog(
        currentRange: _radarRangeMeters,
        onRangeChanged: (newRange) {
          setState(() {
            _radarRangeMeters = newRange;
          });
        },
      ),
    );
  }

  /// Opens the map display layer settings sheet.
  void _showMapLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapLayerSheet(
        currentMapType: _currentMapType,
        isDarkStyleActive: _isDarkStyleActive,
        isTrafficEnabled: _isTrafficEnabled,
        is3DMode: _is3DMode,
        onStyleChanged: (type, isDark) {
          setState(() {
            _currentMapType = type;
            _isDarkStyleActive = isDark;
          });
          if (isDark && type == MapType.normal) {
            // ignore: deprecated_member_use
            _mapController?.setMapStyle(_darkMapStyle);
          } else {
            // ignore: deprecated_member_use
            _mapController?.setMapStyle(null);
          }
          Navigator.pop(ctx);
        },
        onTrafficToggled: (enabled) {
          setState(() {
            _isTrafficEnabled = enabled;
          });
          Navigator.pop(ctx);
        },
        on3DModeToggled: (enabled) {
          setState(() {
            _is3DMode = enabled;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  /// Opens destination search sheet to start turn-by-turn routing anywhere.
  void _showDestinationPicker(DrivingProvider provider) {
    final origin = provider.currentPosition != null
        ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DestinationPickerSheet(
        userLocation: origin,
        onDestinationSelected: (dest) {
          _startNavigationTo(dest, provider);
        },
      ),
    );
  }

  /// Starts turn-by-turn navigation to any destination from the user's real GPS position.
  Future<void> _startNavigationTo(NavDestination dest, DrivingProvider provider) async {
    LatLng? origin;
    if (provider.currentPosition != null) {
      origin = LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude);
    } else {
      try {
        final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        origin = LatLng(fix.latitude, fix.longitude);
      } catch (_) {
        origin = _defaultCenter;
      }
    }

    setState(() {
      _isCalculatingRoute = true;
      _droppedPinDestination = null;
    });

    try {
      final route = await RouteService.calculateRoute(
        origin: origin,
        destination: dest,
      );

      if (!mounted) return;

      final activeRoadName = (route.steps.isNotEmpty ? route.steps[0].streetName : dest.title);
      final designatedLimit = RouteService.getDesignatedSpeedLimit(activeRoadName);

      setState(() {
        _activeRoute = route;
        _currentStepIndex = 0;
        _isCameraFollowLocked = true;
        _isCalculatingRoute = false;
        _currentSpeedZoneName = activeRoadName;
        if (_isAutoSpeedLimit) {
          _speedLimitKmh = designatedLimit;
        }
      });

      // Camera focuses directly on vehicle's current position and heading
      double navBearing = provider.currentHeading;
      if (navBearing <= 0 && route.polylinePoints.length >= 2) {
        final p1 = route.polylinePoints[0];
        final p2 = route.polylinePoints[1];
        final dLat = p2.latitude - p1.latitude;
        final dLng = p2.longitude - p1.longitude;
        navBearing = (math.atan2(dLng, dLat) * 180 / math.pi) % 360;
      }

      _animateCameraProgrammatically(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: origin,
            zoom: 19.3,
            bearing: navBearing,
            tilt: _is3DMode ? 38.0 : 0.0,
          ),
        ),
        keepFollowLocked: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCalculatingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  /// Handles user tapping or long-pressing anywhere on the map to drop a pin.
  /// Automatically snaps to landmarks / POIs and centers the camera on the location.
  void _handleMapTap(LatLng position, DrivingProvider provider) async {
    if (_isCalculatingRoute) return;

    setState(() {
      _droppedPinDestination = NavDestination(
        id: 'tap_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Locating Landmark...',
        subtitle: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        location: position,
        icon: Icons.pin_drop_rounded,
      );
      _isCameraFollowLocked = false;
    });

    final geocoded = await RouteService.reverseGeocode(position);
    if (mounted && _droppedPinDestination != null) {
      setState(() {
        _droppedPinDestination = geocoded;
      });

      // Smoothly center the map directly on the landmark icon
      _animateCameraProgrammatically(
        CameraUpdate.newLatLng(geocoded.location),
        keepFollowLocked: false,
      );
    }
  }

  /// Manually retry connecting to the V2X server when OFFLINE badge is tapped.
  void _handleConnectionTap(DrivingProvider provider) async {
    if (!provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyberBlue),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reconnecting to RoadMesh V2X Network...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      await provider.retryConnection();
    }
  }

  /// Dialog to view automatic road speed limit zone and toggle manual overrides.
  void _showSpeedLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 10),
              Text(
                'ROAD SPEED LIMIT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Auto Zone Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAutoSpeedLimit ? const Color(0xFF10B981) : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAutoSpeedLimit ? 'AUTO-DETECTED ROAD ZONE' : 'MANUAL OVERRIDE ACTIVE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _isAutoSpeedLimit ? const Color(0xFF10B981) : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentSpeedZoneName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Designated Limit: ${_speedLimitKmh.toInt()} km/h',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Road speed limits are automatically determined from road classification (College/School: 30 km/h, Residential: 40 km/h, Urban: 50 km/h, Highway: 70-80 km/h).',
                style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Auto-Detect Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto-Detect From Road',
                    style: TextStyle(fontFamily: 'Inter', color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Switch(
                    value: _isAutoSpeedLimit,
                    activeTrackColor: const Color(0xFF2563EB),
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        _isAutoSpeedLimit = val;
                        if (val) {
                          _speedLimitKmh = RouteService.getDesignatedSpeedLimit(_currentSpeedZoneName);
                        }
                      });
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'MANUAL OVERRIDE:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 40, 50, 60, 80, 100].map((speed) {
                  final isSelected = _speedLimitKmh == speed.toDouble() && !_isAutoSpeedLimit;
                  return ChoiceChip(
                    label: Text('$speed km/h'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _speedLimitKmh = speed.toDouble();
                        _isAutoSpeedLimit = false;
                        _showSpeedLimitSign = true;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Show Badge on Cockpit', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                  Switch(
                    value: _showSpeedLimitSign,
                    activeTrackColor: const Color(0xFF2563EB),
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        _showSpeedLimitSign = val;
                      });
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF2563EB), fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelNavigation() {
    setState(() {
      _activeRoute = null;
      _currentStepIndex = 0;
      _droppedPinDestination = null;
      _isCameraFollowLocked = true;
    });

    final provider = context.read<DrivingProvider>();
    final (carPos, carHeading, _) = _resolveCarTelemetry(provider);
    _animateCameraProgrammatically(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: carPos,
          zoom: 17.5,
          bearing: carHeading,
          tilt: _is3DMode ? 35.0 : 0.0,
        ),
      ),
      keepFollowLocked: true,
    );
  }

  void _showVehicleDetailSheet(Vehicle vehicle, CollisionAlert? alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(vehicle.vehicleType.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleType.displayName.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'NODE: ${vehicle.id.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _telemetryTile('SPEED', '${vehicle.speed.toStringAsFixed(0)} km/h'),
                  _telemetryTile('HEADING', '${vehicle.heading.toStringAsFixed(0)}°'),
                  _telemetryTile(
                    'STATUS',
                    alert != null ? '${alert.timeToCollision.toStringAsFixed(1)}s TTC' : 'CONNECTED',
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _telemetryTile(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Future<void> _stopDriving() async {
    final provider = context.read<DrivingProvider>();
    await provider.stopDriving();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrivingProvider>(
      builder: (context, provider, _) {
        if (provider.currentRiskLevel == RiskLevel.red) {
          _riskPulseController.repeat(reverse: true);
        } else {
          _riskPulseController.stop();
          _riskPulseController.reset();
        }

        final (carPos, carHeading, carSpeed) = _resolveCarTelemetry(provider);

        if (_isCameraFollowLocked && _isMapReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _followDriver(provider, carPos, carHeading);
          });
        }

        final centerLat = carPos.latitude;
        final centerLng = carPos.longitude;

        // Automatic turn-by-turn maneuver progress tracking
        NavigationStep? currentStep;
        double distanceToNextTurn = 0.0;
        if (_activeRoute != null && _activeRoute!.steps.isNotEmpty) {
          final curIdx = _currentStepIndex.clamp(0, _activeRoute!.steps.length - 1);
          currentStep = _activeRoute!.steps[curIdx];

          distanceToNextTurn = RouteService.distanceBetween(
            carPos,
            currentStep.location,
          );

          if (distanceToNextTurn < 25.0 && _currentStepIndex < _activeRoute!.steps.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _activeRoute != null) {
                final nextIdx = _currentStepIndex + 1;
                final nextRoad = nextIdx < _activeRoute!.steps.length
                    ? _activeRoute!.steps[nextIdx].streetName
                    : '';
                setState(() {
                  _currentStepIndex = nextIdx;
                  if (_isAutoSpeedLimit && nextRoad.isNotEmpty) {
                    _currentSpeedZoneName = nextRoad;
                    _speedLimitKmh = RouteService.getDesignatedSpeedLimit(nextRoad);
                  }
                });
              }
            });
          }
        }

        return Scaffold(
          backgroundColor: _isDarkStyleActive ? AppColors.deepSpace : AppColors.navBgLight,
          body: Stack(
            children: [
              // ─── 1. Google Map with Active Layers & Polylines ─────
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 17.5,
                  tilt: _is3DMode ? 35.0 : 0.0,
                ),
                mapType: _currentMapType,
                trafficEnabled: _isTrafficEnabled,
                buildingsEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (mounted && !_isMapReady) {
                    setState(() {
                      _isMapReady = true;
                    });
                  }
                  if (_currentMapType == MapType.normal) {
                    try {
                      // ignore: deprecated_member_use
                      controller.setMapStyle(_isDarkStyleActive ? _darkMapStyle : _lightMapStyle);
                    } catch (_) {}
                  }
                },
                onCameraMoveStarted: () {
                  if (_isProgrammaticCameraMove) {
                    _isProgrammaticCameraMove = false;
                    return;
                  }
                  if (_isCameraFollowLocked) {
                    setState(() {
                      _isCameraFollowLocked = false;
                    });
                  }
                },
                onTap: (pos) => _handleMapTap(pos, provider),
                onLongPress: (pos) => _handleMapTap(pos, provider),
                markers: _buildMarkers(provider),
                polylines: _buildPolylines(carPos),
                circles: _buildCircles(provider),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),

              // ─── Map Loading Placeholder Overlay ─────────────────
              if (!_isMapReady)
                Positioned.fill(
                  child: Container(
                    color: _isDarkStyleActive ? AppColors.deepSpace : const Color(0xFFEDF1F5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.navArrowBlue),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'CALIBRATING ROAD NAVIGATION...',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: _isDarkStyleActive ? Colors.white70 : AppColors.navTextDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── 2. Tactical Hazard Glow Border ───────────────────
              if (provider.currentRiskLevel != RiskLevel.green)
                AnimatedBuilder(
                  animation: _riskPulseController,
                  builder: (context, child) {
                    final pulseColor = provider.currentRiskLevel == RiskLevel.red
                        ? AppColors.dangerRed
                        : AppColors.warningAmber;

                    return IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: pulseColor.withValues(
                              alpha: provider.currentRiskLevel == RiskLevel.red
                                  ? 0.35 + (_riskPulseController.value * 0.45)
                                  : 0.30,
                            ),
                            width: provider.currentRiskLevel == RiskLevel.red ? 5 : 2.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // ─── 3. Top Geoposition Share Banner (Image 1) ─────────
              if (_showGeopositionBanner)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: GeopositionShareBanner(
                    isDark: _isDarkStyleActive,
                    latitude: centerLat,
                    longitude: centerLng,
                    onDismiss: () => setState(() => _showGeopositionBanner = false),
                    onShare: () => _handleShareLocation(provider),
                  ),
                ),

              // ─── 4. Top-Left Turn Maneuver Card (Image 2) ──────────
              if (_activeRoute != null && currentStep != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + (_showGeopositionBanner ? 84 : 12),
                  left: 16,
                  child: ManeuverTopHud(
                    step: currentStep,
                    distanceToTurnMeters: distanceToNextTurn,
                    isDark: _isDarkStyleActive,
                    onCancel: _cancelNavigation,
                  ),
                ),

              // ─── 5. Top-Right Dual Speedometer Gauge (Image 2) ─────
              Positioned(
                top: MediaQuery.of(context).padding.top + (_showGeopositionBanner ? 84 : 12),
                right: 16,
                child: SpeedometerTopHud(
                  currentSpeed: carSpeed,
                  speedLimit: _speedLimitKmh,
                  isDark: _isDarkStyleActive,
                  onTap: _showSpeedLimitDialog,
                ),
              ),

              // ─── 6. Lane Guidance Overlay on Road (Image 1) ────────
              if (_activeRoute != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + (_showGeopositionBanner ? 154 : 82),
                  left: 16,
                  child: LaneGuidanceOverlay(
                    laneCount: 3,
                    recommendedLane: currentStep?.maneuver == ManeuverType.turnLeft
                        ? 0
                        : (currentStep?.maneuver == ManeuverType.turnRight ? 2 : 1),
                    hasTrafficLight: true,
                    zoneBadge: '${_speedLimitKmh.toInt()}',
                  ),
                ),

              // ─── 7. Right Vertical Floating Map Dock (Images 1 & 2) ─
              Positioned(
                top: MediaQuery.of(context).padding.top + (_showGeopositionBanner ? 160 : 88),
                right: 16,
                child: FloatingMapDock(
                  isDark: _isDarkStyleActive,
                  is3D: _is3DMode,
                  isCameraLocked: _isCameraFollowLocked,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onReportHazard: _reportHazard,
                  onToggleTheme: _toggleDayNightTheme,
                  onToggle3D: () => _toggle3DMode(provider),
                  onResetCompass: () => _resetCompassNorth(provider),
                  onRecenter: () => _recenterOnDriver(provider),
                ),
              ),

              // ─── 8. Warning Overlay (Active Hazards) ──────────────
              if (provider.activeAlerts.isNotEmpty && _radarRangeMeters > 0)
                Positioned(
                  bottom: 96,
                  left: 16,
                  right: 16,
                  child: WarningOverlay(alerts: provider.activeAlerts),
                ),

              // ─── 9. Floating Bottom Capsule Pill Bar & Route Sheet ───
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: NavFloatingPillBar(
                  isDark: _isDarkStyleActive,
                  activeRoute: _activeRoute,
                  previewDestination: _droppedPinDestination,
                  currentSpeed: carSpeed,
                  nearbyCount: _radarRangeMeters > 0 ? provider.nearbyVehicles.length : 0,
                  isConnected: provider.isConnected,
                  onConnectionTap: () => _handleConnectionTap(provider),
                  onSearchTap: () => _showDestinationPicker(provider),
                  onStartNavigation: () {
                    if (_droppedPinDestination != null) {
                      _startNavigationTo(_droppedPinDestination!, provider);
                    } else if (_activeRoute == null) {
                      _showDestinationPicker(provider);
                    }
                  },
                  onCancelNavigation: _cancelNavigation,
                  onStepByStepTap: _showStepByStepSheet,
                  onFilterTap: _showMapLayerSheet,
                  onRadarRangeTap: _openRadarRangeDialog,
                  onExitCockpit: _stopDriving,
                  currentLocationName: _currentLocationDisplayName,
                  onShareTap: () => _handleShareLocation(provider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
