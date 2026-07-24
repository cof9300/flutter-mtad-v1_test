import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/config/service_locator.dart';

class DeviceBluetoothMappingsNotifier
    extends StateNotifier<List<DeviceBluetoothMapping>> {
  DeviceBluetoothMappingsNotifier() : super([]) {
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    final mappings =
        await ServiceLocator().deviceBluetoothMappingStorage.getMappings();
    state = mappings;
  }

  Future<void> addMapping(DeviceBluetoothMapping mapping) async {
    // 같은 타입의 기존 기기 모두 삭제 (종류별로 1개만 허용)
    final existingMappings =
        state.where((m) => m.deviceType == mapping.deviceType).toList();
    for (final existingMapping in existingMappings) {
      // 로컬 스토리지에서 삭제
      await ServiceLocator()
          .deviceBluetoothMappingStorage
          .removeMapping(existingMapping.deviceId);
      debugPrint(
          '[DeviceBluetoothMappingsNotifier] Removed existing device of same type: ${existingMapping.deviceName}');
    }

    // 새 기기 추가
    await ServiceLocator().deviceBluetoothMappingStorage.saveMapping(mapping);
    await _loadMappings();
  }

  Future<void> removeMapping(String deviceId) async {
    try {
      // 삭제할 기기 정보 가져오기
      final mapping = state.firstWhere(
        (m) => m.deviceId == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      try {
        if (mapping.deviceType.toUpperCase() == 'AL') {
          await ServiceLocator().alcoBleService.disconnectByMacAddress(mapping.macAddress);
        } else {
          await ServiceLocator().bleService.removeBond(mapping.macAddress);
        }
        debugPrint(
            '[DeviceBluetoothMappingsNotifier] Disconnected/removed bond for device: ${mapping.deviceName}');
      } catch (e) {
        debugPrint(
            '[DeviceBluetoothMappingsNotifier] Error disconnecting device: $e');
      }

      // 로컬 스토리지에서 삭제
      await ServiceLocator()
          .deviceBluetoothMappingStorage
          .removeMapping(deviceId);
      await _loadMappings();
    } catch (e) {
      debugPrint(
          '[DeviceBluetoothMappingsNotifier] Error removing mapping: $e');
      rethrow;
    }
  }

  Future<void> updateMapping(DeviceBluetoothMapping mapping) async {
    await ServiceLocator().deviceBluetoothMappingStorage.saveMapping(mapping);
    await _loadMappings();
  }

  Future<void> toggleEnabled(String deviceId) async {
    try {
      final mapping = state.firstWhere((m) => m.deviceId == deviceId);
      final newEnabledState = !mapping.isEnabled;
      final updatedMapping = mapping.copyWith(isEnabled: newEnabledState);

      if (!newEnabledState) {
        try {
          if (mapping.deviceType.toUpperCase() == 'AL') {
            await ServiceLocator().alcoBleService.disconnectByMacAddress(mapping.macAddress);
          } else {
            await ServiceLocator().bleService.disconnectByMacAddress(mapping.macAddress);
          }
          debugPrint(
              '[DeviceBluetoothMappingsNotifier] Disconnected device after disabling: ${mapping.deviceName}');
        } catch (e) {
          debugPrint(
              '[DeviceBluetoothMappingsNotifier] Error disconnecting device after disabling: $e');
        }
      }

      await updateMapping(updatedMapping);
    } catch (e) {
      // 기기를 찾을 수 없는 경우 무시
      debugPrint('Failed to toggle enabled: $e');
    }
  }

  Future<void> clearAll() async {
    await ServiceLocator().deviceBluetoothMappingStorage.clearAll();
    state = [];
  }

  List<DeviceBluetoothMapping> getMappingsByDeviceType(String deviceType) {
    return state.where((m) => m.deviceType == deviceType).toList();
  }

  DeviceBluetoothMapping? getMappingByDeviceType(String deviceType) {
    final mappings = getMappingsByDeviceType(deviceType);
    if (mappings.isEmpty) return null;
    return mappings.first;
  }

  bool isDeviceTypeEnabled(String deviceType) {
    final mappings = getMappingsByDeviceType(deviceType);
    // 해당 타입의 활성화된 기기가 하나라도 있으면 true
    return mappings.any((m) => m.isEnabled);
  }
}

final deviceBluetoothMappingsProvider = StateNotifierProvider<
    DeviceBluetoothMappingsNotifier, List<DeviceBluetoothMapping>>((ref) {
  return DeviceBluetoothMappingsNotifier();
});
