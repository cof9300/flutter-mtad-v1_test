import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/data/model/response/kiosk_option_response.dart';

class KioskOptionStorage {
  final SharedPreferences _storage;

  KioskOptionStorage(this._storage);

  static const String _keyKioskid = 'kiosk_option_kioskid';
  static const String _keyMasking = 'kiosk_option_masking';
  static const String _keyNextstep = 'kiosk_option_nextstep';
  static const String _keyWaittime = 'kiosk_option_waittime';
  static const String _keyStep = 'kiosk_option_step';
  static const String _keyPlace = 'kiosk_option_place';
  static const String _keyCompany = 'kiosk_option_company';
  static const String _keyMode = 'kiosk_option_mode';
  static const String _keyUsecert = 'kiosk_option_usecert';
  static const String _keyResulttime = 'kiosk_option_resulttime';
  static const String _keyScreentime = 'kiosk_option_screentime';
  static const String _keyCerttime = 'kiosk_option_certtime';
  static const String _keySms = 'kiosk_option_sms';
  static const String _keyDemo = 'kiosk_option_demo';
  static const String _keyFacedetect = 'kiosk_option_facedetect';
  static const String _keyVoiceinfo = 'kiosk_option_voiceinfo';
  static const String _keyResultprint = 'kiosk_option_resultprint';

  Future<void> saveOption(KioskOptionResponse option) async {
    await _storage.setString(_keyKioskid, option.kioskid);
    await _storage.setString(_keyMasking, option.masking.toString());
    await _storage.setString(_keyNextstep, option.nextstep);
    await _storage.setString(_keyWaittime, option.waittime.toString());
    await _storage.setString(_keyStep, option.step);
    await _storage.setString(_keyPlace, option.place);
    await _storage.setString(_keyCompany, option.company);
    await _storage.setString(_keyMode, option.mode.toString());
    await _storage.setString(_keyUsecert, option.usecert.toString());
    await _storage.setString(_keyResulttime, option.resulttime.toString());
    await _storage.setString(_keyScreentime, option.screentime.toString());
    await _storage.setString(_keyCerttime, option.certtime.toString());
    await _storage.setString(_keySms, option.sms.toString());
    await _storage.setString(_keyDemo, option.demo.toString());
    await _storage.setString(_keyFacedetect, option.facedetect.toString());
    await _storage.setString(_keyVoiceinfo, option.voiceinfo.toString());
    await _storage.setString(_keyResultprint, option.resultprint.toString());
  }

  Future<KioskOptionResponse?> getOption() async {
    final kioskid = _storage.getString(_keyKioskid);
    final masking = _storage.getString(_keyMasking);
    final nextstep = _storage.getString(_keyNextstep);
    final waittime = _storage.getString(_keyWaittime);
    final step = _storage.getString(_keyStep);
    final place = _storage.getString(_keyPlace);
    final company = _storage.getString(_keyCompany);
    final mode = _storage.getString(_keyMode);
    final usecert = _storage.getString(_keyUsecert);
    final resulttime = _storage.getString(_keyResulttime);
    final screentime = _storage.getString(_keyScreentime);
    final certtime = _storage.getString(_keyCerttime);
    final sms = _storage.getString(_keySms);
    final demo = _storage.getString(_keyDemo);
    final facedetect = _storage.getString(_keyFacedetect);
    final voiceinfo = _storage.getString(_keyVoiceinfo);
    final resultprint = _storage.getString(_keyResultprint);

    if (kioskid == null) return null;

    return KioskOptionResponse(
      kioskid: kioskid,
      masking: masking == 'true',
      nextstep: nextstep!,
      waittime: int.parse(waittime!),
      step: step!,
      place: place!,
      company: company!,
      mode: int.parse(mode!),
      usecert: int.parse(usecert!),
      resulttime: int.parse(resulttime!),
      screentime: int.parse(screentime!),
      certtime: int.parse(certtime!),
      sms: int.parse(sms!),
      demo: int.parse(demo!),
      facedetect: int.parse(facedetect!),
      voiceinfo: int.parse(voiceinfo!),
      resultprint: int.parse(resultprint!),
    );
  }

  Future<void> deleteOption() async {
    await _storage.remove(_keyKioskid);
    await _storage.remove(_keyMasking);
    await _storage.remove(_keyNextstep);
    await _storage.remove(_keyWaittime);
    await _storage.remove(_keyStep);
    await _storage.remove(_keyPlace);
    await _storage.remove(_keyCompany);
    await _storage.remove(_keyMode);
    await _storage.remove(_keyUsecert);
    await _storage.remove(_keyResulttime);
    await _storage.remove(_keyScreentime);
    await _storage.remove(_keyCerttime);
    await _storage.remove(_keySms);
    await _storage.remove(_keyDemo);
    await _storage.remove(_keyFacedetect);
    await _storage.remove(_keyVoiceinfo);
    await _storage.remove(_keyResultprint);
  }
}
