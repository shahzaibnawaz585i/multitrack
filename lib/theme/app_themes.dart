import 'package:flutter/material.dart';

import '../constants/app_fonts.dart';
import 'app_theme_mode.dart';
import 'app_theme_tokens.dart';

class AppThemes {
  AppThemes._();

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.aurora:
        return aurora;
      case AppThemeMode.hacking:
        return hacking;
    }
  }

  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightText = Color(0xFF292B32);
  static const Color pinkAccent = Color(0xFFFF2F68);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF23252E);
  static const Color auroraBackground = Color(0xFF07091A);
  static const Color auroraSurface = Color(0xFF171C32);
  static const Color auroraText = Color(0xFFF0F4FF);
  static const Color auroraGlowCyan = Color(0xFF5CE1FF);
  static const Color auroraGlowViolet = Color(0xFF9B7DFF);
  static const Color hackBackground = Color(0xFF000000);
  static const Color hackSurface = Color(0xFF050805);
  static const Color hackText = Color(0xFF00E676);
  static const Color hackAccent = Color(0xFF00FF88);

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(color: color, fontFamily: AppFonts.regular),
      displayMedium: TextStyle(color: color, fontFamily: AppFonts.regular),
      displaySmall: TextStyle(color: color, fontFamily: AppFonts.regular),
      headlineLarge: TextStyle(color: color, fontFamily: AppFonts.regular),
      headlineMedium: TextStyle(color: color, fontFamily: AppFonts.regular),
      headlineSmall: TextStyle(
        color: color,
        fontFamily: AppFonts.regular,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: color,
        fontFamily: AppFonts.regular,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: color,
        fontFamily: AppFonts.regular,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(color: color, fontFamily: AppFonts.regular),
      bodyLarge: TextStyle(color: color, fontFamily: AppFonts.regular),
      bodyMedium: TextStyle(color: color, fontFamily: AppFonts.regular),
      bodySmall: TextStyle(
        color: color.withValues(alpha: 0.75),
        fontFamily: AppFonts.regular,
      ),
      labelLarge: TextStyle(color: color, fontFamily: AppFonts.regular),
      labelMedium: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontFamily: AppFonts.regular,
      ),
      labelSmall: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontFamily: AppFonts.regular,
      ),
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        fontFamily: AppFonts.regular,
        colorScheme: const ColorScheme.light(
          primary: pinkAccent,
          surface: Colors.white,
          onSurface: lightText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: lightText,
          surfaceTintColor: lightBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardColor: Colors.white,
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        dividerColor: Color(0x14000000),
        textTheme: _textTheme(lightText),
        iconTheme: const IconThemeData(color: lightText),
        datePickerTheme: _datePickerThemeDark,
        timePickerTheme: _timePickerThemeDark,
        extensions: const <ThemeExtension<dynamic>>[
          AppThemeTokens.light,
        ],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        fontFamily: AppFonts.regular,
        colorScheme: const ColorScheme.dark(
          primary: pinkAccent,
          surface: darkSurface,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          foregroundColor: Colors.white,
          surfaceTintColor: darkBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardColor: darkSurface,
        dialogTheme: const DialogThemeData(
          backgroundColor: darkSurface,
          surfaceTintColor: darkSurface,
        ),
        dividerColor: Color(0x24FFFFFF),
        textTheme: _textTheme(Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        datePickerTheme: _datePickerThemeDark,
        timePickerTheme: _timePickerThemeDark,
        extensions: const <ThemeExtension<dynamic>>[
          AppThemeTokens.dark,
        ],
      );

  static ThemeData get aurora => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: AppFonts.regular,
        splashFactory: InkSparkle.splashFactory,
        colorScheme: const ColorScheme.dark(
          primary: pinkAccent,
          secondary: Color(0xFF00F5D4),
          tertiary: Color(0xFFA78BFA),
          surface: auroraSurface,
          onSurface: auroraText,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: auroraText,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF13182E).withValues(alpha: 0.82),
          elevation: 6,
          shadowColor: const Color(0xFF00F5D4).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.22),
              width: 1,
            ),
          ),
        ),
        cardColor: const Color(0xFF13182E),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF101529).withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shadowColor: const Color(0xFFA78BFA).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.38),
              width: 1.2,
            ),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: const Color(0xFF101529).withValues(alpha: 0.96),
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(
              color: Color(0xFF00F5D4),
              width: 0.8,
            ),
          ),
        ),
        dividerColor: const Color(0x44A78BFA),
        textTheme: _textTheme(auroraText),
        iconTheme: const IconThemeData(color: auroraText),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: pinkAccent,
          foregroundColor: Colors.white,
          elevation: 10,
          splashColor: const Color(0xFF00F5D4).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkAccent,
            foregroundColor: Colors.white,
            shadowColor: pinkAccent.withValues(alpha: 0.55),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A213D),
          labelStyle: TextStyle(color: auroraText.withValues(alpha: 0.88)),
          hintStyle: TextStyle(color: auroraText.withValues(alpha: 0.48)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.30),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.30),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00F5D4), width: 2),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            return s.contains(WidgetState.selected)
                ? const Color(0xFF00F5D4)
                : auroraText.withValues(alpha: 0.65);
          }),
          trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            return s.contains(WidgetState.selected)
                ? const Color(0xFF00F5D4).withValues(alpha: 0.35)
                : const Color(0xFF1A213D);
          }),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF00F5D4),
          thumbColor: Color(0xFF00F5D4),
          overlayColor: Color(0x3300F5D4),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF101529),
          contentTextStyle: TextStyle(color: auroraText),
        ),
        datePickerTheme: _datePickerThemeAurora,
        timePickerTheme: _timePickerThemeAurora,
        extensions: <ThemeExtension<dynamic>>[
          AppThemeTokens.aurora,
        ],
      );

  static ThemeData get hacking => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: AppFonts.regular,
        colorScheme: ColorScheme.dark(
          primary: hackAccent,
          surface: hackSurface.withValues(alpha: 0.72),
          onSurface: hackText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: hackText,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardColor: hackSurface.withValues(alpha: 0.72),
        dividerColor: Color(0x3300FF88),
        textTheme: _textTheme(hackText),
        primaryTextTheme: _textTheme(hackText),
        iconTheme: const IconThemeData(color: hackText),
        listTileTheme: const ListTileThemeData(
          textColor: hackText,
          iconColor: hackText,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: hackText.withValues(alpha: 0.85)),
          hintStyle: TextStyle(color: hackText.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: hackAccent.withValues(alpha: 0.35)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: hackAccent, width: 2),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: hackAccent,
          unselectedLabelColor: hackText,
          indicatorColor: hackAccent,
        ),
        datePickerTheme: _datePickerThemeDark,
        timePickerTheme: _timePickerThemeDark,
        extensions: <ThemeExtension<dynamic>>[
          AppThemeTokens.hacking,
        ],
      );

  static const Color _pickerHeader = Color(0xFF292B32);

  static final DatePickerThemeData _datePickerTheme = DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: _pickerHeader,
    headerForegroundColor: Colors.white,
    dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return Colors.white;
      }
      if (s.contains(WidgetState.disabled)) {
        return Colors.grey.shade400;
      }
      return _pickerHeader;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return _pickerHeader;
      }
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.all(_pickerHeader),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: _pickerHeader),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: _pickerHeader),
  );

  static final TimePickerThemeData _timePickerTheme = TimePickerThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    hourMinuteColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return _pickerHeader;
      }
      return const Color(0xFFE8E8E8);
    }),
    hourMinuteTextColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return _pickerHeader;
    }),
    dialHandColor: _pickerHeader,
    entryModeIconColor: _pickerHeader,
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: _pickerHeader),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: _pickerHeader),
  );

  static final DatePickerThemeData _datePickerThemeDark = DatePickerThemeData(
    backgroundColor: darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: darkSurface,
    headerForegroundColor: Colors.white,
    dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return Colors.white;
      }
      if (s.contains(WidgetState.disabled)) {
        return Colors.white38;
      }
      return Colors.white;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return pinkAccent;
      }
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.all(pinkAccent),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pinkAccent),
  );

  static final TimePickerThemeData _timePickerThemeDark = TimePickerThemeData(
    backgroundColor: darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    hourMinuteColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return pinkAccent;
      }
      return const Color(0xFF2C2E38);
    }),
    hourMinuteTextColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return Colors.white;
    }),
    dialHandColor: pinkAccent,
    entryModeIconColor: Colors.white,
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pinkAccent),
  );

  static final DatePickerThemeData _datePickerThemeAurora = DatePickerThemeData(
    backgroundColor: auroraSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: auroraSurface,
    headerForegroundColor: auroraText,
    dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return Colors.white;
      }
      if (s.contains(WidgetState.disabled)) {
        return auroraText.withValues(alpha: 0.35);
      }
      return auroraText;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return pinkAccent;
      }
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.all(auroraGlowCyan),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: auroraText),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pinkAccent),
  );

  static final TimePickerThemeData _timePickerThemeAurora = TimePickerThemeData(
    backgroundColor: auroraSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    hourMinuteColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return pinkAccent;
      }
      return const Color(0xFF232A48);
    }),
    hourMinuteTextColor: WidgetStateColor.resolveWith((Set<WidgetState> s) {
      return Colors.white;
    }),
    dialHandColor: pinkAccent,
    dialBackgroundColor: const Color(0xFF232A48),
    entryModeIconColor: auroraGlowCyan,
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: auroraText),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pinkAccent),
  );

  static ThemeData hackingOverlayTheme(ThemeData base) {
    return base.copyWith(
      textTheme: _textTheme(hackText),
      primaryTextTheme: _textTheme(hackText),
      iconTheme: const IconThemeData(color: hackText),
      listTileTheme: const ListTileThemeData(
        textColor: hackText,
        iconColor: hackText,
      ),
      // Keep calendar/time pickers on the shared light charcoal look.
      datePickerTheme: _datePickerThemeDark,
      timePickerTheme: _timePickerThemeDark,
      dialogTheme: DialogThemeData(
        backgroundColor: hackSurface.withValues(alpha: 0.92),
        titleTextStyle: const TextStyle(
          color: hackText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: hackText),
      ),
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(color: hackText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: hackAccent,
        unselectedItemColor: hackText.withValues(alpha: 0.6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: hackText.withValues(alpha: 0.85)),
        hintStyle: TextStyle(color: hackText.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: hackAccent.withValues(alpha: 0.35)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: hackAccent, width: 2),
        ),
      ),
    );
  }

  static Widget wrapHackingContent({
    required Widget child,
    required Widget background,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        background,
        Builder(
          builder: (BuildContext context) {
            return Theme(
              data: hackingOverlayTheme(Theme.of(context)),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: hackText),
                child: IconTheme.merge(
                  data: const IconThemeData(color: hackText),
                  child: child,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
