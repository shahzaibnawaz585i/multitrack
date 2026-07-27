enum AppThemeMode {
  light,
  dark,
  hacking,
}

extension AppThemeModeX on AppThemeMode {
  bool get isHacking => this == AppThemeMode.hacking;

  bool get isDark => this == AppThemeMode.dark || isHacking;

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
      case AppThemeMode.hacking:
        return 'Hacking Theme';
    }
  }
}
