import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';

class DeviceBluetoothMappingStorage {
  final SharedPreferences _prefs;
  static const String _mappingKey = 'device_bluetooth_mappings';

  DeviceBluetoothMappingStorage(this._prefs);

  Future<List<DeviceBluetoothMapping>> getMappings() async {
    try {
      final jsonString = _prefs.getString(_mappingKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => DeviceBluetoothMapping.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMappings(List<DeviceBluetoothMapping> mappings) async {
    final jsonList = mappings.map((mapping) => mapping.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_mappingKey, jsonString);
  }

  Future<void> saveMapping(DeviceBluetoothMapping mapping) async {
    final mappings = await getMappings();
    // 같은 deviceId가 이미 있으면 업데이트, 없으면 추가
    final index = mappings.indexWhere((m) => m.deviceId == mapping.deviceId);
    if (index >= 0) {
      mappings[index] = mapping;
    } else {
      mappings.add(mapping);
    }
    await saveMappings(mappings);
  }

  Future<void> removeMapping(String deviceId) async {
    final mappings = await getMappings();
    mappings.removeWhere((m) => m.deviceId == deviceId);
    await saveMappings(mappings);
  }

  Future<List<DeviceBluetoothMapping>> getMappingsByDeviceType(String deviceType) async {
    final mappings = await getMappings();
    return mappings.where((m) => m.deviceType == deviceType).toList();
  }

  Future<DeviceBluetoothMapping?> getMappingByDeviceType(String deviceType) async {
    final mappings = await getMappingsByDeviceType(deviceType);
    if (mappings.isEmpty) return null;
    return mappings.first;
  }

  Future<void> clearAll() async {
    await _prefs.remove(_mappingKey);
  }
}
