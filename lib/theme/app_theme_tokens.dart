import 'package:flutter/material.dart';

import 'app_themes.dart';
import 'aurora_map_style.dart';
import 'hacking_map_style.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.containerColor,
    required this.expiredContainerColor,
    required this.fieldFillColor,
    this.containerBorderColor,
    this.isHacking = false,
    this.isAurora = false,
  });

  final Color containerColor;
  final Color expiredContainerColor;
  final Color fieldFillColor;
  final Color? containerBorderColor;
  final bool isHacking;
  final bool isAurora;

  BoxDecoration containerDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return BoxDecoration(
      color: containerColor,
      borderRadius: borderRadius,
      border: containerBorderColor == null
          ? null
          : Border.all(color: containerBorderColor!, width: isAurora ? 1.2 : 1),
      boxShadow: containerBorderColor == null
          ? null
          : isAurora
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppThemes.auroraGlowCyan.withValues(alpha: 0.22),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppThemes.pinkAccent.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: containerBorderColor!.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
    );
  }

  @override
  AppThemeTokens copyWith({
    Color? containerColor,
    Color? expiredContainerColor,
    Color? fieldFillColor,
    Color? containerBorderColor,
    bool? isHacking,
    bool? isAurora,
  }) {
    return AppThemeTokens(
      containerColor: containerColor ?? this.containerColor,
      expiredContainerColor:
          expiredContainerColor ?? this.expiredContainerColor,
      fieldFillColor: fieldFillColor ?? this.fieldFillColor,
      containerBorderColor: containerBorderColor ?? this.containerBorderColor,
      isHacking: isHacking ?? this.isHacking,
      isAurora: isAurora ?? this.isAurora,
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
      fieldFillColor: Color.lerp(fieldFillColor, other.fieldFillColor, t)!,
      containerBorderColor: Color.lerp(
        containerBorderColor,
        other.containerBorderColor,
        t,
      ),
      isHacking: t < 0.5 ? isHacking : other.isHacking,
      isAurora: t < 0.5 ? isAurora : other.isAurora,
    );
  }

  static const AppThemeTokens light = AppThemeTokens(
    containerColor: Colors.white,
    expiredContainerColor: Color(0xFF4A4A4A),
    fieldFillColor: Color(0xFFF2F2F2),
  );

  static const AppThemeTokens dark = AppThemeTokens(
    containerColor: AppThemes.darkSurface,
    expiredContainerColor: Color(0xFF4A4A4A),
    fieldFillColor: Color(0xFF2C2E38),
  );

  static final AppThemeTokens aurora = AppThemeTokens(
    containerColor: AppThemes.auroraSurface.withValues(alpha: 0.94),
    expiredContainerColor: const Color(0xFF4A4A4A).withValues(alpha: 0.88),
    fieldFillColor: const Color(0xFF232A48),
    containerBorderColor: AppThemes.auroraGlowCyan.withValues(alpha: 0.42),
    isAurora: true,
  );

  static final AppThemeTokens hacking = AppThemeTokens(
    containerColor: AppThemes.hackSurface.withValues(alpha: 0.72),
    expiredContainerColor: const Color(0xFF4A4A4A).withValues(alpha: 0.72),
    fieldFillColor: const Color(0xFF0B140B),
    containerBorderColor: AppThemes.hackAccent.withValues(alpha: 0.45),
    isHacking: true,
  );
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get appTokens =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppThemeTokens.light;

  Color get containerColor => appTokens.containerColor;

  Color get fieldFillColor => appTokens.fieldFillColor;

  Color get expiredContainerColor => appTokens.expiredContainerColor;

  BoxDecoration containerDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return appTokens.containerDecoration(borderRadius: borderRadius);
  }

  Color get textColor => Theme.of(this).colorScheme.onSurface;

  Color get mutedTextColor => textColor.withValues(alpha: 0.72);

  Color get labelTextColor => textColor.withValues(alpha: 0.55);

  bool get isHackingTheme => appTokens.isHacking;

  bool get isAuroraTheme => appTokens.isAurora;

  String? get themedMapStyle {
    if (isHackingTheme) {
      return hackingMapStyle;
    }
    if (isAuroraTheme) {
      return auroraMapStyle;
    }
    return null;
  }
}
