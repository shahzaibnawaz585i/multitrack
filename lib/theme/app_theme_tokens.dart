import 'package:flutter/material.dart';

import 'app_themes.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.containerColor,
    required this.expiredContainerColor,
    this.containerBorderColor,
  });

  final Color containerColor;
  final Color expiredContainerColor;
  final Color? containerBorderColor;

  BoxDecoration containerDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return BoxDecoration(
      color: containerColor,
      borderRadius: borderRadius,
      border: containerBorderColor == null
          ? null
          : Border.all(color: containerBorderColor!),
    );
  }

  @override
  AppThemeTokens copyWith({
    Color? containerColor,
    Color? expiredContainerColor,
    Color? containerBorderColor,
  }) {
    return AppThemeTokens(
      containerColor: containerColor ?? this.containerColor,
      expiredContainerColor:
          expiredContainerColor ?? this.expiredContainerColor,
      containerBorderColor: containerBorderColor ?? this.containerBorderColor,
    );
  }

  @override
  AppThemeTokens lerp(AppThemeTokens? other, double t) {
    if (other == null) {
      return this;
    }

    return AppThemeTokens(
      containerColor: Color.lerp(containerColor, other.containerColor, t)!,
      expiredContainerColor:
          Color.lerp(expiredContainerColor, other.expiredContainerColor, t)!,
      containerBorderColor: Color.lerp(
        containerBorderColor,
        other.containerBorderColor,
        t,
      ),
    );
  }

  static const AppThemeTokens light = AppThemeTokens(
    containerColor: Colors.white,
    expiredContainerColor: Color(0xFF4A4A4A),
  );

  static const AppThemeTokens dark = AppThemeTokens(
    containerColor: AppThemes.darkSurface,
    expiredContainerColor: Color(0xFF4A4A4A),
  );

  static final AppThemeTokens hacking = AppThemeTokens(
    containerColor: AppThemes.hackSurface.withValues(alpha: 0.72),
    expiredContainerColor: const Color(0xFF4A4A4A).withValues(alpha: 0.72),
    containerBorderColor: AppThemes.hackAccent.withValues(alpha: 0.45),
  );
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get appTokens =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppThemeTokens.light;

  Color get containerColor => appTokens.containerColor;

  Color get expiredContainerColor => appTokens.expiredContainerColor;

  BoxDecoration containerDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return appTokens.containerDecoration(borderRadius: borderRadius);
  }

  Color get textColor => Theme.of(this).colorScheme.onSurface;

  Color get mutedTextColor => textColor.withValues(alpha: 0.72);

  Color get labelTextColor => textColor.withValues(alpha: 0.55);

  bool get isHackingTheme => appTokens.containerBorderColor != null;
}
