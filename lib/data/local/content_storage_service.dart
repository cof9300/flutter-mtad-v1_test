import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/data/model/response/wait_page_option_response.dart';
import 'package:flutter_template/data/model/response/result_page_option_response.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';
import 'dart:convert';

class ContentStorageService {
  static const String _keyWaitPageOption = 'stored_wait_page_option';
  static const String _keyResultPageOption = 'stored_result_page_option';
  static const String _keyAgreementOption = 'stored_agreement_option';
  static const String _keyHeaderTitle = 'stored_header_title';
  static const String _keyHeaderLogo = 'stored_header_logo';
  static const String _keyPrinterLogo = 'stored_printer_logo';

  final SharedPreferences _prefs;

  ContentStorageService(this._prefs);

  Future<void> clearAllStoredContent() async {
    final directory = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${directory.path}/kiosk_content');
    if (await storageDir.exists()) {
      await storageDir.delete(recursive: true);
    }

    await _prefs.remove(_keyWaitPageOption);
    await _prefs.remove(_keyResultPageOption);
    await _prefs.remove(_keyAgreementOption);
    await _prefs.remove(_keyHeaderTitle);
    await _prefs.remove(_keyHeaderLogo);
    await _prefs.remove(_keyPrinterLogo);

    // device page option 키도 모두 삭제 (파일은 위에서 이미 삭제됨)
    final deviceOptionKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith('stored_device_page_option_'))
        .toList();
    for (final key in deviceOptionKeys) {
      await _prefs.remove(key);
    }
  }

  Future<String?> _downloadAndSaveFile(String url, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${directory.path}/kiosk_content');
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    final fullUrl = url.startsWith('http') ? url : '${Config.baseUrl}$url';
    final file = File('${storageDir.path}/$filename');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(fullUrl));
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 404) {
        await streamedResponse.stream.drain<void>();
        return null;
      }

      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to download file: ${streamedResponse.statusCode}');
      }

      final sink = file.openWrite();
      await streamedResponse.stream.pipe(sink);
      await sink.close();
    } finally {
      client.close();
    }

    return file.path;
  }

  Future<void> saveWaitPageOption(WaitPageOptionResponse option) async {
    final cmFutures = option.cm.asMap().entries.map((e) async {
      final filename = 'wait_content_${e.key}${_getFileExtension(e.value.path)}';
      final localPath = await _downloadAndSaveFile(e.value.path, filename);
      if (localPath == null) return null;
      return <String, dynamic>{
        'path': localPath,
        'playtime': e.value.playtime,
        'sound': e.value.sound,
      };
    }).toList();

    final cachedContents = (await Future.wait(cmFutures))
        .whereType<Map<String, dynamic>>()
        .toList();

    final cacheData = {
      'title': option.title,
      'logo': option.logo,
      'printerlogo': option.printerlogo,
      'cm': cachedContents,
    };

    await _prefs.setString(_keyWaitPageOption, jsonEncode(cacheData));

    if (option.title.isNotEmpty) {
      await _prefs.setString(_keyHeaderTitle, option.title);
    }
    if (option.logo.isNotEmpty) {
      await _prefs.setString(_keyHeaderLogo, option.logo);
    }
    if (option.printerlogo.isNotEmpty) {
      await _prefs.setString(_keyPrinterLogo, option.printerlogo);
    }
  }

  Future<void> saveResultPageOption(ResultPageOptionResponse option) async {
    final cmFutures = option.cm.asMap().entries.map((e) async {
      final filename = 'result_content_${e.key}${_getFileExtension(e.value.path)}';
      final localPath = await _downloadAndSaveFile(e.value.path, filename);
      if (localPath == null) return null;
      return <String, dynamic>{
        'path': localPath,
        'playtime': e.value.playtime,
        'sound': e.value.sound,
      };
    }).toList();

    final cachedContents = (await Future.wait(cmFutures))
        .whereType<Map<String, dynamic>>()
        .toList();

    await _prefs.setString(_keyResultPageOption, jsonEncode({
      'masking': option.masking,
      'cm': cachedContents,
    }));
  }

  Future<void> saveDevicePageOption(String deviceType, DevicePageOptionResponse option) async {
    final menualFutures = option.menual.asMap().entries.map((e) async {
      final filename = '${deviceType}_menual_${e.key}${_getFileExtension(e.value.path)}';
      final localPath = await _downloadAndSaveFile(e.value.path, filename);
      if (localPath == null) return null;
      return <String, dynamic>{
        'path': localPath,
        'playtime': e.value.playtime,
        'sound': e.value.sound,
      };
    }).toList();

    final cmFutures = option.cm.asMap().entries.map((e) async {
      final filename = '${deviceType}_cm_${e.key}${_getFileExtension(e.value.path)}';
      final localPath = await _downloadAndSaveFile(e.value.path, filename);
      if (localPath == null) return null;
      return <String, dynamic>{
        'path': localPath,
        'playtime': e.value.playtime,
        'sound': e.value.sound,
      };
    }).toList();

    final cachedMenual = (await Future.wait(menualFutures))
        .whereType<Map<String, dynamic>>()
        .toList();
    final cachedCm = (await Future.wait(cmFutures))
        .whereType<Map<String, dynamic>>()
        .toList();

    await _prefs.setString('stored_device_page_option_$deviceType', jsonEncode({
      'menual': cachedMenual,
      'cm': cachedCm,
      'waittime': option.waittime,
    }));
  }

  String _getFileExtension(String path) {
    final uri = Uri.parse(path);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return '';
    final filename = pathSegments.last;
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filename.substring(lastDot);
  }

  WaitPageOptionResponse? getStoredWaitPageOption() {
    final json = _prefs.getString(_keyWaitPageOption);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return WaitPageOptionResponse(
        title: map['title'] as String? ?? '',
        logo: map['logo'] as String? ?? '',
        printerlogo: map['printerlogo'] as String? ?? '',
        cm: (map['cm'] as List<dynamic>?)
                ?.map((item) => WaitPageContent.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      return null;
    }
  }

  ResultPageOptionResponse? getStoredResultPageOption() {
    final json = _prefs.getString(_keyResultPageOption);
    if (json == null) {
      print('[ContentStorage] No stored result page option found');
      return null;
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      print('[ContentStorage] Loaded result page option: cm count=${(map['cm'] as List?)?.length ?? 0}');
      final wrappedData = {'resultData': map};
      return ResultPageOptionResponse.fromJson(wrappedData);
    } catch (e) {
      print('[ContentStorage] Error loading result page option: $e');
      return null;
    }
  }

  String? getStoredHeaderTitle() {
    return _prefs.getString(_keyHeaderTitle);
  }

  String? getStoredHeaderLogo() {
    return _prefs.getString(_keyHeaderLogo);
  }

  String? getStoredPrinterLogo() {
    return _prefs.getString(_keyPrinterLogo);
  }

  Future<void> saveAgreementOption(AgreementOptionResponse option) async {
    final downloads = <String, Future<String?>>{};

    if (option.agreeimage1.isNotEmpty) {
      downloads['agreeimage1'] = _downloadAndSaveFile(
          option.agreeimage1, 'agreement_image_1${_getFileExtension(option.agreeimage1)}');
    }
    if (option.agreeimage2.isNotEmpty) {
      downloads['agreeimage2'] = _downloadAndSaveFile(
          option.agreeimage2, 'agreement_image_2${_getFileExtension(option.agreeimage2)}');
    }
    if (option.agreeimage3.isNotEmpty) {
      downloads['agreeimage3'] = _downloadAndSaveFile(
          option.agreeimage3, 'agreement_image_3${_getFileExtension(option.agreeimage3)}');
    }
    if (option.agreeimage4.isNotEmpty) {
      downloads['agreeimage4'] = _downloadAndSaveFile(
          option.agreeimage4, 'agreement_image_4${_getFileExtension(option.agreeimage4)}');
    }

    final paths = await Future.wait(downloads.values);
    final localPaths = Map.fromIterables(downloads.keys, paths);

    await _prefs.setString(_keyAgreementOption, jsonEncode({
      'agreeimage1': localPaths['agreeimage1'] ?? '',
      'agreeimage2': localPaths['agreeimage2'] ?? '',
      'agreeimage3': localPaths['agreeimage3'] ?? '',
      'agreeimage4': localPaths['agreeimage4'] ?? '',
    }));
  }

  AgreementOptionResponse? getStoredAgreementOption() {
    final json = _prefs.getString(_keyAgreementOption);
    if (json == null) {
      print('[ContentStorage] No stored agreement option found');
      return null;
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      print('[ContentStorage] Loaded agreement option');
      final wrappedData = {'resultData': map};
      return AgreementOptionResponse.fromJson(wrappedData);
    } catch (e) {
      print('[ContentStorage] Error loading agreement option: $e');
      return null;
    }
  }

  DevicePageOptionResponse? getStoredDevicePageOption(String deviceType) {
    final json = _prefs.getString('stored_device_page_option_$deviceType');
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final resultData = {'resultData': map};
      return DevicePageOptionResponse.fromJson(resultData);
    } catch (e) {
      return null;
    }
  }
}
