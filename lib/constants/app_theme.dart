import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppThemes {
  AppThemes._();

  static const Color pinkColor = Color(0xFFFF2F68);

  // Advanced hacking / terminal palette
  static const Color hackVoid = Color(0xFF010402);
  static const Color hackPanel = Color(0xFF071007);
  static const Color hackPanelRaised = Color(0xFF0C180C);
  static const Color hackNeon = Color(0xFF00FF88);
  static const Color hackNeonBright = Color(0xFF39FF14);
  static const Color hackCyan = Color(0xFF00E5FF);
  static const Color hackAmber = Color(0xFFFFB000);
  static const Color hackText = Color(0xFF7CFF9E);
  static const Color hackMuted = Color(0xFF3D6B45);
  static const Color hackBorder = Color(0xFF1A5C2A);
  static const Color hackGlow = Color(0x6600FF88);

  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData screenHack() => _buildAdvancedHackingTheme(screenHack: true);

  static ThemeData _buildAdvancedHackingTheme({bool screenHack = false}) {
    const Color scaffold = Colors.transparent;
    const Color surface = Color(0xE0071007);
    const Color onSurface = hackText;
    const Color secondaryText = hackMuted;
    const Color fieldFill = Color(0xD8050C05);
    const Color headerBackground = Color(0xDD030803);
    const Color divider = Color(0xFF143814);
    const Color chipBackground = Color(0xCC0A160A);
    const Color scrolledHeader = Color(0xD8081208);
    const Color border = hackBorder;
    const Color iconCircleFill = Color(0xE00C180C);
    const Color accentColor = hackNeon;

    final TextStyle terminalText = TextStyle(
      color: onSurface,
      letterSpacing: 0.4,
      height: 1.35,
    );

    final TextStyle terminalTitle = TextStyle(
      color: hackNeonBright,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      fontFamily: AppFonts.number,
    );

    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: hackNeon,
      onPrimary: hackVoid,
      secondary: hackCyan,
      onSecondary: hackVoid,
      error: hackAmber,
      onError: hackVoid,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: hackPanelRaised,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffold,
      cardColor: surface,
      dividerColor: divider,
      fontFamily: AppFonts.regular,
      colorScheme: colorScheme,
      iconTheme: const IconThemeData(color: hackNeonBright),
      textTheme: TextTheme(
        bodyLarge: terminalText,
        bodyMedium: terminalText,
        bodySmall: TextStyle(color: secondaryText, letterSpacing: 0.3),
        titleLarge: terminalTitle.copyWith(fontSize: 22),
        titleMedium: terminalTitle.copyWith(fontSize: 18),
        labelLarge: TextStyle(
          color: hackCyan,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.number,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: headerBackground,
        foregroundColor: hackNeonBright,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: terminalTitle.copyWith(fontSize: 20),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF00C180C),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: hackNeon.withValues(alpha: 0.55)),
        ),
        titleTextStyle: terminalTitle.copyWith(fontSize: 18),
        contentTextStyle: terminalText,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xF00C180C),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          side: BorderSide(color: hackNeon.withValues(alpha: 0.35)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: TextStyle(
          color: secondaryText,
          letterSpacing: 0.5,
          fontFamily: AppFonts.number,
        ),
        labelStyle: TextStyle(color: hackCyan, letterSpacing: 0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: hackNeonBright, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: hackAmber),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: hackNeonBright,
        textColor: onSurface,
        tileColor: surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: hackNeon,
        foregroundColor: hackVoid,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: hackNeonBright.withValues(alpha: 0.8)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: hackNeon,
        inactiveTrackColor: const Color(0xFF1A331A),
        thumbColor: hackNeonBright,
        overlayColor: hackGlow,
        valueIndicatorColor: hackPanelRaised,
        valueIndicatorTextStyle: TextStyle(
          color: hackNeonBright,
          fontFamily: AppFonts.number,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: hackPanelRaised,
        contentTextStyle: TextStyle(
          color: hackNeonBright,
          fontFamily: AppFonts.number,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: hackNeon.withValues(alpha: 0.5)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xE00C180C),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: hackGlow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: hackNeon.withValues(alpha: 0.28)),
        ),
      ),
      canvasColor: surface,
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xE0071007),
        selectedItemColor: hackNeonBright,
        unselectedItemColor: hackMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: AppFonts.number,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: hackPanel,
        indicatorColor: hackNeon.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: hackText,
            fontFamily: AppFonts.number,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: hackNeonBright, size: 24);
          }
          return const IconThemeData(color: hackMuted, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: hackNeon.withValues(alpha: 0.22),
        disabledColor: hackPanel,
        labelStyle: TextStyle(
          color: hackNeonBright,
          letterSpacing: 0.5,
          fontFamily: AppFonts.number,
        ),
        side: BorderSide(color: hackNeon.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hackNeonBright;
          }
          return hackMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hackNeon.withValues(alpha: 0.35);
          }
          return const Color(0xFF142814);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hackNeon;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(hackVoid),
        side: BorderSide(color: hackNeon.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: hackNeon,
        circularTrackColor: Color(0xFF142814),
        linearTrackColor: Color(0xFF142814),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(hackPanelRaised),
          side: WidgetStatePropertyAll(
            BorderSide(color: hackNeon.withValues(alpha: 0.4)),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: hackPanelRaised,
        headerBackgroundColor: headerBackground,
        headerForegroundColor: hackNeonBright,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hackVoid;
          }
          return hackText;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hackNeon;
          }
          return Colors.transparent;
        }),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: hackPanelRaised,
        dialHandColor: hackNeon,
        dialBackgroundColor: hackPanel,
        hourMinuteColor: fieldFill,
        hourMinuteTextColor: hackNeonBright,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppPalette(
          fieldFill: fieldFill,
          headerBackground: headerBackground,
          secondaryText: secondaryText,
          chipBackground: chipBackground,
          scrolledHeader: scrolledHeader,
          border: border,
          iconCircleFill: iconCircleFill,
          accentColor: accentColor,
          glowColor: hackGlow,
          isHackingTheme: true,
          isScreenHackTheme: screenHack,
        ),
      ],
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return _buildCustomTheme(
      brightness: brightness,
      scaffold: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      onSurface: isDark ? Colors.white : const Color(0xFF292B32),
      secondaryText: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      fieldFill: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
      headerBackground:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEBF2F8),
      divider: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
      chipBackground:
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFE8EE),
      scrolledHeader:
          isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE3F2FD),
      border: isDark ? const Color(0xFF444444) : Colors.grey.shade400,
      iconCircleFill: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      accentColor: pinkColor,
      isHackingTheme: false,
      isScreenHackTheme: false,
    );
  }

  static ThemeData _buildCustomTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color secondaryText,
    required Color fieldFill,
    required Color headerBackground,
    required Color divider,
    required Color chipBackground,
    required Color scrolledHeader,
    required Color border,
    required Color iconCircleFill,
    required Color accentColor,
    required bool isHackingTheme,
    bool isScreenHackTheme = false,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
      primary: accentColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      cardColor: surface,
      dividerColor: divider,
      fontFamily: AppFonts.regular,
      colorScheme: colorScheme,
      iconTheme: IconThemeData(color: onSurface),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: secondaryText),
        titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: onSurface),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
        tileColor: surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor:
            isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
      ),
      canvasColor: surface,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentColor,
        unselectedItemColor: secondaryText,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: headerBackground,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppPalette(
          fieldFill: fieldFill,
          headerBackground: headerBackground,
          secondaryText: secondaryText,
          chipBackground: chipBackground,
          scrolledHeader: scrolledHeader,
          border: border,
          iconCircleFill: iconCircleFill,
          accentColor: accentColor,
          glowColor: accentColor.withValues(alpha: 0.25),
          isHackingTheme: isHackingTheme,
          isScreenHackTheme: isScreenHackTheme,
        ),
      ],
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color fieldFill;
  final Color headerBackground;
  final Color secondaryText;
  final Color chipBackground;
  final Color scrolledHeader;
  final Color border;
  final Color iconCircleFill;
  final Color accentColor;
  final Color glowColor;
  final bool isHackingTheme;
  final bool isScreenHackTheme;

  const AppPalette({
    required this.fieldFill,
    required this.headerBackground,
    required this.secondaryText,
    required this.chipBackground,
    required this.scrolledHeader,
    required this.border,
    required this.iconCircleFill,
    required this.accentColor,
    required this.glowColor,
    this.isHackingTheme = false,
    this.isScreenHackTheme = false,
  });

  @override
  AppPalette copyWith({
    Color? fieldFill,
    Color? headerBackground,
    Color? secondaryText,
    Color? chipBackground,
    Color? scrolledHeader,
    Color? border,
    Color? iconCircleFill,
    Color? accentColor,
    Color? glowColor,
    bool? isHackingTheme,
    bool? isScreenHackTheme,
  }) {
    return AppPalette(
      fieldFill: fieldFill ?? this.fieldFill,
      headerBackground: headerBackground ?? this.headerBackground,
      secondaryText: secondaryText ?? this.secondaryText,
      chipBackground: chipBackground ?? this.chipBackground,
      scrolledHeader: scrolledHeader ?? this.scrolledHeader,
      border: border ?? this.border,
      iconCircleFill: iconCircleFill ?? this.iconCircleFill,
      accentColor: accentColor ?? this.accentColor,
      glowColor: glowColor ?? this.glowColor,
      isHackingTheme: isHackingTheme ?? this.isHackingTheme,
      isScreenHackTheme: isScreenHackTheme ?? this.isScreenHackTheme,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      headerBackground: Color.lerp(headerBackground, other.headerBackground, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      scrolledHeader: Color.lerp(scrolledHeader, other.scrolledHeader, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconCircleFill: Color.lerp(iconCircleFill, other.iconCircleFill, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      isHackingTheme: t < 0.5 ? isHackingTheme : other.isHackingTheme,
      isScreenHackTheme:
          t < 0.5 ? isScreenHackTheme : other.isScreenHackTheme,
    );
  }
}

extension AppThemeContext on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  bool get isHackingTheme => palette.isHackingTheme;

  bool get isScreenHackTheme => palette.isScreenHackTheme;

  bool get usesHackBackground => isHackingTheme;

  ThemeData get appTheme => Theme.of(this);

  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (isDarkTheme
          ? const AppPalette(
              fieldFill: Color(0xFF2A2A2A),
              headerBackground: Color(0xFF1A1A1A),
              secondaryText: Colors.grey,
              chipBackground: Color(0xFF2A2A2A),
              scrolledHeader: Color(0xFF1F1F1F),
              border: Color(0xFF444444),
              iconCircleFill: Color(0xFF2A2A2A),
              accentColor: AppThemes.pinkColor,
              glowColor: Color(0x33FF2F68),
            )
          : const AppPalette(
              fieldFill: Color(0xFFF2F2F2),
              headerBackground: Color(0xFFEBF2F8),
              secondaryText: Colors.grey,
              chipBackground: Color(0xFFFFE8EE),
              scrolledHeader: Color(0xFFE3F2FD),
              border: Colors.grey,
              iconCircleFill: Colors.white,
              accentColor: AppThemes.pinkColor,
              glowColor: Color(0x33FF2F68),
            ));

  Color get appBackground => appTheme.scaffoldBackgroundColor;

  Color get appSurface => appTheme.cardColor;

  Color get appTextColor => appTheme.colorScheme.onSurface;

  Color get appSecondaryText => palette.secondaryText;

  Color get appFieldFill => palette.fieldFill;

  Color get appHeaderBackground => palette.headerBackground;

  Color get appChipBackground => palette.chipBackground;

  Color get appScrolledHeader => palette.scrolledHeader;

  Color get appBorder => palette.border;

  Color get appIconCircleFill => palette.iconCircleFill;

  Color get appAccentColor => palette.accentColor;

  Color get appGlowColor => palette.glowColor;

  Color get appPrimaryColor =>
      isHackingTheme ? palette.accentColor : AppThemes.pinkColor;

  static const Color pinkColor = AppThemes.pinkColor;
}

/// Onboarding / login screens always stay light, even if dark mode is on.
class PreLoginThemeScope extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const PreLoginThemeScope({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.light(),
      child: Builder(
        builder: (lightContext) => ColoredBox(
          color: lightContext.appBackground,
          child: builder(lightContext),
        ),
      ),
    );
  }
}

/// Terminal-style panel decoration for hacking theme screens.
class HackingPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  const HackingPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    final bool hacking = context.isHackingTheme;

    if (!hacking) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: borderRadius,
        ),
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xE00C180C),
        borderRadius: borderRadius,
        border: Border.all(
          color: AppThemes.hackNeon.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemes.hackGlow,
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
