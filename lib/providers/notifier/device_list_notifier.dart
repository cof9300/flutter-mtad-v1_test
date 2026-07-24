import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/device.dart';

class DeviceListNotifier extends StateNotifier<List<Device>> {
  DeviceListNotifier() : super([]);

  void setDevices(List<Device> devices) {
    state = devices;
  }

  void clearDevices() {
    state = [];
  }
}

final deviceListProvider =
    StateNotifierProvider<DeviceListNotifier, List<Device>>((ref) {
  return DeviceListNotifier();
});
















