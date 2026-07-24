import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/data/model/rich_text_content.dart';
import 'dart:convert';

class RichTextStorageService {
  static const String _keyPrefix = 'rich_text_';
  static const String _allKeysKey = 'rich_text_all_keys';

  final SharedPreferences _prefs;

  RichTextStorageService(this._prefs) {
    _initializeDefaults();
  }

  void _initializeDefaults() {
    final keys = _getAllKeys();
    if (!keys.contains('auth_title')) {
      _saveRichText(RichTextContent(
        key: 'auth_title',
        koText: '<b>사용자 번호</b> 또는 <b>휴대폰 번호</b>를 입력해주세요!',
        enText: 'Please enter your <b>user number</b> or <b>phone number</b>!',
        zhText: '请输入您的<b>用户编号</b>或<b>手机号码</b>！',
        viText: 'Vui lòng nhập <b>số người dùng</b> hoặc <b>số điện thoại</b>!',
        updatedAt: DateTime.now(),
      ));
    }
    if (!keys.contains('guest_phone_title')) {
      _saveRichText(RichTextContent(
        key: 'guest_phone_title',
        koText: '<b>휴대폰 번호</b>를 입력해주세요.\n<b>측정 결과</b>가 휴대폰으로 전송됩니다.',
        enText: 'Please enter your <b>phone number</b>.\n<b>Measurement results</b> will be sent to your phone.',
        zhText: '请输入您的<b>手机号码</b>。\n<b>测量结果</b>将发送到您的手机。',
        viText: 'Vui lòng nhập <b>số điện thoại</b> của bạn.\n<b>Kết quả đo</b> sẽ được gửi đến điện thoại của bạn.',
        updatedAt: DateTime.now(),
      ));
    }
  }

  List<String> _getAllKeys() {
    return _prefs.getStringList(_allKeysKey) ?? [];
  }

  Future<void> _saveAllKeys(List<String> keys) async {
    await _prefs.setStringList(_allKeysKey, keys);
  }

  Future<void> _saveRichText(RichTextContent content) async {
    final json = jsonEncode(content.toMap());
    await _prefs.setString('$_keyPrefix${content.key}', json);

    final keys = _getAllKeys();
    if (!keys.contains(content.key)) {
      keys.add(content.key);
      await _saveAllKeys(keys);
    }
  }

  Future<RichTextContent?> getRichTextByKey(String key) async {
    final json = _prefs.getString('$_keyPrefix$key');
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return RichTextContent.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<List<RichTextContent>> getAllRichTexts() async {
    final keys = _getAllKeys();
    final List<RichTextContent> contents = [];

    for (final key in keys) {
      final content = await getRichTextByKey(key);
      if (content != null) {
        contents.add(content);
      }
    }

    return contents;
  }

  Future<void> updateRichText(RichTextContent content) async {
    await _saveRichText(content);
  }

  Future<void> deleteRichText(String key) async {
    await _prefs.remove('$_keyPrefix$key');

    final keys = _getAllKeys();
    keys.remove(key);
    await _saveAllKeys(keys);
  }
}















