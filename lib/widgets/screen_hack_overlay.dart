import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

/// Foreground overlay — screen par live hacking / intrusion feel.
class ScreenHackOverlay extends StatefulWidget {
  final Widget child;

  const ScreenHackOverlay({super.key, required this.child});

  @override
  State<ScreenHackOverlay> createState() => _ScreenHackOverlayState();
}

class _ScreenHackOverlayState extends State<ScreenHackOverlay>
    with TickerProviderStateMixin {
  static const List<String> _commands = [
    '> inject_payload --force',
    '> bypass_firewall OK',
    '> dump_memory 0x7FA2',
    '> decrypt_stream ████░░',
    '> uplink stable...',
    '> root access gained',
  ];

  late final AnimationController _pulseController;
  late final AnimationController _glitchController;
  late final AnimationController _typeController;
  final Random _random = Random(11);

  int _commandIndex = 0;
  int _typedChars = 0;
  double _glitchY = 0.3;
  double _glitchHeight = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    )..addListener(() {
        if (_glitchController.isCompleted) {
          _glitchHeight = 0;
        }
      });

    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _typeController.forward(from: 0);
          if (_typedChars >= _commands[_commandIndex].length) {
            _typedChars = 0;
            _commandIndex = (_commandIndex + 1) % _commands.length;
          } else {
            _typedChars++;
          }
        }
      });

    _typeController.forward();
    _scheduleGlitch();
  }

  void _scheduleGlitch() {
    Future<void>.delayed(
      Duration(milliseconds: 900 + _random.nextInt(2200)),
      () {
        if (!mounted) {
          return;
        }
        _glitchY = _random.nextDouble() * 0.85;
        _glitchHeight = 8 + _random.nextDouble() * 28;
        _glitchController.forward(from: 0);
        _scheduleGlitch();
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseController,
              _glitchController,
              _typeController,
            ]),
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ScreenHackPainter(
                      pulse: _pulseController.value,
                      glitchProgress: _glitchController.value,
                      glitchY: _glitchY,
                      glitchHeight: _glitchHeight * (1 - _glitchController.value),
                      typedCommand: _commands[_commandIndex]
                          .substring(0, _typedChars.clamp(0, 999)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScreenHackPainter extends CustomPainter {
  final double pulse;
  final double glitchProgress;
  final double glitchY;
  final double glitchHeight;
  final String typedCommand;

  _ScreenHackPainter({
    required this.pulse,
    required this.glitchProgress,
    required this.glitchY,
    required this.glitchHeight,
    required this.typedCommand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawScanlines(canvas, size);
    _drawVignette(canvas, size);
    _drawGlitchBar(canvas, size);
    _drawCrosshair(canvas, size);
    _drawLiveBadge(canvas, size, pulse);
    _drawSideCode(canvas, size);
    _drawBottomTerminal(canvas, size);
    _drawCornerAlerts(canvas, size, pulse);
  }

  void _drawScanlines(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = AppThemes.hackNeon.withValues(alpha: 0.045);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final Paint vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppThemes.hackVoid.withValues(alpha: 0.15),
          AppThemes.hackVoid.withValues(alpha: 0.45),
        ],
        stops: const [0.55, 0.85, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawGlitchBar(Canvas canvas, Size size) {
    if (glitchHeight <= 0) {
      return;
    }

    final double y = glitchY * size.height;
    final Rect bar = Rect.fromLTWH(0, y, size.width, glitchHeight);

    canvas.drawRect(
      bar,
      Paint()..color = AppThemes.hackNeonBright.withValues(alpha: 0.12),
    );
    canvas.drawRect(
      bar.shift(const Offset(3, 0)),
      Paint()..color = AppThemes.hackCyan.withValues(alpha: 0.08),
    );
    canvas.drawRect(
      bar.shift(const Offset(-2, 0)),
      Paint()..color = const Color(0xFFFF0040).withValues(alpha: 0.06),
    );
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final Paint paint = Paint()
      ..color = AppThemes.hackNeon.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const double arm = 18;
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm),
      Offset(center.dx, center.dy + arm),
      paint,
    );
    canvas.drawCircle(center, 6, paint);
  }

  void _drawLiveBadge(Canvas canvas, Size size, double pulseValue) {
    const TextStyle labelStyle = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 11,
      letterSpacing: 1.1,
    );

    final double alpha = 0.55 + pulseValue * 0.45;
    final Offset badgeOrigin = Offset(size.width - 152, 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeOrigin.dx, badgeOrigin.dy, 140, 24),
        const Radius.circular(4),
      ),
      Paint()
        ..color = const Color(0xFFFF0033).withValues(alpha: 0.18 + pulseValue * 0.12),
    );

    canvas.drawCircle(
      Offset(badgeOrigin.dx + 10, badgeOrigin.dy + 12),
      4,
      Paint()..color = Color.lerp(
            const Color(0xFFFF0033),
            AppThemes.hackNeonBright,
            pulseValue,
          )!,
    );

    final TextPainter liveText = TextPainter(
      text: TextSpan(
        text: 'LIVE INTRUSION',
        style: labelStyle.copyWith(
          color: const Color(0xFFFF3355).withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    liveText.paint(canvas, Offset(badgeOrigin.dx + 20, badgeOrigin.dy + 5));
  }

  void _drawSideCode(Canvas canvas, Size size) {
    const TextStyle style = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 9,
      height: 1.15,
    );

    final String column = List.generate(
      28,
      (i) => '${(i * 17).toRadixString(16).padLeft(2, '0')} '
          '${(i * 3).toRadixString(2).padLeft(8, '0')}',
    ).join('\n');

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: column,
        style: style.copyWith(
          color: AppThemes.hackNeon.withValues(alpha: 0.14),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 70);

    painter.paint(canvas, Offset(6, size.height * 0.18));
  }

  void _drawBottomTerminal(Canvas canvas, Size size) {
    const TextStyle style = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 12,
      letterSpacing: 0.6,
    );

    final Rect panel = Rect.fromLTWH(
      0,
      size.height - 56,
      size.width,
      56,
    );

    canvas.drawRect(
      panel,
      Paint()..color = AppThemes.hackVoid.withValues(alpha: 0.72),
    );
    canvas.drawLine(
      Offset(0, panel.top),
      Offset(size.width, panel.top),
      Paint()
        ..color = AppThemes.hackNeon.withValues(alpha: 0.45)
        ..strokeWidth = 1,
    );

    final String line = '$typedCommand▌';

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: line,
        style: style.copyWith(color: AppThemes.hackNeonBright.withValues(alpha: 0.85)),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);

    painter.paint(canvas, Offset(12, size.height - 38));

    final TextPainter hint = TextPainter(
      text: TextSpan(
        text: 'screen hack active // packets intercepted',
        style: style.copyWith(
          fontSize: 10,
          color: AppThemes.hackCyan.withValues(alpha: 0.45),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    hint.paint(canvas, Offset(size.width - hint.width - 12, size.height - 20));
  }

  void _drawCornerAlerts(Canvas canvas, Size size, double pulseValue) {
    const TextStyle style = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 10,
      letterSpacing: 0.8,
    );

    final TextPainter topLeft = TextPainter(
      text: TextSpan(
        text: '!! SYSTEM COMPROMISED !!',
        style: style.copyWith(
          color: AppThemes.hackAmber.withValues(alpha: 0.35 + pulseValue * 0.2),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    topLeft.paint(canvas, Offset(12, 40));

    final TextPainter topRight = TextPainter(
      text: TextSpan(
        text: 'TRACE: HIDDEN',
        style: style.copyWith(
          color: AppThemes.hackCyan.withValues(alpha: 0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    topRight.paint(
      canvas,
      Offset(size.width - topRight.width - 12, 40),
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenHackPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.glitchProgress != glitchProgress ||
        oldDelegate.glitchY != glitchY ||
        oldDelegate.glitchHeight != glitchHeight ||
        oldDelegate.typedCommand != typedCommand;
  }
}
