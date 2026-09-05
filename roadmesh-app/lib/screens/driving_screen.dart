// ─── Driving Screen (V2X Navigation Cockpit) ──────────────────────────────────
//
// Full-featured Google Maps automotive navigation cockpit:
// - Turn-by-turn routing with glowing polylines and next maneuver HUD
// - V2X Radar Detection Range configurable from 0m (OFF) to 300m
// - Multi-layer map views (Friendly Road, Terrain, Satellite, Dark Tactical)
// - Live Google Traffic layer toggle and 2D/3D perspective camera controls
// - Real-time speed limit badge and overspeed alerts
// - Instant camera re-center and compass North orientation

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/driving_provider.dart';
import '../models/alert.dart';
import '../models/vehicle.dart';
import '../navigation/navigation_route.dart';
import '../navigation/route_service.dart';
import '../widgets/warning_overlay.dart';
import '../widgets/status_bar.dart';
import '../widgets/navigation_banner.dart';
import '../widgets/radar_range_dialog.dart';
import '../widgets/map_layer_sheet.dart';
import '../widgets/destination_picker_sheet.dart';
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

  // Camera follow state
  bool _isCameraFollowLocked = true;

  // Map layer controls
  MapType _currentMapType = MapType.normal;
  bool _isDarkStyleActive = true;
  bool _isTrafficEnabled = false;
  bool _is3DMode = true;

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
  String _currentSpeedZoneName = 'MA College Rd (College Zone)';

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

  @override
  void initState() {
    super.initState();
    _speedLimitKmh = RouteService.getDesignatedSpeedLimit('MA College Rd');
    _currentSpeedZoneName = 'MA College Rd (College Zone)';

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

  /// Builds custom vector markers for driver, peers, and destination flag.
  Set<Marker> _buildMarkers(DrivingProvider provider) {
    final markers = <Marker>{};

    final egoLat = provider.currentPosition?.latitude;
    final egoLng = provider.currentPosition?.longitude;

    // 1. Ego (Driver) Custom Vehicle Marker
    if (egoLat != null && egoLng != null) {
      final egoKey = '${provider.vehicleType.name}_green_egoTrue';
      final egoIcon = _markerCache[egoKey] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);

      markers.add(
        Marker(
          markerId: const MarkerId('ego'),
          position: LatLng(egoLat, egoLng),
          icon: egoIcon,
          rotation: provider.currentHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 100,
          infoWindow: InfoWindow(
            title: '${provider.vehicleType.icon} Your ${provider.vehicleType.displayName}',
            snippet:
                '${provider.currentSpeed.toStringAsFixed(0)} km/h • Heading: ${provider.currentHeading.toStringAsFixed(0)}° • V2X Active',
          ),
        ),
      );
    }

    // 2. Real Nearby Peers (Filtered by V2X Radar Range: 0 to 300m)
    if (_radarRangeMeters > 0) {
      for (final vehicle in provider.nearbyVehicles) {
        if (egoLat != null && egoLng != null) {
          final dist = _distanceBetween(egoLat, egoLng, vehicle.lat, vehicle.lng);
          if (dist > _radarRangeMeters) continue;
        }

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

    return markers;
  }

  /// Builds navigation route polylines.
  Set<Polyline> _buildPolylines() {
    if (_activeRoute == null) return const <Polyline>{};

    return {
      // Glow underlay polyline
      Polyline(
        polylineId: const PolylineId('nav_route_glow'),
        points: _activeRoute!.polylinePoints,
        color: AppColors.cyberBlue.withValues(alpha: 0.35),
        width: 10,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      // Core navigation polyline
      Polyline(
        polylineId: const PolylineId('nav_route_core'),
        points: _activeRoute!.polylinePoints,
        color: AppColors.cyberBlue,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  /// Clean map view: zero hardcoded circles!
  Set<Circle> _buildCircles(DrivingProvider provider) => const <Circle>{};

  /// Smoothly follows the driver in 2D/3D perspective (zoom 19.3 when navigating, 17.5 in free drive).
  void _followDriver(DrivingProvider provider) {
    if (!_isCameraFollowLocked || _mapController == null || provider.currentPosition == null) return;

    final targetZoom = _activeRoute != null ? 19.3 : 17.5;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          zoom: targetZoom,
          bearing: provider.currentHeading,
          tilt: _is3DMode ? 38.0 : 0.0,
        ),
      ),
    );
  }

  /// Re-centers the camera smoothly onto the driver and locks tracking.
  void _recenterOnDriver(DrivingProvider provider) {
    setState(() {
      _isCameraFollowLocked = true;
    });

    final lat = provider.currentPosition?.latitude ?? 10.0538;
    final lng = provider.currentPosition?.longitude ?? 76.6193;
    final targetZoom = _activeRoute != null ? 19.3 : 17.5;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: targetZoom,
          bearing: provider.currentHeading,
          tilt: _is3DMode ? 38.0 : 0.0,
        ),
      ),
    );
  }

  /// Resets map orientation directly to True North (0°).
  void _resetCompassNorth(DrivingProvider provider) {
    final lat = provider.currentPosition?.latitude ?? 10.0538;
    final lng = provider.currentPosition?.longitude ?? 76.6193;

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 17.5,
          bearing: 0.0,
          tilt: 0.0,
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
    final originLat = provider.currentPosition?.latitude ?? 10.0538;
    final originLng = provider.currentPosition?.longitude ?? 76.6193;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DestinationPickerSheet(
        userLocation: LatLng(originLat, originLng),
        onDestinationSelected: (dest) {
          _startNavigationTo(dest, provider);
        },
      ),
    );
  }

  /// Starts turn-by-turn navigation to any destination using real OSRM road network routing.
  Future<void> _startNavigationTo(NavDestination dest, DrivingProvider provider) async {
    final originLat = provider.currentPosition?.latitude ?? 10.0538;
    final originLng = provider.currentPosition?.longitude ?? 76.6193;

    setState(() {
      _isCalculatingRoute = true;
      _droppedPinDestination = null;
    });

    try {
      final route = await RouteService.calculateRoute(
        origin: LatLng(originLat, originLng),
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

      // Zoom in close to the road and vehicle (Image 1, zoom 19.3) with cockpit perspective
      double navBearing = provider.currentHeading;
      if (navBearing <= 0 && route.polylinePoints.length >= 2) {
        final p1 = route.polylinePoints[0];
        final p2 = route.polylinePoints[1];
        final dLat = p2.latitude - p1.latitude;
        final dLng = p2.longitude - p1.longitude;
        navBearing = (math.atan2(dLng, dLat) * 180 / math.pi) % 360;
      }

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(originLat, originLng),
            zoom: 19.3,
            bearing: navBearing,
            tilt: _is3DMode ? 38.0 : 0.0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
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

      // Smoothly center the map directly on the landmark icon!
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(geocoded.location),
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
          backgroundColor: const Color(0xFF0D1526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.speed_rounded, color: AppColors.cyberBlue, size: 22),
              SizedBox(width: 10),
              Text(
                'ROAD SPEED LIMIT',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.0,
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
                  color: AppColors.cyberBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAutoSpeedLimit
                        ? AppColors.cyberBlue.withValues(alpha: 0.4)
                        : Colors.white12,
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
                            color: _isAutoSpeedLimit ? AppColors.safeGreen : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isAutoSpeedLimit ? 'AUTO-DETECTED ROAD ZONE' : 'MANUAL OVERRIDE ACTIVE',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isAutoSpeedLimit ? AppColors.safeGreen : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentSpeedZoneName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Designated Limit: ${_speedLimitKmh.toInt()} km/h',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        color: AppColors.cyberBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Road speed limits are automatically determined from road classification (College/School: 30 km/h, Residential: 40 km/h, Urban: 50 km/h, Highway: 70-80 km/h).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 14),

              // Auto-Detect Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto-Detect From Road',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: _isAutoSpeedLimit,
                    activeColor: AppColors.cyberBlue,
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
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
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
                    selectedColor: AppColors.cyberBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
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
                  const Text('Show Badge on Cockpit', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Switch(
                    value: _showSpeedLimitSign,
                    activeColor: AppColors.cyberBlue,
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
              child: const Text('CLOSE', style: TextStyle(color: AppColors.cyberBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Google Maps-style confirmation card when a pin is dropped on the map.
  Widget _buildDroppedPinCard(DrivingProvider provider) {
    final originLat = provider.currentPosition?.latitude ?? 10.0538;
    final originLng = provider.currentPosition?.longitude ?? 76.6193;
    final dist = RouteService.distanceBetween(
      LatLng(originLat, originLng),
      _droppedPinDestination!.location,
    );
    final distStr = dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(1)} km'
        : '${dist.toStringAsFixed(0)} m';
    final estMin = (dist / 500).round().clamp(1, 999);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFA090E1A),
            border: Border.all(color: AppColors.cyberBlue.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 6),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dangerRed.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.dangerRed),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.dangerRed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _droppedPinDestination!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _droppedPinDestination!.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _droppedPinDestination = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car_rounded, color: AppColors.cyberBlue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$distStr • ~$estMin min',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isCalculatingRoute
                        ? null
                        : () => _startNavigationTo(_droppedPinDestination!, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.cyberBlue,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyberBlue.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCalculatingRoute)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          else ...[
                            const Icon(Icons.navigation_rounded, color: Colors.black, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'START NAVIGATION',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
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
            ],
          ),
        ),
      ),
    );
  }

  void _cancelNavigation() {
    setState(() {
      _activeRoute = null;
      _currentStepIndex = 0;
      _droppedPinDestination = null;
    });

    final provider = context.read<DrivingProvider>();
    final lat = provider.currentPosition?.latitude ?? 10.0538;
    final lng = provider.currentPosition?.longitude ?? 76.6193;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 17.5,
          bearing: provider.currentHeading,
          tilt: _is3DMode ? 35.0 : 0.0,
        ),
      ),
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
            color: const Color(0xFF0D1526).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: alert != null
                  ? (alert.riskLevel == RiskLevel.red
                      ? AppColors.dangerRed
                      : AppColors.warningAmber)
                  : AppColors.cyberBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyberBlue.withValues(alpha: 0.15),
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
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'NODE: ${vehicle.id.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
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
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.cyberBlue,
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

        if (provider.currentPosition != null && _isCameraFollowLocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _followDriver(provider);
          });
        }

        final centerLat = provider.currentPosition?.latitude ?? 10.0538;
        final centerLng = provider.currentPosition?.longitude ?? 76.6193;
        final isOverspeeding = provider.currentSpeed > _speedLimitKmh;

        // Automatic turn-by-turn maneuver progress tracking
        NavigationStep? currentStep;
        double distanceToNextTurn = 0.0;
        if (_activeRoute != null && _activeRoute!.steps.isNotEmpty) {
          final curIdx = _currentStepIndex.clamp(0, _activeRoute!.steps.length - 1);
          currentStep = _activeRoute!.steps[curIdx];

          final userLat = provider.currentPosition?.latitude ?? centerLat;
          final userLng = provider.currentPosition?.longitude ?? centerLng;
          distanceToNextTurn = RouteService.distanceBetween(
            LatLng(userLat, userLng),
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
          backgroundColor: AppColors.deepSpace,
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
                  if (_isDarkStyleActive && _currentMapType == MapType.normal) {
                    try {
                      // ignore: deprecated_member_use
                      controller.setMapStyle(_darkMapStyle);
                    } catch (_) {}
                  }
                },
                onCameraMoveStarted: () {
                  if (_isCameraFollowLocked) {
                    setState(() {
                      _isCameraFollowLocked = false;
                    });
                  }
                },
                onTap: (pos) => _handleMapTap(pos, provider),
                onLongPress: (pos) => _handleMapTap(pos, provider),
                markers: _buildMarkers(provider),
                polylines: _buildPolylines(),
                circles: _buildCircles(provider),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
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

              // ─── 3. Top HUD Status Bar with Interactive Compass ────
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: DrivingStatusBar(
                  isConnected: provider.isConnected,
                  speed: provider.currentSpeed,
                  heading: provider.currentHeading,
                  nearbyCount: _radarRangeMeters > 0 ? provider.nearbyVehicles.length : 0,
                  riskLevel: provider.currentRiskLevel,
                  vehicleType: provider.vehicleType,
                  onCompassTap: () => _resetCompassNorth(provider),
                  onConnectionTap: () => _handleConnectionTap(provider),
                ),
              ),

              // ─── 4. Active Turn-by-Turn Navigation Banner ─────────
              if (_activeRoute != null && currentStep != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 76,
                  left: 16,
                  right: 16,
                  child: NavigationBanner(
                    route: _activeRoute!,
                    currentStep: currentStep,
                    distanceToNextTurn: distanceToNextTurn,
                    onCancel: _cancelNavigation,
                  ),
                ),

              // ─── 4b. Real Road Route Calculating Indicator ───────
              if (_isCalculatingRoute)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 76,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xEE090E1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cyberBlue),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cyberBlue,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'CALCULATING OPTIMAL ROUTE...',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyberBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── 5. Radar Metric & Automotive Control Dock ────────
              Positioned(
                top: _activeRoute != null
                    ? MediaQuery.of(context).padding.top + 152
                    : MediaQuery.of(context).padding.top + 76,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tappable V2X Radar Range Badge (0m OFF to 300m)
                      GestureDetector(
                        onTap: _openRadarRangeDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xEE0A0F1D),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _radarRangeMeters == 0
                                  ? AppColors.dangerRed.withValues(alpha: 0.5)
                                  : AppColors.cyberBlue.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_radarRangeMeters == 0 ? AppColors.dangerRed : AppColors.cyberBlue)
                                    .withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _radarRangeMeters == 0 ? AppColors.dangerRed : AppColors.cyberBlue,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _radarRangeMeters == 0
                                    ? 'V2X RADAR: OFF'
                                    : 'V2X RADAR: ${_radarRangeMeters}m',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _radarRangeMeters == 0 ? AppColors.dangerRed : AppColors.cyberBlue,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.tune_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Navigation Search, Layer Picker & Re-center Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Navigate Button
                          GestureDetector(
                            onTap: () => _showDestinationPicker(provider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xEE0A0F1D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _activeRoute != null ? AppColors.cyberBlue : AppColors.glassBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: _activeRoute != null ? AppColors.cyberBlue : Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ROUTE',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _activeRoute != null ? AppColors.cyberBlue : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Map Layer Picker Button
                          GestureDetector(
                            onTap: _showMapLayerSheet,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xEE0A0F1D),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.glassBorder, width: 1.2),
                              ),
                              child: const Icon(Icons.layers_outlined, color: Colors.white, size: 17),
                            ),
                          ),

                          // Re-center Button
                          if (!_isCameraFollowLocked) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _recenterOnDriver(provider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.cyberBlue.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.cyberBlue, width: 1.4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyberBlue.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.my_location_rounded, size: 14, color: AppColors.cyberBlue),
                                    SizedBox(width: 4),
                                    Text(
                                      'RE-CENTER',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.cyberBlue,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 6. Speed Limit Sign (Bottom Left Floating Badge - Tappable) ─
              if (_showSpeedLimitSign)
                Positioned(
                  bottom: 36,
                  left: 16,
                  child: GestureDetector(
                    onTap: _showSpeedLimitDialog,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOverspeeding ? AppColors.dangerRed : const Color(0xFFD32F2F),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isOverspeeding
                                    ? AppColors.dangerRed.withValues(alpha: 0.5)
                                    : Colors.black26,
                                blurRadius: isOverspeeding ? 14 : 8,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _speedLimitKmh.toInt().toString(),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xDD0D1526),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isAutoSpeedLimit
                                  ? AppColors.cyberBlue.withValues(alpha: 0.5)
                                  : Colors.white24,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _isAutoSpeedLimit ? 'ZONE' : 'LIMIT',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: _isAutoSpeedLimit ? AppColors.cyberBlue : Colors.white70,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── 7. Warning Overlay (Active Hazards) ──────────────
              if (provider.activeAlerts.isNotEmpty && _radarRangeMeters > 0)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: WarningOverlay(alerts: provider.activeAlerts),
                ),

              // ─── 7b. Dropped Pin "Navigate Here" Bottom Card ─────
              if (_droppedPinDestination != null && _activeRoute == null)
                Positioned(
                  bottom: 96,
                  left: 16,
                  right: 16,
                  child: _buildDroppedPinCard(provider),
                ),

              // ─── 8. End Session Button ────────────────────────────
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _stopDriving,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xEE0A0F1D),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.dangerRed.withValues(alpha: 0.65),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dangerRed.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stop_circle_outlined,
                            color: AppColors.dangerRed,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'END SESSION',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
