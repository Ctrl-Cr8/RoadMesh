// ─── Nav Floating Pill Bar & Expandable Route Sheet ─────────────────────────
//
// Matches Images 1, 2, and 3:
// - Minimized: Floating capsule pill [ 🔍 | 6 min | 07:22 arrival | 2.2 km | ☰ ]
// - Expanded: Full Route Overview Sheet with waypoints, quick chips, trip stats,
//   traffic lights count, big green "Go!" button, and transport mode selector.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../navigation/navigation_route.dart';
import '../theme/app_colors.dart';

enum TransportMode { car, moto, bus, bike, walk }

class NavFloatingPillBar extends StatefulWidget {
  final bool isDark;
  final ActiveNavigationRoute? activeRoute;
  final NavDestination? previewDestination;
  final double currentSpeed;
  final int nearbyCount;
  final VoidCallback onSearchTap;
  final VoidCallback onStartNavigation;
  final VoidCallback? onCancelNavigation;
  final VoidCallback? onStepByStepTap;
  final bool isConnected;
  final VoidCallback? onFilterTap;
  final VoidCallback? onRadarRangeTap;
  final VoidCallback? onExitCockpit;
  final VoidCallback? onConnectionTap;
  final VoidCallback? onShareTap;
  final String? currentLocationName;
  final ValueChanged<TransportMode>? onModeChanged;

  const NavFloatingPillBar({
    super.key,
    required this.isDark,
    this.activeRoute,
    this.previewDestination,
    required this.currentSpeed,
    required this.nearbyCount,
    this.isConnected = true,
    required this.onSearchTap,
    required this.onStartNavigation,
    this.onCancelNavigation,
    this.onStepByStepTap,
    this.onFilterTap,
    this.onRadarRangeTap,
    this.onExitCockpit,
    this.onConnectionTap,
    this.onShareTap,
    this.currentLocationName,
    this.onModeChanged,
  });

  @override
  State<NavFloatingPillBar> createState() => _NavFloatingPillBarState();
}

class _NavFloatingPillBarState extends State<NavFloatingPillBar> {
  bool _isExpanded = false;
  TransportMode _selectedMode = TransportMode.car;
  bool _isInsured = true;

  String _getModeDuration(TransportMode mode) {
    final distanceMeters = widget.activeRoute?.totalDistanceMeters ??
        (widget.previewDestination?.distanceFromUserMeters ?? 2200.0);
    final distanceKm = distanceMeters / 1000.0;

    int minutes;
    switch (mode) {
      case TransportMode.car:
        if (widget.activeRoute != null) {
          minutes = (widget.activeRoute!.estimatedSeconds / 60).round().clamp(1, 999);
        } else {
          minutes = (distanceKm / 35.0 * 60).round().clamp(1, 999);
        }
        break;
      case TransportMode.moto:
        minutes = (distanceKm / 40.0 * 60).round().clamp(1, 999);
        break;
      case TransportMode.bus:
        minutes = ((distanceKm / 20.0 * 60) + 4).round().clamp(2, 999);
        break;
      case TransportMode.bike:
        minutes = (distanceKm / 14.0 * 60).round().clamp(1, 999);
        break;
      case TransportMode.walk:
        minutes = (distanceKm / 4.8 * 60).round().clamp(1, 999);
        break;
    }
    return '$minutes min';
  }

  String get _etaString {
    final now = DateTime.now();
    final durationSeconds = widget.activeRoute?.estimatedSeconds ?? 360;
    final arrival = now.add(Duration(seconds: durationSeconds));
    return DateFormat('HH:mm').format(arrival);
  }

  String get _durationString {
    if (widget.activeRoute != null) {
      return widget.activeRoute!.formattedDuration;
    }
    return '6 min';
  }

  String get _distanceString {
    if (widget.activeRoute != null) {
      return widget.activeRoute!.formattedDistance;
    }
    return '2.2 km';
  }

  int get _trafficLightsCount {
    if (widget.activeRoute != null) {
      final steps = widget.activeRoute!.steps.length;
      return (steps / 2).ceil().clamp(1, 12);
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpanded || widget.previewDestination != null) {
      return _buildExpandedRouteSheet();
    }
    return _buildFloatingCapsulePill();
  }

