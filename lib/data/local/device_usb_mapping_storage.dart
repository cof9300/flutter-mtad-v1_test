import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';

class DeviceUsbMappingStorage {
  final SharedPreferences _prefs;
  static const String _mappingKey = 'device_usb_mappings';

  DeviceUsbMappingStorage(this._prefs);

  Future<List<DeviceUsbMapping>> getMappings() async {
    try {
      final jsonString = _prefs.getString(_mappingKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => DeviceUsbMapping.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMappings(List<DeviceUsbMapping> mappings) async {
    final jsonList = mappings.map((mapping) => mapping.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_mappingKey, jsonString);
  }

  Future<void> saveMapping(DeviceUsbMapping mapping) async {
    final mappings = await getMappings();
    final index = mappings.indexWhere((m) => m.deviceType == mapping.deviceType);
    if (index >= 0) {
      mappings[index] = mapping;
    } else {
      mappings.add(mapping);
    }
    await saveMappings(mappings);
  }

  Future<void> removeMapping(String deviceType) async {
    final mappings = await getMappings();
    mappings.removeWhere((m) => m.deviceType == deviceType);
    await saveMappings(mappings);
  }

  Future<DeviceUsbMapping?> getMappingByDeviceType(String deviceType) async {
    final mappings = await getMappings();
    try {
      return mappings.firstWhere((m) => m.deviceType == deviceType);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _prefs.remove(_mappingKey);
  }
}















