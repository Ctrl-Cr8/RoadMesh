// ─── Home Screen (Apple / Yandex Light Aesthetic) ───────────────────────────
//
// Matches Image 3 navigation theme:
// - Crisp, bright daytime aesthetic (off-white, soft slate, emerald green)
// - Modern Inter typography
// - Pure white floating cards with soft diffuse shadows
// - Sleek horizontal transport mode selector (matching Image 3 bottom bar)
// - Clean V2X server connection card with rounded preset chips
// - Vibrant emerald green "START DRIVING" button matching the Image 3 "Go!" button
// - Removed: version badge, bulky 8-card grid, and bottom 3 feature boxes

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/driving_provider.dart';
import 'driving_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpLocation();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _warmUpLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        await Geolocator.getLastKnownPosition();
      }
    } catch (_) {}
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
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to connect: $e',
                    style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          // ─── 1. Ambient Light Network Canvas ───────────────────────────
          AnimatedBuilder(
            animation: _meshController,
            builder: (_, __) => CustomPaint(
              painter: _LightMeshPainter(_meshController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // ─── 2. Main Content ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildServerInput(),
                  const SizedBox(height: 32),
                  _buildStartButton(),
                  const SizedBox(height: 28),
                  _buildFooterTrustBadge(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header: Modern Beacon & Clean Inter Typography ─────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Pulsing Emerald / Teal Beacon Orb
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _glowAnim]),
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer diffuse emerald aura
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: _glowAnim.value * 0.20),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Core beacon circle
                Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00E676)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Brand Title in clean Inter
        const Text(
          'ROADMESH',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'COOPERATIVE VEHICLE AWARENESS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  // ─── Server Input Card: Clean & Modern ──────────────────────────────────────

  Widget _buildServerInput() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'V2X SERVER CONNECTION',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _serverController,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: Icon(
                  Icons.dns_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                hintText: 'ws://127.0.0.1:3000/ws',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: isCurrent ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: isCurrent ? const Color(0xFF00C853) : const Color(0xFFE2E8F0),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? const Color(0xFF00C853) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ─── Start Button: Emerald Green "Go!" Style matching Image 3 ───────────────

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF00C853),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withValues(alpha: 0.35 + (_glowAnim.value * 0.15)),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              onTap: _startDriving,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'START DRIVING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Minimal Trust Footer ───────────────────────────────────────────────────

  Widget _buildFooterTrustBadge() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 14, color: Color(0xFF94A3B8)),
          SizedBox(width: 6),
          Text(
            'Autonomous Peer-to-Peer V2X Mesh Network',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Clean White Card matching Image 3 ───────────────────────────────

class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Subtle Light Mesh Canvas Background ──────────────────────────────────────

class _LightMeshPainter extends CustomPainter {
  final double t;

  _LightMeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _generateNodes(size);
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke;

    // Draw subtle connections between nearby nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dx = nodes[i].dx - nodes[j].dx;
        final dy = nodes[i].dy - nodes[j].dy;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 150) {
          final opacity = (1 - dist / 150) * 0.07;
          linePaint
            ..color = const Color(0xFF00C853).withValues(alpha: opacity)
            ..strokeWidth = 0.6;
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw soft nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodeT = (t + i * 0.07) % 1.0;
      final nodeOpacity = 0.2 + 0.3 * math.sin(nodeT * math.pi * 2).abs();
      paint.color = const Color(0xFF00C853).withValues(alpha: nodeOpacity * 0.4);
      canvas.drawCircle(nodes[i], 1.4, paint);
    }
  }

  List<Offset> _generateNodes(Size size) {
    final rng = math.Random(42);
    return List.generate(24, (i) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final wobbleX = math.sin((t + i * 0.17) * math.pi * 2) * 10;
      final wobbleY = math.cos((t + i * 0.23) * math.pi * 2) * 6;
      return Offset(baseX + wobbleX, baseY + wobbleY);
    });
  }

  @override
  bool shouldRepaint(covariant _LightMeshPainter old) => old.t != t;
}
