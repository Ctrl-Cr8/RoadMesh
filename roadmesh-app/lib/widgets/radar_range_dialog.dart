// ─── V2X Radar Range Modal Dialog ───────────────────────────────────────────
//
// Clean daylight dialog allowing configuration of direct V2X detection horizon
// from 0m (OFF) to 300m.

import 'package:flutter/material.dart';

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
    _selectedRange = widget.currentRange.toDouble().clamp(0.0, 500.0);
  }

  @override
  Widget build(BuildContext context) {
    final isOff = _selectedRange == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 8),
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
                const Row(
                  children: [
                    Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'V2X DETECTION HORIZON',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    widget.onRangeChanged(_selectedRange.toInt());
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Radius Big Metric Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isOff ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                border: Border.all(
                  color: isOff ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isOff ? 'OFF' : '${_selectedRange.toInt()} METERS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOff
                        ? 'V2X Radar disabled (0m horizon)'
                        : 'Detecting all mesh nodes within ${_selectedRange.toInt()}m',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Quick Presets: 0m, 50m, 100m, 200m, 300m, 500m
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
                _presetButton(500, '500m'),
              ],
            ),

            const SizedBox(height: 18),

            // Slider (0 to 500 meters — matches server NEARBY_RADIUS_METERS)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                inactiveTrackColor: const Color(0xFFE2E8F0),
                thumbColor: isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                overlayColor: (isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB))
                    .withValues(alpha: 0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedRange,
                min: 0,
                max: 500,
                divisions: 20,
                onChanged: (val) {
                  setState(() {
                    _selectedRange = val;
                  });
                  widget.onRangeChanged(val.toInt());
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  boxShadow: [
                    BoxShadow(
                      color: (isOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB))
                          .withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'APPLY RADAR METRIC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetButton(int value, String label) {
    final isSelected = _selectedRange.toInt() == value;
    final isPresetOff = value == 0;

    Color activeColor = isPresetOff ? const Color(0xFFEF4444) : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = value.toDouble();
        });
        widget.onRangeChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
