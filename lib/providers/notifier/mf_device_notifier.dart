import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/device.dart';

class MfDeviceNotifier extends StateNotifier<Device?> {
  MfDeviceNotifier() : super(null);

  void setDevice(Device device) {
    state = device;
  }

  void clearDevice() {
    state = null;
  }
}

final mfDeviceProvider =
    StateNotifierProvider<MfDeviceNotifier, Device?>((ref) {
  return MfDeviceNotifier();
});
