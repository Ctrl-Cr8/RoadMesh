// ─── Lane Guidance Overlay ──────────────────────────────────────────────────
//
// Matches Image 1: Floating road lane indicator pill [8 ⬆ ⬆] with active lane
// highlighted and traffic light status (🔴🟡🟢).

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LaneGuidanceOverlay extends StatelessWidget {
  final int laneCount;
  final int recommendedLane; // 0-indexed from left
  final bool hasTrafficLight;
  final String? zoneBadge; // e.g., "8" or speed limit

  const LaneGuidanceOverlay({
    super.key,
    this.laneCount = 3,
    this.recommendedLane = 1,
    this.hasTrafficLight = true,
    this.zoneBadge = '8',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Traffic Light Indicator (if active)
        if (hasTrafficLight) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TrafficDot(color: Colors.red, isActive: false),
                SizedBox(height: 2),
                _TrafficDot(color: Colors.amber, isActive: false),
                SizedBox(height: 2),
                _TrafficDot(color: Color(0xFF00E676), isActive: true),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Dark Lane Guidance Capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xE6131822),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional Zone Badge (e.g., Red circle with 8)
              if (zoneBadge != null) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dangerRed,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    zoneBadge!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Lane Arrows
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(laneCount, (index) {
                  final isRecommended = index == recommendedLane;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      index == 0 && laneCount > 2
                          ? Icons.arrow_upward_rounded
                          : Icons.straight_rounded,
                      size: 20,
                      color: isRecommended ? Colors.white : Colors.white38,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrafficDot extends StatelessWidget {
  final Color color;
  final bool isActive;

  const _TrafficDot({required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : color.withValues(alpha: 0.25),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}
