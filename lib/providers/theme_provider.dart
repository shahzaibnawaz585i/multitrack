import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_theme.dart';

enum AppThemeType {
  light,
  dark,
  screenHack,
}

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'app_theme_type';
  static const String _legacyDarkKey = 'is_dark_theme';

  AppThemeType _themeType = AppThemeType.light;

  AppThemeType get themeType => _themeType;

  bool get isDarkMode => _themeType == AppThemeType.dark;

  bool get isScreenHackTheme => _themeType == AppThemeType.screenHack;

  bool get isHackingTheme => isScreenHackTheme;

  bool get usesHackBackground => isScreenHackTheme;

  ThemeData get resolvedTheme {
    switch (_themeType) {
      case AppThemeType.light:
        return AppThemes.light();
      case AppThemeType.dark:
        return AppThemes.dark();
      case AppThemeType.screenHack:
        return AppThemes.screenHack();
    }
  }

  String get themeLabel {
    switch (_themeType) {
      case AppThemeType.light:
        return 'Light Theme';
      case AppThemeType.dark:
        return 'Dark Theme';
      case AppThemeType.screenHack:
        return 'Screen Hack Theme';
    }
  }

  Future<void> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedType = prefs.getString(_storageKey);

    if (savedType != null) {
      if (savedType == 'hacking') {
        _themeType = AppThemeType.screenHack;
      } else {
        _themeType = AppThemeType.values.firstWhere(
          (type) => type.name == savedType,
          orElse: () => AppThemeType.light,
        );
      }
    } else {
      final bool legacyDark = prefs.getBool(_legacyDarkKey) ?? false;
      _themeType = legacyDark ? AppThemeType.dark : AppThemeType.light;
    }

    notifyListeners();
  }

  Future<void> setTheme(AppThemeType type) async {
    if (_themeType == type) {
      return;
    }

    _themeType = type;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, type.name);
    await prefs.setBool(
      _legacyDarkKey,
      type == AppThemeType.dark || type == AppThemeType.screenHack,
    );

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final AppThemeType nextTheme = switch (_themeType) {
      AppThemeType.light => AppThemeType.dark,
      AppThemeType.dark => AppThemeType.screenHack,
      AppThemeType.screenHack => AppThemeType.light,
    };

    await setTheme(nextTheme);
  }
}
