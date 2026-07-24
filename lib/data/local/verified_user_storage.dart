import 'package:shared_preferences/shared_preferences.dart';

class VerifiedUserStorage {
  final SharedPreferences _storage;

  VerifiedUserStorage(this._storage);

  static const String _keyPhoneNumber = 'verified_user_phone_number';
  static const String _keyBirthday = 'verified_user_birthday';
  static const String _keyGender = 'verified_user_gender';

  Future<void> saveUserData({
    required String phoneNumber,
    required String birthday,
    required String gender,
  }) async {
    await Future.wait([
      _storage.setString(_keyPhoneNumber, phoneNumber),
      _storage.setString(_keyBirthday, birthday),
      _storage.setString(_keyGender, gender),
    ]);
  }

  Future<String?> getPhoneNumber() async {
    return _storage.getString(_keyPhoneNumber);
  }

  Future<String?> getBirthday() async {
    return _storage.getString(_keyBirthday);
  }

  Future<String?> getGender() async {
    return _storage.getString(_keyGender);
  }

  Future<Map<String, String?>> getAllData() async {
    return {
      'phoneNumber': await getPhoneNumber(),
      'birthday': await getBirthday(),
      'gender': await getGender(),
    };
  }

  Future<void> clearAll() async {
    await Future.wait([
      _storage.remove(_keyPhoneNumber),
      _storage.remove(_keyBirthday),
      _storage.remove(_keyGender),
    ]);
  }
}




