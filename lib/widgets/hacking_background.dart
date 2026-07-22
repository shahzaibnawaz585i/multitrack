import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class HackingBackground extends StatefulWidget {
  final Widget child;

  const HackingBackground({super.key, required this.child});

  @override
  State<HackingBackground> createState() => _HackingBackgroundState();
}

class _HackingBackgroundState extends State<HackingBackground>
    with SingleTickerProviderStateMixin {
  static const String _matrixChars =
      '01アイウエオカキク01010101<>[]//\\\\ACCESSROOTSHELL';

  late final AnimationController _controller;
  final Random _random = Random(7);
  List<_MatrixColumn>? _columns;
  Size? _cachedSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_MatrixColumn> _columnsForSize(Size size) {
    if (_columns != null && _cachedSize == size) {
      return _columns!;
    }

    _cachedSize = size;
    final int count = (size.width / 16).ceil().clamp(14, 48);

    _columns = List<_MatrixColumn>.generate(count, (index) {
      final double x = index * (size.width / count);
      return _MatrixColumn(
        x: x + _random.nextDouble() * 6,
        speed: 0.04 + _random.nextDouble() * 0.08,
        offset: _random.nextDouble(),
        chars: List<String>.generate(
          18 + _random.nextInt(14),
          (_) => _matrixChars[_random.nextInt(_matrixChars.length)],
        ),
        headBrightness: 0.55 + _random.nextDouble() * 0.45,
      );
    });

    return _columns!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final Size size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return CustomPaint(
                  size: size,
                  painter: _MatrixBackgroundPainter(
                    progress: _controller.value,
                    columns: _columnsForSize(size),
                    size: size,
                  ),
                );
              },
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: [
                AppThemes.hackVoid.withValues(alpha: 0.05),
                AppThemes.hackVoid.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MatrixColumn {
  final double x;
  final double speed;
  final double offset;
  final List<String> chars;
  final double headBrightness;

  const _MatrixColumn({
    required this.x,
    required this.speed,
    required this.offset,
    required this.chars,
    required this.headBrightness,
  });
}

class _MatrixBackgroundPainter extends CustomPainter {
  final double progress;
  final List<_MatrixColumn> columns;
  final Size size;

  _MatrixBackgroundPainter({
    required this.progress,
    required this.columns,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Rect fullRect = Offset.zero & canvasSize;

    canvas.drawRect(fullRect, Paint()..color = AppThemes.hackVoid);

    _drawGrid(canvas, canvasSize);
    _drawMatrix(canvas, canvasSize);
    _drawScanline(canvas, canvasSize);
    _drawHud(canvas, canvasSize);
    _drawStatusStrip(canvas, canvasSize);
  }

  void _drawGrid(Canvas canvas, Size canvasSize) {
    final Paint gridPaint = Paint()
      ..color = AppThemes.hackNeon.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    const double step = 28;

    for (double x = 0; x < canvasSize.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, canvasSize.height), gridPaint);
    }

    for (double y = 0; y < canvasSize.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(canvasSize.width, y), gridPaint);
    }
  }

  void _drawMatrix(Canvas canvas, Size canvasSize) {
    const TextStyle charStyle = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 13,
      height: 1.1,
    );

    for (final _MatrixColumn column in columns) {
      final double headY =
          ((progress * column.speed * 6 + column.offset) % 1.2) *
              (canvasSize.height + 220) -
          120;

      for (int i = 0; i < column.chars.length; i++) {
        final double y = headY - (i * 16);
        if (y < -20 || y > canvasSize.height + 20) {
          continue;
        }

        final double fade = (1 - (i / column.chars.length)).clamp(0.0, 1.0);
        final double alpha = i == 0
            ? column.headBrightness
            : (0.08 + fade * 0.28);

        final TextPainter painter = TextPainter(
          text: TextSpan(
            text: column.chars[i],
            style: charStyle.copyWith(
              color: i == 0
                  ? AppThemes.hackNeonBright.withValues(alpha: alpha)
                  : AppThemes.hackNeon.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, Offset(column.x, y));
      }
    }
  }

  void _drawScanline(Canvas canvas, Size canvasSize) {
    final double y = progress * canvasSize.height;
    final Paint scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppThemes.hackNeon.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 24, canvasSize.width, 48));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 24, canvasSize.width, 48),
      scanPaint,
    );
  }

  void _drawHud(Canvas canvas, Size canvasSize) {
    final Paint hudPaint = Paint()
      ..color = AppThemes.hackNeonBright.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const double len = 28;
    const double inset = 10;

    _corner(canvas, hudPaint, inset, inset, len, top: true, left: true);
    _corner(
      canvas,
      hudPaint,
      canvasSize.width - inset,
      inset,
      len,
      top: true,
      left: false,
    );
    _corner(
      canvas,
      hudPaint,
      inset,
      canvasSize.height - inset,
      len,
      top: false,
      left: true,
    );
    _corner(
      canvas,
      hudPaint,
      canvasSize.width - inset,
      canvasSize.height - inset,
      len,
      top: false,
      left: false,
    );
  }

  void _corner(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double len, {
    required bool top,
    required bool left,
  }) {
    final double xDir = left ? 1 : -1;
    final double yDir = top ? 1 : -1;

    canvas.drawLine(Offset(x, y), Offset(x + len * xDir, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + len * yDir), paint);
  }

  void _drawStatusStrip(Canvas canvas, Size canvasSize) {
    const TextStyle style = TextStyle(
      fontFamily: 'NumberFonts',
      fontSize: 11,
      letterSpacing: 1.2,
    );

    final String banner =
        '[ HACKING MODE ACTIVE ]  root@multitrack  //  shell:live  //  trace:disabled';

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: banner,
        style: style.copyWith(
          color: AppThemes.hackCyan.withValues(alpha: 0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasSize.width - 24);

    painter.paint(canvas, const Offset(12, 8));

    final TextPainter watermark = TextPainter(
      text: TextSpan(
        text: 'MATRIX LINK ESTABLISHED',
        style: style.copyWith(
          fontSize: 22,
          letterSpacing: 4,
          color: AppThemes.hackNeon.withValues(alpha: 0.06),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    watermark.paint(
      canvas,
      Offset(
        (canvasSize.width - watermark.width) / 2,
        canvasSize.height * 0.42,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MatrixBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.size != size ||
        oldDelegate.columns != columns;
  }
}
