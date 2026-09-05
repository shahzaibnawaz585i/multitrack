import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_extra_translations.dart';
import 'app_languages.dart';
import 'app_translations.dart';

class AppLocaleController extends ChangeNotifier {
  static const String _storageKey = 'app_language_name';
   AppLanguage _language = AppLanguages.byName('English');
  bool _isReady = false;

  AppLanguage get language => _language;

  String get languageName => _language.name;

  bool get isReady => _isReady;

  Locale get locale => _language.locale;

  Locale get materialLocale {
    if (AppLanguages.materialSupportedCodes.contains(_language.code)) {
      return _language.locale;
    }
    return const Locale('en');
  }

  TextDirection get textDirection =>
      _language.isRtl ? TextDirection.rtl : TextDirection.ltr;

  String translate(String text) {
    if (text.isEmpty || _language.code == 'en') {
      return text;
    }
    if (RegExp(r'^[\d./:#+\-()\s]+$').hasMatch(text)) {
      return text;
    }
    final String key = AppLanguages.lookupKey(_language);
    return kAppExtraTranslations[key]?[text] ??
        kAppTranslations[key]?[text] ??
        text;
  }

  String translateParams(String text, Map<String, String> params) {
    String translated = translate(text);
    params.forEach((String name, String value) {
      translated = translated.replaceAll('{$name}', value);
    });
    return translated;
  }

  Future<void> initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? storedName = prefs.getString(_storageKey);
      if (storedName != null && storedName.isNotEmpty) {
        _language = AppLanguages.byName(storedName);
      }
    } catch (error, stackTrace) {
      debugPrint('AppLocaleController.initialize failed: $error');
      debugPrint('$stackTrace');
      _language = AppLanguages.byName('English');
    } finally {
      _isReady = true;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  Future<void> setLanguageName(String name) async {
    final AppLanguage next = AppLanguages.byName(name);
    if (next.name == _language.name && _isReady) {
      return;
    }
    _language = next;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, next.name);
    } catch (error) {
      debugPrint('AppLocaleController.setLanguageName failed: $error');
    }
  }
}

AppLocaleController? appLocaleController;
