// ─── Debug Console Screen ─────────────────────────────────────────────────────
//
// Hidden developer screen (accessible via long-press on status bar).
// Shows live log buffer, server stats, GPS raw data.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driving_provider.dart';
import '../services/app_logger.dart';
import '../theme/app_colors.dart';
import 'package:logger/logger.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.logBuffer.reversed.toList();
    final provider = context.watch<DrivingProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      appBar: AppBar(
        title: const Text(
          'DEBUG CONSOLE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.dangerRed,
          ),
        ),
        backgroundColor: AppColors.deepSpace,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () {
              AppLogger.clearBuffer();
              setState(() {});
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Server stats cards ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _StatChip(
                  label: 'VEHICLE ID',
                  value: provider.vehicleId != null
                      ? '${provider.vehicleId!.substring(0, 8)}...'
                      : 'N/A',
                  color: AppColors.cyberBlue,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'LATENCY',
                  value: '${provider.latencyMs}ms',
                  color: provider.latencyMs < 100 ? AppColors.safeGreen : AppColors.warningAmber,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'NEARBY',
                  value: '${provider.nearbyVehicles.length}',
                  color: AppColors.neonPurple,
                ),
              ],
            ),
          ),

          // ─── GPS data ───────────────────────────────────────────────────────
          if (provider.currentPosition != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.glassWhite,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      'GPS: ${provider.currentPosition!.latitude.toStringAsFixed(6)}, '
                      '${provider.currentPosition!.longitude.toStringAsFixed(6)}  '
                      'Acc: ±${provider.currentPosition!.accuracy.toStringAsFixed(0)}m  '
                      'Alt: ${provider.currentPosition!.altitude.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: AppColors.safeGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ─── Log viewer ─────────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF050810),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No log entries yet',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      itemBuilder: (_, i) {
                        final entry = logs[i];
                        return _LogLine(entry: entry);
                      },
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Action buttons ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'RECONNECT',
                    icon: Icons.refresh_rounded,
                    color: AppColors.cyberBlue,
                    onTap: () => AppLogger.info('Manual reconnect triggered'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;

  const _LogLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      Level.error   => AppColors.dangerRed,
      Level.warning => AppColors.warningAmber,
      Level.info    => AppColors.cyberBlue,
      _             => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')} ',
            style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: AppColors.textMuted),
          ),
          Text(
            '[${entry.levelLabel}] ',
            style: TextStyle(fontFamily: 'Courier', fontSize: 9, color: color, fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(fontFamily: 'Courier', fontSize: 9, color: color.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
