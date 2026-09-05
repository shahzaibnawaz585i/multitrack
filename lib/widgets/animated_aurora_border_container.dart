import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A widget that wraps content with a continuously rotating multi-color
/// neon gradient border (Cyan, Violet, Pink, Emerald) and rounded corners for Aurora Theme.
class AnimatedAuroraBorderContainer extends StatefulWidget {
  const AnimatedAuroraBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.borderWidth = 2.0,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showGlow = true,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showGlow;

  @override
  State<AnimatedAuroraBorderContainer> createState() =>
      _AnimatedAuroraBorderContainerState();
}

class _AnimatedAuroraBorderContainerState
    extends State<AnimatedAuroraBorderContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color fillBg =
        widget.backgroundColor ?? const Color(0xFF12172E).withValues(alpha: 0.88);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double angle = _controller.value * math.pi * 2;

        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.showGlow
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.20),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: CustomPaint(
            painter: _AuroraGradientBorderPainter(
              angle: angle,
              borderWidth: widget.borderWidth,
              borderRadius: widget.borderRadius,
            ),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fillBg,
                borderRadius: BorderRadius.circular(
                  math.max(0, widget.borderRadius - widget.borderWidth),
                ),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _AuroraGradientBorderPainter extends CustomPainter {
  _AuroraGradientBorderPainter({
    required this.angle,
    required this.borderWidth,
    required this.borderRadius,
  });

  final double angle;
  final double borderWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = SweepGradient(
        center: Alignment.center,
        transform: GradientRotation(angle),
        colors: const <Color>[
          Color(0xFF00F5D4), // Neon Cyan
          Color(0xFFA78BFA), // Aurora Violet
          Color(0xFFFF2F68), // Electric Pink
          Color(0xFF00E676), // Emerald Glow
          Color(0xFF00F5D4), // Wrap back to Neon Cyan
        ],
        stops: const <double>[0.0, 0.28, 0.55, 0.80, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraGradientBorderPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