  // ─── Minimized Floating Capsule Pill (Images 1 & 2) ─────────────────────────
  Widget _buildFloatingCapsulePill() {
    final bgColor = widget.isDark ? const Color(0xEE141D2E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.navTextDark;
    final subColor = widget.isDark ? AppColors.textMuted : AppColors.navTextMutedLight;
    final borderColor = widget.isDark ? Colors.white12 : AppColors.navBorderLight;
    final isNavigating = widget.activeRoute != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: widget.isDark ? AppColors.floatingPillShadowDark : AppColors.floatingPillShadow,
      ),
      child: Row(
        children: [
          // Left Search Button
          InkWell(
            onTap: widget.onSearchTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.search_rounded, color: textColor, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Central Metrics
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isExpanded = true);
              },
              behavior: HitTestBehavior.opaque,
              child: isNavigating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Duration
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _durationString,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'time',
                              style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Arrival Time
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _etaString,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'arrival',
                              style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Distance
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _distanceString,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'dist',
                              style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isConnected ? 'FREE DRIVE' : 'OFFLINE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: widget.isConnected ? textColor : AppColors.dangerRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onConnectionTap,
                              child: Text(
                                widget.isConnected ? 'V2X Active' : 'Tap to Reconnect',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.isConnected ? AppColors.safeGreen : AppColors.warningAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.nearbyCount} PEERS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'in radar',
                              style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Right Menu Button
          InkWell(
            onTap: () {
              setState(() => _isExpanded = true);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.menu_rounded, color: textColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Full Expandable Route Overview Sheet (Image 3) ─────────────────────────
  Widget _buildExpandedRouteSheet() {
    final bgColor = widget.isDark ? const Color(0xFF111827) : Colors.white;
    final cardBg = widget.isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final textColor = widget.isDark ? Colors.white : AppColors.navTextDark;
    final subColor = widget.isDark ? AppColors.textMuted : AppColors.navTextMutedLight;
    final borderColor = widget.isDark ? Colors.white12 : AppColors.navBorderLight;

    final destinationName = widget.activeRoute?.destination.title ??
        widget.previewDestination?.title ??
        'Choose Destination';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Origin & Destination Waypoints
          Row(
            children: [
              // Waypoint Dots & Vertical Line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.safeGreen,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navArrowBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Address Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentLocationName ?? 'Your Current Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isExpanded = false);
                        widget.onSearchTap();
                      },
                      child: Text(
                        destinationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Swap & Close Buttons
              IconButton(
                icon: Icon(Icons.swap_vert_rounded, color: subColor, size: 22),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subColor, size: 22),
                onPressed: () {
                  setState(() => _isExpanded = false);
                  if (widget.activeRoute != null && widget.onCancelNavigation != null) {
                    widget.onCancelNavigation!();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Action Chips Scroll Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _QuickChip(
                  icon: Icons.layers_outlined,
                  label: 'Map Layers',
                  isDark: widget.isDark,
                  onTap: widget.onFilterTap,
                ),
                _QuickChip(
                  icon: Icons.radar_rounded,
                  label: 'V2X Radar',
                  isDark: widget.isDark,
                  onTap: widget.onRadarRangeTap,
                ),
                _QuickChip(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  isDark: widget.isDark,
                  onTap: widget.onShareTap,
                ),
                _QuickChip(
                  icon: Icons.local_parking_rounded,
                  label: 'To parking',
                  isDark: widget.isDark,
                ),
                _QuickChip(
                  icon: Icons.power_settings_new_rounded,
                  label: 'End Session',
                  isDark: widget.isDark,
                  color: AppColors.dangerRed,
                  onTap: widget.onExitCockpit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Route Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Main Route Time & ETA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _durationString,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: subColor),
                              const SizedBox(width: 6),
                              Text(
                                _etaString,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_distanceString • Best Route',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Traffic lights • $_trafficLightsCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Big Green "Go!" Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navGoGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.navGoGreen.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() => _isExpanded = false);
                        widget.onStartNavigation();
                      },
                      child: const Text(
                        'Go!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isInsured = !_isInsured),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isInsured ? Icons.check_circle_rounded : Icons.shield_outlined,
                                size: 16,
                                color: _isInsured ? AppColors.safeGreen : subColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Insure my trip',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: widget.onStepByStepTap ?? () {},
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.compare_arrows_rounded, size: 16, color: subColor),
                              const SizedBox(width: 6),
                              Text(
                                'Step by step',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Transport Mode Selector Row at the Bottom (🚗 🚌 🚶 🚕 🏍️ 🚲)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _TransportModeTab(
                  mode: TransportMode.car,
                  icon: Icons.directions_car_rounded,
                  label: _getModeDuration(TransportMode.car),
                  isSelected: _selectedMode == TransportMode.car,
                  isDark: widget.isDark,
                  onTap: () {
                    setState(() => _selectedMode = TransportMode.car);
                    widget.onModeChanged?.call(TransportMode.car);
                  },
                ),
                _TransportModeTab(
                  mode: TransportMode.moto,
                  icon: Icons.two_wheeler_rounded,
                  label: _getModeDuration(TransportMode.moto),
                  isSelected: _selectedMode == TransportMode.moto,
                  isDark: widget.isDark,
                  onTap: () {
                    setState(() => _selectedMode = TransportMode.moto);
                    widget.onModeChanged?.call(TransportMode.moto);
                  },
                ),
                _TransportModeTab(
                  mode: TransportMode.bus,
                  icon: Icons.directions_bus_rounded,
                  label: _getModeDuration(TransportMode.bus),
                  isSelected: _selectedMode == TransportMode.bus,
                  isDark: widget.isDark,
                  onTap: () {
                    setState(() => _selectedMode = TransportMode.bus);
                    widget.onModeChanged?.call(TransportMode.bus);
                  },
                ),
                _TransportModeTab(
                  mode: TransportMode.bike,
                  icon: Icons.pedal_bike_rounded,
                  label: _getModeDuration(TransportMode.bike),
                  isSelected: _selectedMode == TransportMode.bike,
                  isDark: widget.isDark,
                  onTap: () {
                    setState(() => _selectedMode = TransportMode.bike);
                    widget.onModeChanged?.call(TransportMode.bike);
                  },
                ),
                _TransportModeTab(
                  mode: TransportMode.walk,
                  icon: Icons.directions_walk_rounded,
                  label: _getModeDuration(TransportMode.walk),
                  isSelected: _selectedMode == TransportMode.walk,
                  isDark: widget.isDark,
                  onTap: () {
                    setState(() => _selectedMode = TransportMode.walk);
                    widget.onModeChanged?.call(TransportMode.walk);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback? onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isDark ? Colors.white : AppColors.navTextDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color != null ? color!.withValues(alpha: 0.5) : (isDark ? Colors.white12 : AppColors.navBorderLight)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportModeTab extends StatelessWidget {
  final TransportMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TransportModeTab({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.navGoGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.navGoGreen
                  : (isDark ? Colors.white60 : AppColors.navTextMutedLight),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.navGoGreen : const Color(0xFF1B5E20))
                    : (isDark ? Colors.white60 : AppColors.navTextMutedLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
