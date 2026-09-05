// ─── Destination Picker Sheet ─────────────────────────────────────────────────
//
// Universal Google Maps destination picker:
// - Live search anywhere in the world (streets, junctions, shops, hospitals, cities)
// - Google Maps-style quick category filters (Fuel, Hospital, Parking, Food, College)
// - Proximity distance badges and real-time place suggestions

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../navigation/navigation_route.dart';
import '../navigation/route_service.dart';
import '../theme/app_colors.dart';

class DestinationPickerSheet extends StatefulWidget {
  final ValueChanged<NavDestination> onDestinationSelected;
  final LatLng? userLocation;

  const DestinationPickerSheet({
    super.key,
    required this.onDestinationSelected,
    this.userLocation,
  });

  @override
  State<DestinationPickerSheet> createState() => _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<DestinationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<NavDestination> _destinations = RouteService.predefinedDestinations;
  bool _isLoading = false;
  Timer? _debounceTimer;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _quickCategories = [
    {'label': 'Fuel / Petrol', 'query': 'petrol pump', 'icon': Icons.local_gas_station_rounded},
    {'label': 'Hospitals', 'query': 'hospital', 'icon': Icons.local_hospital_rounded},
    {'label': 'Parking', 'query': 'parking', 'icon': Icons.local_parking_rounded},
    {'label': 'Food & Cafe', 'query': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'label': 'Colleges', 'query': 'college', 'icon': Icons.school_rounded},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _selectedCategory = null;
        _destinations = RouteService.predefinedDestinations;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await RouteService.searchPlaces(
        query,
        proximity: widget.userLocation,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _destinations = results;
        });
      }
    });
  }

  void _selectCategory(Map<String, dynamic> cat) {
    final query = cat['query'] as String;
    setState(() {
      _selectedCategory = cat['label'] as String;
      _searchController.text = query;
      _isLoading = true;
    });

    _debounceTimer?.cancel();
    RouteService.searchPlaces(query, proximity: widget.userLocation).then((results) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _destinations = results;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF090E1A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.glassBorder),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.cyberBlue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'NAVIGATE ANYWHERE',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.place_rounded, color: AppColors.cyberBlue, size: 20),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cyberBlue,
                              ),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                child: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              )
                            : null),
                    hintText: 'Search any address, city, junction, landmark...',
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Category Shortcuts
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final cat = _quickCategories[idx];
                    final isSelected = _selectedCategory == cat['label'];

                    return GestureDetector(
                      onTap: () => _selectCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isSelected
                              ? AppColors.cyberBlue.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: isSelected ? AppColors.cyberBlue : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 14,
                              color: isSelected ? AppColors.cyberBlue : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.cyberBlue : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Destination List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: _destinations.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No locations found. Try a different query.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final dest = _destinations[idx];
                          final prox = dest.formattedProximity;

                          return GestureDetector(
                            onTap: () {
                              widget.onDestinationSelected(dest);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.03),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.cyberBlue.withValues(alpha: 0.15),
                                    ),
                                    child: Icon(dest.icon, color: AppColors.cyberBlue, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dest.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dest.subtitle,
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
                                  if (prox != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: AppColors.cyberBlue.withValues(alpha: 0.15),
                                        border: Border.all(
                                          color: AppColors.cyberBlue.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        prox,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.cyberBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.navigation_rounded,
                                    color: AppColors.cyberBlue,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
