import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/service_locator.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ko'));
  bool _isInitialized = false;
  bool _hasTemporaryChange = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final localeService = ServiceLocator().localeService;
    final defaultLocale = await localeService.getDefaultLocale();
    if (!_hasTemporaryChange) {
      state = defaultLocale;
    }
  }

  Future<void> changeDefaultLocale(Locale locale) async {
    state = locale;
    _hasTemporaryChange = false;
    final localeService = ServiceLocator().localeService;
    await localeService.setDefaultLocale(locale);
  }

  void changeTemporaryLocale(Locale locale) {
    _hasTemporaryChange = true;
    state = locale;
  }

  Future<void> resetToDefaultLocale() async {
    _hasTemporaryChange = false;
    final localeService = ServiceLocator().localeService;
    final defaultLocale = await localeService.getDefaultLocale();
    state = defaultLocale;
  }

  void toggleLocale() {
    if (state.languageCode == 'ko') {
      changeTemporaryLocale(const Locale('en'));
    } else {
      changeTemporaryLocale(const Locale('ko'));
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final notifier = LocaleNotifier();
  notifier.initialize();
  return notifier;
});
