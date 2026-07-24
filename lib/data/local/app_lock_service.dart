import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const String _key = 'app_lock_enabled';

  final SharedPreferences _prefs;

  AppLockService(this._prefs);

  Future<bool> isLocked() async => _prefs.getBool(_key) ?? false;

  Future<void> setLocked(bool locked) async =>
      _prefs.setBool(_key, locked);
}
