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
      case AppThemeMode.hacking:
        return hacking;
    }
  }

  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightText = Color(0xFF292B32);
  static const Color pinkAccent = Color(0xFFFF2F68);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF23252E);
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
        dividerColor: Color(0x14000000),
        textTheme: _textTheme(lightText),
        iconTheme: const IconThemeData(color: lightText),
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
        dividerColor: Color(0x24FFFFFF),
        textTheme: _textTheme(Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        extensions: const <ThemeExtension<dynamic>>[
          AppThemeTokens.dark,
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
        extensions: <ThemeExtension<dynamic>>[
          AppThemeTokens.hacking,
        ],
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
