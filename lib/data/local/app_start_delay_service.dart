import 'package:shared_preferences/shared_preferences.dart';

class AppStartDelayService {
  static const String _key = 'app_start_delay_seconds';
  static const int _defaultSeconds = 0;

  final SharedPreferences _prefs;

  AppStartDelayService(this._prefs);

  Future<int> getDelaySeconds() async {
    return _prefs.getInt(_key) ?? _defaultSeconds;
  }

  Future<void> setDelaySeconds(int seconds) async {
    await _prefs.setInt(_key, seconds.clamp(0, 300));
  }
}
