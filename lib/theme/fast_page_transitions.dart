import 'package:flutter/material.dart';

/// Short fade + slide — feels instant but not abrupt.
class FastPageTransitionsBuilder extends PageTransitionsBuilder {
  const FastPageTransitionsBuilder();

  static const Duration kTransitionDuration = Duration(milliseconds: 200);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.88, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Push with the same ~200ms transition as [MaterialApp] theme.
class FastMaterialPageRoute<T> extends MaterialPageRoute<T> {
  FastMaterialPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => FastPageTransitionsBuilder.kTransitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      FastPageTransitionsBuilder.kTransitionDuration;
}

/// Near-instant push — detail opens on first frame after tap.
class InstantMaterialPageRoute<T> extends MaterialPageRoute<T> {
  InstantMaterialPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  static const Duration kOpenDuration = Duration(milliseconds: 1);

  @override
  Duration get transitionDuration => kOpenDuration;

  @override
  Duration get reverseTransitionDuration => kOpenDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
