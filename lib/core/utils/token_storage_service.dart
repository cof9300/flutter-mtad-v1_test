import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  
  final SharedPreferences _storage;

  TokenStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _storage.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

