// ─── Geoposition Share Banner ────────────────────────────────────────────────
//
// Matches Image 1: Top floating card prompting:
// "Send your geoposition to friends in real time"
// "Share geoposition" in vibrant green with wireless radar wave icon.

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';

class GeopositionShareBanner extends StatefulWidget {
  final bool isDark;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onDismiss;
  final VoidCallback? onShare;

  const GeopositionShareBanner({
    super.key,
    this.isDark = false,
    this.latitude,
    this.longitude,
    this.onDismiss,
    this.onShare,
  });

  @override
  State<GeopositionShareBanner> createState() => _GeopositionShareBannerState();
}

class _GeopositionShareBannerState extends State<GeopositionShareBanner> {
  bool _isShared = false;

  void _handleShare() {
    if (widget.onShare != null) {
      widget.onShare!();
      setState(() => _isShared = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isShared = false);
      });
      return;
    }

    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat != null && lng != null) {
      final googleUrl = 'https://maps.google.com/?q=$lat,$lng';
      // ignore: deprecated_member_use
      Share.share(
        '📍 My real-time RoadMesh location:\n$googleUrl',
        subject: 'RoadMesh Live Geoposition',
      );
      setState(() => _isShared = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isShared = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xEE131C2E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.navTextDark;
    final borderColor = widget.isDark ? Colors.white12 : AppColors.navBorderLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: widget.isDark ? AppColors.floatingPillShadowDark : AppColors.floatingPillShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send your geoposition to friends in real time',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _handleShare,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isShared ? 'Shared!' : 'Share geoposition',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navRouteGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.navRouteGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Radar Share Icon Button
          GestureDetector(
            onTap: _handleShare,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              child: const Icon(
                Icons.wifi_tethering_rounded,
                size: 20,
                color: AppColors.navTextDark,
              ),
            ),
          ),
          if (widget.onDismiss != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: widget.isDark ? Colors.white54 : AppColors.navTextMutedLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
