// ─── Stats Dashboard Screen ────────────────────────────────────────────────────
//
// Session statistics: distance, speed, alerts breakdown, speed chart.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/stats_provider.dart';
import '../theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      appBar: AppBar(
        title: const Text(
          'SESSION STATS',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.deepSpace,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<StatsProvider>(
        builder: (_, stats, __) {
          final s = stats.currentStats;
          if (s == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No active session',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Duration badge ──────────────────────────────────────────
                Center(
                  child: _GlassBadge(
                    icon: Icons.timer_rounded,
                    label: _formatDuration(s.duration),
                    color: AppColors.cyberBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Key metrics grid ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _MetricCard(
                      label: 'DISTANCE',
                      value: (s.totalDistanceMeters / 1000).toStringAsFixed(2),
                      unit: 'km',
                      icon: Icons.route_rounded,
                      color: AppColors.cyberBlue,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(
                      label: 'MAX SPEED',
                      value: s.maxSpeedKmh.toStringAsFixed(0),
                      unit: 'km/h',
                      icon: Icons.speed_rounded,
                      color: AppColors.neonPurple,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MetricCard(
                      label: 'AVG SPEED',
                      value: s.avgSpeedKmh.toStringAsFixed(0),
                      unit: 'km/h',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.safeGreen,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricCard(
                      label: 'ALERTS',
                      value: '${s.redAlerts + s.yellowAlerts}',
                      unit: 'total',
                      icon: Icons.warning_amber_rounded,
                      color: s.redAlerts > 0 ? AppColors.dangerRed : AppColors.warningAmber,
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Alert breakdown ─────────────────────────────────────────
                _GlassSection(
                  title: 'ALERT BREAKDOWN',
                  child: Column(
                    children: [
                      _AlertBar(
                        label: 'DANGER (RED)',
                        count: s.redAlerts,
                        total: (s.redAlerts + s.yellowAlerts).clamp(1, 999),
                        color: AppColors.dangerRed,
                      ),
                      const SizedBox(height: 12),
                      _AlertBar(
                        label: 'CAUTION (YELLOW)',
                        count: s.yellowAlerts,
                        total: (s.redAlerts + s.yellowAlerts).clamp(1, 999),
                        color: AppColors.warningAmber,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Speed over time chart ────────────────────────────────────
                if (s.speedHistory.length > 2)
                  _GlassSection(
                    title: 'SPEED OVER TIME',
                    child: SizedBox(
                      height: 140,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 30,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.glassBorder,
                              strokeWidth: 0.5,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 30,
                                getTitlesWidget: (v, _) => Text(
                                  '${v.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: s.speedHistory.asMap().entries.map(
                                (e) => FlSpot(e.key.toDouble(), e.value),
                              ).toList(),
                              isCurved: true,
                              color: AppColors.cyberBlue,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.cyberBlue.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _GlassSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.glassWhite,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.07),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
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
}

class _AlertBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;

  const _AlertBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count / total,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
