import 'package:shared_preferences/shared_preferences.dart';

class AdminPasswordService {
  static const String _passwordKey = 'admin_password';
  static const String _defaultPassword = '0000';

  final SharedPreferences _prefs;

  AdminPasswordService(this._prefs);

  Future<String> getPassword() async {
    final password = _prefs.getString(_passwordKey);
    return password ?? _defaultPassword;
  }

  Future<void> setPassword(String password) async {
    await _prefs.setString(_passwordKey, password);
  }

  Future<bool> verifyPassword(String inputPassword) async {
    final storedPassword = await getPassword();
    return inputPassword == storedPassword;
  }
}





















