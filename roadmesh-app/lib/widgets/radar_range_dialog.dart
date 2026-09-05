// ─── V2X Radar Range Modal Dialog ───────────────────────────────────────────
//
// Allows configuring the direct V2X detection horizon from 0m (OFF) to 300m.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RadarRangeDialog extends StatefulWidget {
  final int currentRange;
  final ValueChanged<int> onRangeChanged;

  const RadarRangeDialog({
    super.key,
    required this.currentRange,
    required this.onRangeChanged,
  });

  @override
  State<RadarRangeDialog> createState() => _RadarRangeDialogState();
}

class _RadarRangeDialogState extends State<RadarRangeDialog> {
  late double _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.currentRange.toDouble().clamp(0.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final isOff = _selectedRange == 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1526).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOff
                  ? AppColors.dangerRed.withValues(alpha: 0.5)
                  : AppColors.cyberBlue.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isOff
                    ? AppColors.dangerRed.withValues(alpha: 0.2)
                    : AppColors.cyberBlue.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'V2X DETECTION METRIC',
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

              // Radius Big Metric Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isOff
                      ? AppColors.dangerRed.withValues(alpha: 0.12)
                      : AppColors.cyberBlue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: isOff
                        ? AppColors.dangerRed.withValues(alpha: 0.4)
                        : AppColors.cyberBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isOff ? 'OFF' : '${_selectedRange.toInt()} METERS',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isOff ? AppColors.dangerRed : AppColors.cyberBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOff
                          ? 'V2X Radar disabled (0m horizon)'
                          : 'Detecting all mesh nodes within ${_selectedRange.toInt()}m',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _presetButton(0, '0m (OFF)'),
                  _presetButton(50, '50m'),
                  _presetButton(100, '100m'),
                  _presetButton(200, '200m'),
                  _presetButton(300, '300m'),
                ],
              ),

              const SizedBox(height: 20),

              // Slider (0 to 300 meters)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: isOff ? AppColors.dangerRed : AppColors.cyberBlue,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: isOff ? AppColors.dangerRed : AppColors.cyberBlue,
                  overlayColor: (isOff ? AppColors.dangerRed : AppColors.cyberBlue)
                      .withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _selectedRange,
                  min: 0,
                  max: 300,
                  divisions: 12,
                  onChanged: (val) {
                    setState(() {
                      _selectedRange = val;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Button
              GestureDetector(
                onTap: () {
                  widget.onRangeChanged(_selectedRange.toInt());
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isOff
                        ? AppColors.dangerGradient
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isOff ? AppColors.dangerRed : AppColors.cyberBlue)
                            .withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'APPLY RADAR METRIC',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetButton(int value, String label) {
    final isSelected = _selectedRange.toInt() == value;
    final isPresetOff = value == 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = value.toDouble();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? (isPresetOff
                  ? AppColors.dangerRed.withValues(alpha: 0.2)
                  : AppColors.cyberBlue.withValues(alpha: 0.2))
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? (isPresetOff ? AppColors.dangerRed : AppColors.cyberBlue)
                : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isPresetOff ? AppColors.dangerRed : AppColors.cyberBlue)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
