import 'package:shared_preferences/shared_preferences.dart';

class KioskIdStorage {
  static const String _kioskIdKey = 'kiosk_id';

  final SharedPreferences _prefs;

  KioskIdStorage(this._prefs);

  Future<String?> getKioskId() async {
    return _prefs.getString(_kioskIdKey);
  }

  Future<void> setKioskId(String kioskId) async {
    await _prefs.setString(_kioskIdKey, kioskId);
  }

  Future<void> clearKioskId() async {
    await _prefs.remove(_kioskIdKey);
  }
}
