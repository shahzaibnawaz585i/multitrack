import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Advanced, high-performance animated cosmic aurora backdrop.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({super.key});

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppThemes.auroraBackground,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _AdvancedAuroraPainter(t: _controller.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _AdvancedAuroraPainter extends CustomPainter {
  _AdvancedAuroraPainter({required this.t});

  final double t;

  static final List<_StarData> _stars = _buildStars();

  static List<_StarData> _buildStars() {
    final math.Random random = math.Random(1337);
    return List<_StarData>.generate(96, (int index) {
      return _StarData(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.85,
        radius: 0.6 + random.nextDouble() * 1.5,
        twinkleSpeed: 3.0 + random.nextDouble() * 6.0,
        phaseOffset: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    // 1. Deep Space Atmospheric Gradient
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF030510),
          Color(0xFF070B20),
          Color(0xFF0E132E),
          Color(0xFF060818),
        ],
        stops: <double>[0.0, 0.35, 0.70, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, skyPaint);

    // 2. Pulsing Cosmic Nebulae (Ambient Orbs)
    _drawNebulaOrb(
      canvas,
      Offset(size.width * (0.15 + 0.08 * math.sin(t * math.pi)), size.height * 0.12),
      size.width * 0.55,
      const Color(0xFF00F5D4).withValues(alpha: 0.18 + 0.05 * math.sin(t * math.pi * 2)),
    );
    _drawNebulaOrb(
      canvas,
      Offset(size.width * (0.85 - 0.06 * math.cos(t * math.pi)), size.height * 0.32),
      size.width * 0.60,
      const Color(0xFFFF2F68).withValues(alpha: 0.14 + 0.04 * math.cos(t * math.pi * 2)),
    );
    _drawNebulaOrb(
      canvas,
      Offset(size.width * 0.45, size.height * (0.75 - 0.05 * math.sin(t * math.pi))),
      size.width * 0.65,
      const Color(0xFF9B7DFF).withValues(alpha: 0.16 + 0.05 * math.sin(t * math.pi)),
    );

    // 3. Twinkling Star Field
    _drawStarfield(canvas, size);

    // 4. Layered Liquid Aurora Ribbons (Borealis Curtains)
    _drawAuroraRibbon(
      canvas,
      size,
      yFactor: 0.10,
      amplitude: 34,
      frequency: 2.2,
      phase: t * math.pi * 2,
      topColor: const Color(0xFF00F5D4).withValues(alpha: 0.32),
      bottomColor: const Color(0xFF00F5D4).withValues(alpha: 0.0),
      curtainHeight: 140,
    );
    _drawAuroraRibbon(
      canvas,
      size,
      yFactor: 0.22,
      amplitude: 42,
      frequency: 1.8,
      phase: t * math.pi * 2 + 1.8,
      topColor: const Color(0xFFA78BFA).withValues(alpha: 0.28),
      bottomColor: const Color(0xFFA78BFA).withValues(alpha: 0.0),
      curtainHeight: 160,
    );
    _drawAuroraRibbon(
      canvas,
      size,
      yFactor: 0.35,
      amplitude: 38,
      frequency: 2.6,
      phase: t * math.pi * 2 + 3.4,
      topColor: const Color(0xFFFF2F68).withValues(alpha: 0.22),
      bottomColor: const Color(0xFFFF2F68).withValues(alpha: 0.0),
      curtainHeight: 150,
    );
    _drawAuroraRibbon(
      canvas,
      size,
      yFactor: 0.50,
      amplitude: 30,
      frequency: 2.0,
      phase: t * math.pi * 2 + 4.8,
      topColor: const Color(0xFF00E676).withValues(alpha: 0.18),
      bottomColor: const Color(0xFF00E676).withValues(alpha: 0.0),
      curtainHeight: 130,
    );

    // 5. Shooting Star Effect (Occasional Aurora Ray)
    _drawShootingStar(canvas, size);

    // 6. Deep Outer Space Vignette
    final Paint vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 1.25,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF02030A).withValues(alpha: 0.65),
        ],
        stops: const <double>[0.50, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, vignettePaint);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final Paint starPaint = Paint();
    for (final _StarData star in _stars) {
      final double twinkle = 0.2 +
          0.8 * (0.5 + 0.5 * math.sin((t * star.twinkleSpeed) + star.phaseOffset));
      starPaint.color = Colors.white.withValues(alpha: twinkle * 0.70);

      final Offset pos = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(pos, star.radius, starPaint);

      // Glow halo for brighter stars
      if (star.radius > 1.2) {
        starPaint.color = const Color(0xFF5CE1FF).withValues(alpha: twinkle * 0.25);
        canvas.drawCircle(pos, star.radius * 2.2, starPaint);
      }
    }
  }

  void _drawAuroraRibbon(
    Canvas canvas,
    Size size, {
    required double yFactor,
    required double amplitude,
    required double frequency,
    required double phase,
    required Color topColor,
    required Color bottomColor,
    required double curtainHeight,
  }) {
    final double yBase = size.height * yFactor;
    final Path path = Path()..moveTo(-30, yBase);

    for (double x = -30; x <= size.width + 30; x += 12) {
      final double normX = x / size.width;
      final double wave1 = math.sin(normX * math.pi * frequency + phase);
      final double wave2 = math.cos(normX * math.pi * 1.4 - phase * 0.7);
      final double yPos = yBase + (wave1 + wave2 * 0.5) * amplitude;
      path.lineTo(x, yPos);
    }

    path
      ..lineTo(size.width + 30, yBase + curtainHeight)
      ..lineTo(-30, yBase + curtainHeight)
      ..close();

    final Paint curtainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[topColor, bottomColor],
      ).createShader(Rect.fromLTWH(0, yBase - 40, size.width, curtainHeight + 60));

    canvas.drawPath(path, curtainPaint);
  }

  void _drawShootingStar(Canvas canvas, Size size) {
    final double progress = (t * 2.5) % 1.0;
    if (progress < 0.35) {
      final double p = progress / 0.35;
      final double startX = size.width * 0.7;
      final double startY = size.height * 0.05;
      final double endX = startX - 180 * p;
      final double endY = startY + 110 * p;

      final Paint rayPaint = Paint()
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0xFF00F5D4).withValues(alpha: (1.0 - p) * 0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromPoints(Offset(endX, endY), Offset(startX, startY)));

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  void _drawNebulaOrb(Canvas canvas, Offset center, double radius, Color color) {
    final Paint orbPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _AdvancedAuroraPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _StarData {
  final double x;
  final double y;
  final double radius;
  final double twinkleSpeed;
  final double phaseOffset;

  const _StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinkleSpeed,
    required this.phaseOffset,
  });
}

