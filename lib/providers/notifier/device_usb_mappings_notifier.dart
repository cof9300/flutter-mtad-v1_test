import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';

class DeviceUsbMappingsNotifier extends StateNotifier<List<DeviceUsbMapping>> {
  DeviceUsbMappingsNotifier() : super([]) {
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    final mappings = await ServiceLocator().deviceUsbMappingStorage.getMappings();
    state = mappings;
  }

  Future<void> addMapping(DeviceUsbMapping mapping) async {
    await ServiceLocator().deviceUsbMappingStorage.saveMapping(mapping);
    await _loadMappings();
    if (mapping.deviceType.toUpperCase() != 'AL') {
      await MeasurementListener().restartDevice(mapping.deviceType);
    }
  }

  Future<void> removeMapping(String deviceType) async {
    await ServiceLocator().deviceUsbMappingStorage.removeMapping(deviceType);
    await _loadMappings();
    if (deviceType.toUpperCase() == 'AL') {
      await ServiceLocator().alcoUsbService.disconnect();
    } else {
      await MeasurementListener().stopDevice(deviceType);
    }
  }

  Future<void> clearAll() async {
    await ServiceLocator().deviceUsbMappingStorage.clearAll();
    state = [];
    await MeasurementListener().stopListening();
  }

  DeviceUsbMapping? getMappingByDeviceType(String deviceType) {
    try {
      return state.firstWhere((m) => m.deviceType == deviceType);
    } catch (e) {
      return null;
    }
  }
}

final deviceUsbMappingsProvider =
    StateNotifierProvider<DeviceUsbMappingsNotifier, List<DeviceUsbMapping>>((ref) {
  return DeviceUsbMappingsNotifier();
});

