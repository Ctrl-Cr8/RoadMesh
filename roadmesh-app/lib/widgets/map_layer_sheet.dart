// ─── Map Layer & Display Controls Sheet ───────────────────────────────────────
//
// Modal sheet allowing drivers to configure map styles, toggle live traffic,
// toggle 3D buildings, and switch 2D/3D perspective camera angles.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

class MapLayerSheet extends StatelessWidget {
  final MapType currentMapType;
  final bool isDarkStyleActive;
  final bool isTrafficEnabled;
  final bool is3DMode;
  final Function(MapType type, bool isDark) onStyleChanged;
  final ValueChanged<bool> onTrafficToggled;
  final ValueChanged<bool> on3DModeToggled;

  const MapLayerSheet({
    super.key,
    required this.currentMapType,
    required this.isDarkStyleActive,
    required this.isTrafficEnabled,
    required this.is3DMode,
    required this.onStyleChanged,
    required this.onTrafficToggled,
    required this.on3DModeToggled,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF090E1A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MAP DISPLAY & NAVIGATION LAYERS',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Map Styles Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _styleCard(
                    'Friendly Road',
                    Icons.map_outlined,
                    currentMapType == MapType.normal && !isDarkStyleActive,
                    () => onStyleChanged(MapType.normal, false),
                  ),
                  _styleCard(
                    'Terrain',
                    Icons.terrain_outlined,
                    currentMapType == MapType.terrain,
                    () => onStyleChanged(MapType.terrain, false),
                  ),
                  _styleCard(
                    'Satellite',
                    Icons.satellite_alt_outlined,
                    currentMapType == MapType.hybrid,
                    () => onStyleChanged(MapType.hybrid, false),
                  ),
                  _styleCard(
                    'Dark Tactical',
                    Icons.dark_mode_outlined,
                    currentMapType == MapType.normal && isDarkStyleActive,
                    () => onStyleChanged(MapType.normal, true),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 16),

              // Live Traffic Toggle
              SwitchListTile(
                value: isTrafficEnabled,
                onChanged: onTrafficToggled,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.cyberBlue,
                title: const Text(
                  'Live Traffic Congestion',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                subtitle: const Text(
                  'Color-coded real-time road congestion overlay',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTrafficEnabled
                        ? AppColors.cyberBlue.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.traffic_rounded,
                    color: isTrafficEnabled ? AppColors.cyberBlue : Colors.white60,
                    size: 18,
                  ),
                ),
              ),

              // 3D Perspective Tilt Toggle
              SwitchListTile(
                value: is3DMode,
                onChanged: on3DModeToggled,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.cyberBlue,
                title: const Text(
                  '3D Perspective Cockpit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                subtitle: Text(
                  is3DMode
                      ? '35° dynamic tilted camera following vehicle heading'
                      : '0° flat 2D top-down view',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: is3DMode
                        ? AppColors.cyberBlue.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.view_in_ar_rounded,
                    color: is3DMode ? AppColors.cyberBlue : Colors.white60,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styleCard(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? AppColors.cyberBlue.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isSelected ? AppColors.cyberBlue : AppColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.cyberBlue.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.cyberBlue : Colors.white70,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.cyberBlue : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
