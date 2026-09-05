// ─── Home Screen ─────────────────────────────────────────────────────────────
//
// Premium dark landing screen with:
// - Animated mesh particle background
// - Glassmorphism cards
// - Orbitron-font logo with neon glow
// - Animated vehicle type selector
// - Glassmorphic server input
// - Pulsing gradient CTA button

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driving_provider.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import 'driving_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _serverController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _meshController;
  late AnimationController _glowController;

  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _serverController.text = 'ws://127.0.0.1:3000/ws';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _pulseController.dispose();
    _meshController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startDriving() async {
    final provider = context.read<DrivingProvider>();
    provider.serverUrl = _serverController.text.trim();

    try {
      await provider.startDriving();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DrivingScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to connect: $e', style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.dangerRed, width: 0.5),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: Stack(
        children: [
          // ─── Animated mesh background ─────────────────────────────────────
          AnimatedBuilder(
            animation: _meshController,
            builder: (_, __) => CustomPaint(
              painter: _MeshPainter(_meshController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // ─── Gradient overlay ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC070B14),
                  Color(0x88070B14),
                  Color(0xDD070B14),
                ],
              ),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildVehicleSelector(),
                  const SizedBox(height: 28),
                  _buildServerInput(),
                  const SizedBox(height: 40),
                  _buildStartButton(),
                  const SizedBox(height: 32),
                  _buildFeatureRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated logo orb
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _glowAnim]),
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyberBlue.withValues(alpha: _glowAnim.value * 0.25),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Logo circle
                Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.cyberBlue, AppColors.hyperBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberBlue.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Title with neon glow text shadow
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'ROADMESH',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        const Text(
          'COOPERATIVE VEHICLE AWARENESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 20),

        // Version badge
        _GlassChip(label: 'v1.0.0 · REAL-TIME · ANONYMOUS'),
      ],
    );
  }

  // ─── Vehicle Selector ──────────────────────────────────────────────────────

  Widget _buildVehicleSelector() {
    return _GlassCard(
      child: Consumer<DrivingProvider>(
        builder: (_, provider, __) {
          final types = VehicleType.values.where((t) => t != VehicleType.unknown).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('VEHICLE TELEMETRY PROFILE'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyberBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cyberBlue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${provider.vehicleType.icon} ${provider.vehicleType.label}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyberBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: types.length,
                itemBuilder: (ctx, idx) {
                  final type = types[idx];
                  final isSelected = provider.vehicleType == type;
                  return _VehicleCard(
                    type: type,
                    isSelected: isSelected,
                    onTap: () => provider.vehicleType = type,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Server Input ──────────────────────────────────────────────────────────

  Widget _buildServerInput() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('SERVER CONNECTION'),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x0AFFFFFF),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: _serverController,
              style: const TextStyle(
                color: AppColors.cyberBlue,
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                prefixIcon: Icon(
                  Icons.dns_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                hintText: 'ws://server:3000/ws',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontFamily: 'Courier',
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _presetChip('🔌 USB (127.0.0.1)', 'ws://127.0.0.1:3000/ws'),
              _presetChip('📱 Emulator (10.0.2.2)', 'ws://10.0.2.2:3000/ws'),
              _presetChip('🌐 Wi-Fi (10.210.147.50)', 'ws://10.210.147.50:3000/ws'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String url) {
    final isCurrent = _serverController.text == url;
    return GestureDetector(
      onTap: () {
        setState(() {
          _serverController.text = url;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCurrent
              ? AppColors.cyberBlue.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isCurrent
                ? AppColors.cyberBlue.withValues(alpha: 0.6)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? AppColors.cyberBlue : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ─── Start Button ──────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) {
        return GestureDetector(
          onTap: _startDriving,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppColors.cyberBlue, AppColors.hyperBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyberBlue.withValues(alpha: _glowAnim.value * 0.5),
                  blurRadius: 30,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.transparent,
                onTap: _startDriving,
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'START DRIVING',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Feature Row ───────────────────────────────────────────────────────────

  Widget _buildFeatureRow() {
    return Row(
      children: [
        _FeatureChip(Icons.shield_outlined, 'Anonymous'),
        const SizedBox(width: 10),
        _FeatureChip(Icons.bolt_rounded, 'Real-Time'),
        const SizedBox(width: 10),
        _FeatureChip(Icons.warning_amber_rounded, 'Collision AI'),
      ],
    );
  }
}

// ─── Subwidgets ────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.glassWhite,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;

  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: AppColors.glassBlue,
            border: Border.all(
              color: AppColors.cyberBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.cyberBlue,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.cyberBlue.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isSelected ? AppColors.cyberBlue : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyberBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.cyberBlue.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              alignment: Alignment.center,
              child: Text(type.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.categorySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? AppColors.cyberBlue : AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.glassWhite,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.cyberBlue, size: 20),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mesh Particle Background Painter ─────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  final double t;

  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _generateNodes(size);
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke;

    // Draw connections between nearby nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dx = nodes[i].dx - nodes[j].dx;
        final dy = nodes[i].dy - nodes[j].dy;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 160) {
          final opacity = (1 - dist / 160) * 0.12;
          linePaint
            ..color = AppColors.cyberBlue.withValues(alpha: opacity)
            ..strokeWidth = 0.5;
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodeT = (t + i * 0.07) % 1.0;
      final nodeOpacity = 0.3 + 0.4 * math.sin(nodeT * math.pi * 2).abs();
      paint.color = AppColors.cyberBlue.withValues(alpha: nodeOpacity * 0.6);
      canvas.drawCircle(nodes[i], 1.5, paint);
    }
  }

  List<Offset> _generateNodes(Size size) {
    final rng = math.Random(42); // Fixed seed for stable layout
    return List.generate(28, (i) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final wobbleX = math.sin((t + i * 0.17) * math.pi * 2) * 12;
      final wobbleY = math.cos((t + i * 0.23) * math.pi * 2) * 8;
      return Offset(baseX + wobbleX, baseY + wobbleY);
    });
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.t != t;
}
