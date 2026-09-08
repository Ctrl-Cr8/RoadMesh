// ─── Map Layer & Display Controls Sheet ───────────────────────────────────────
//
// Clean daylight modal sheet allowing drivers to configure map styles, toggle live traffic,
// and switch 2D/3D perspective camera angles.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers_rounded, color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'MAP DISPLAY & LAYERS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
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
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 16),

            // Live Traffic Toggle
            SwitchListTile(
              value: isTrafficEnabled,
              onChanged: onTrafficToggled,
              contentPadding: EdgeInsets.zero,
              activeTrackColor: const Color(0xFF2563EB),
              activeColor: Colors.white,
              title: const Text(
                'Live Traffic Congestion',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: const Text(
                'Color-coded real-time road congestion overlay',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTrafficEnabled
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.traffic_rounded,
                  color: isTrafficEnabled ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),

            // 3D Perspective Tilt Toggle
            SwitchListTile(
              value: is3DMode,
              onChanged: on3DModeToggled,
              contentPadding: EdgeInsets.zero,
              activeTrackColor: const Color(0xFF2563EB),
              activeColor: Colors.white,
              title: const Text(
                '3D Perspective Cockpit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                is3DMode
                    ? '35° dynamic tilted camera following vehicle heading'
                    : '0° flat 2D top-down view',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: is3DMode
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.view_in_ar_rounded,
                  color: is3DMode ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF8FAFC),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
