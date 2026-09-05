enum AppThemeMode {
  light,
  dark,
  aurora,
  hacking,
}

extension AppThemeModeX on AppThemeMode {
  bool get isHacking => this == AppThemeMode.hacking;

  bool get isAurora => this == AppThemeMode.aurora;

  bool get isDark => this == AppThemeMode.dark || isHacking || isAurora;

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
      case AppThemeMode.aurora:
        return 'Aurora Theme';
      case AppThemeMode.hacking:
        return 'Hacking Theme';
    }
  }
}
