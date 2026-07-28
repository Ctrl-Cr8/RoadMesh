// ─── Driving Screen ─────────────────────────────────────────────────────────
//
// Full-screen Google Map with nearby vehicle markers, status bar,
// and warning overlay. Minimal design to avoid driver distraction.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/driving_provider.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../widgets/warning_overlay.dart';
import '../widgets/status_bar.dart';

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _riskPulseController;

  // Dark mode map style
  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
    {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
    {"featureType": "land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
    {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
    {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
    {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
    {"featureType": "water", "elementType": "geometry.fill", "stylers": [{"color": "#0e1626"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _riskPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _riskPulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Build map markers for nearby vehicles.
  Set<Marker> _buildMarkers(DrivingProvider provider) {
    final markers = <Marker>{};

    // Ego vehicle marker
    if (provider.currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('ego'),
        position: LatLng(
          provider.currentPosition!.latitude,
          provider.currentPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: provider.currentHeading,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'You',
          snippet: '${provider.currentSpeed.toStringAsFixed(0)} km/h',
        ),
      ));
    }

    // Nearby vehicle markers
    for (final vehicle in provider.nearbyVehicles) {
      // Determine marker color based on alerts
      double hue = BitmapDescriptor.hueGreen;
      final alert = provider.activeAlerts
          .where((a) => a.vehicleId == vehicle.id)
          .firstOrNull;

      if (alert != null) {
        switch (alert.riskLevel) {
          case RiskLevel.red:
            hue = BitmapDescriptor.hueRed;
            break;
          case RiskLevel.yellow:
            hue = BitmapDescriptor.hueYellow;
            break;
          case RiskLevel.green:
            hue = BitmapDescriptor.hueGreen;
            break;
        }
      }

      markers.add(Marker(
        markerId: MarkerId(vehicle.id),
        position: LatLng(vehicle.lat, vehicle.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        rotation: vehicle.heading,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: '${vehicle.vehicleType.icon} ${vehicle.vehicleType.label}',
          snippet: vehicle.speedDisplay,
        ),
      ));
    }

    return markers;
  }

  /// Move camera to follow the driver.
  void _followDriver(DrivingProvider provider) {
    if (_mapController == null || provider.currentPosition == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          zoom: 17.0,
          bearing: provider.currentHeading,
          tilt: 45,
        ),
      ),
    );
  }

  Future<void> _stopDriving() async {
    final provider = context.read<DrivingProvider>();
    await provider.stopDriving();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrivingProvider>(
      builder: (context, provider, _) {
        // Animate risk border
        if (provider.currentRiskLevel == RiskLevel.red) {
          _riskPulseController.repeat(reverse: true);
        } else {
          _riskPulseController.stop();
          _riskPulseController.reset();
        }

        // Follow driver when position updates
        if (provider.currentPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _followDriver(provider);
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              // ─── Map ───────────────────────────
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    provider.currentPosition?.latitude ?? 10.0261,
                    provider.currentPosition?.longitude ?? 76.3125,
                  ),
                  zoom: 17.0,
                  tilt: 45,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.setMapStyle(_darkMapStyle);
                },
                markers: _buildMarkers(provider),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                buildingsEnabled: false,
              ),

              // ─── Risk border glow ─────────────
              if (provider.currentRiskLevel != RiskLevel.green)
                AnimatedBuilder(
                  animation: _riskPulseController,
                  builder: (context, child) {
                    return IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: provider.currentRiskLevel.color.withOpacity(
                              provider.currentRiskLevel == RiskLevel.red
                                  ? 0.3 + _riskPulseController.value * 0.4
                                  : 0.2,
                            ),
                            width: provider.currentRiskLevel == RiskLevel.red
                                ? 4
                                : 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // ─── Status Bar (top) ─────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: DrivingStatusBar(
                  isConnected: provider.isConnected,
                  speed: provider.currentSpeed,
                  heading: provider.currentHeading,
                  nearbyCount: provider.nearbyVehicles.length,
                  riskLevel: provider.currentRiskLevel,
                ),
              ),

              // ─── Warning Overlay (bottom) ─────
              if (provider.activeAlerts.isNotEmpty)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: WarningOverlay(alerts: provider.activeAlerts),
                ),

              // ─── Stop Button ──────────────────
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _stopDriving,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF44336),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF44336).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stop_rounded,
                        color: Colors.white,
                        size: 32,
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
