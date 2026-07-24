import 'package:shared_preferences/shared_preferences.dart';

class GuestPhoneStorage {
  final SharedPreferences _storage;

  GuestPhoneStorage(this._storage);

  static const String _keyGuestPhone = 'guest_phone_number';

  Future<void> savePhoneNumber(String phoneNumber) async {
    await _storage.setString(_keyGuestPhone, phoneNumber);
  }

  void savePhoneNumberSync(String phoneNumber) {
    _storage.setString(_keyGuestPhone, phoneNumber);
  }

  Future<String?> getPhoneNumber() async {
    return _storage.getString(_keyGuestPhone);
  }

  String? getPhoneNumberSync() {
    return _storage.getString(_keyGuestPhone);
  }

  Future<void> clearPhoneNumber() async {
    await _storage.remove(_keyGuestPhone);
  }
}





