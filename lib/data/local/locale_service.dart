import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocaleService {
  static const String _defaultLocaleKey = 'default_locale';
  static const String _defaultLocaleCode = 'ko';

  final SharedPreferences _prefs;

  LocaleService(this._prefs);

  Future<Locale> getDefaultLocale() async {
    final localeCode = _prefs.getString(_defaultLocaleKey) ?? _defaultLocaleCode;
    return Locale(localeCode);
  }

  Future<void> setDefaultLocale(Locale locale) async {
    await _prefs.setString(_defaultLocaleKey, locale.languageCode);
  }

  Future<String> getDefaultLocaleCode() async {
    return _prefs.getString(_defaultLocaleKey) ?? _defaultLocaleCode;
  }
}





















