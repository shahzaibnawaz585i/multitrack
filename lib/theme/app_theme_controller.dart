import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_mode.dart';

class AppThemeController extends ChangeNotifier {
  /// New key — avoids crash from old int value under `app_theme_mode`.
  static const String _storageKey = 'app_theme_mode_v2';
  static const String _legacyKey = 'app_theme_mode';
  static const String _legacyIndexKey = 'app_theme_mode_index';
  static const String _appColorKey = 'app_primary_color_name';

  AppThemeMode _mode = AppThemeMode.light;
  String _appColorName = 'Default Color';
  bool _isReady = false;

  AppThemeMode get mode => _mode;
  String get appColorName => _appColorName;

  bool get isReady => _isReady;

  bool get isHacking => _mode.isHacking;

  bool get isAurora => _mode.isAurora;

  bool get isDark => _mode.isDark;

  Color get customAccentColor {
    if (_mode == AppThemeMode.hacking) {
      return const Color(0xFF00FF88);
    }
    switch (_appColorName) {
      case 'Blue':
        return const Color(0xFF2196F3);
      case 'Green':
        return const Color(0xFF4CAF50);
      case 'Red':
        return const Color(0xFFE53935);
      case 'Pink':
        return const Color(0xFFFF2F68);
      case 'Default Color':
      default:
        return const Color(0xFFFF2F68);
    }
  }

  Future<void> initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _mode = _readStoredMode(prefs);
      _appColorName = prefs.getString(_appColorKey) ?? 'Default Color';
      // Migrate / clean old broken int key so it never crashes again.
      await _migrateLegacy(prefs, _mode);
    } catch (error, stackTrace) {
      debugPrint('AppThemeController.initialize failed: $error');
      debugPrint('$stackTrace');
      _mode = AppThemeMode.light;
    } finally {
      _isReady = true;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  Future<void> setAppColorName(String name) async {
    if (_appColorName != name) {
      _appColorName = name;
      notifyListeners();
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appColorKey, name);
    } catch (error) {
      debugPrint('AppThemeController.setAppColorName failed: $error');
    }
  }

  AppThemeMode _readStoredMode(SharedPreferences prefs) {
    final String? storedName = prefs.getString(_storageKey);
    if (storedName != null) {
      for (final AppThemeMode mode in AppThemeMode.values) {
        if (mode.name == storedName) {
          return mode;
        }
      }
    }

    // Read legacy values without getString on a possibly-int key.
    final Object? legacyRaw = prefs.get(_legacyKey);
    if (legacyRaw is String) {
      for (final AppThemeMode mode in AppThemeMode.values) {
        if (mode.name == legacyRaw) {
          return mode;
        }
      }
    }
    if (legacyRaw is int) {
      return AppThemeMode
          .values[legacyRaw.clamp(0, AppThemeMode.values.length - 1)];
    }

    final Object? legacyIndexRaw = prefs.get(_legacyIndexKey);
    if (legacyIndexRaw is int) {
      return AppThemeMode.values[
          legacyIndexRaw.clamp(0, AppThemeMode.values.length - 1)];
    }

    return AppThemeMode.light;
  }

  Future<void> _migrateLegacy(
    SharedPreferences prefs,
    AppThemeMode mode,
  ) async {
    await prefs.setString(_storageKey, mode.name);
    // Drop old key that may still hold an int (causes getString crash).
    await prefs.remove(_legacyKey);
    await prefs.remove(_legacyIndexKey);
    await prefs.remove('app_theme_mode_index');
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
    await _persist(mode);
  }

  Future<void> _persist(AppThemeMode mode) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.name);
      await prefs.remove(_legacyKey);
    } catch (error) {
      debugPrint('AppThemeController._persist failed: $error');
    }
  }
}
