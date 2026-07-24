import 'package:shared_preferences/shared_preferences.dart';

class DebugModeService {
  static const String _debugModeKey = 'debug_mode';
  static const bool _defaultDebugMode = false;

  final SharedPreferences _prefs;

  DebugModeService(this._prefs);

  Future<bool> isDebugMode() async {
    return _prefs.getBool(_debugModeKey) ?? _defaultDebugMode;
  }

  Future<void> setDebugMode(bool enabled) async {
    await _prefs.setBool(_debugModeKey, enabled);
  }
}
