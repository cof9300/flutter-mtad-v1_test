import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDeviceNotifier extends StateNotifier<String?> {
  SelectedDeviceNotifier() : super(null);

  void selectDevice(String deviceType) {
    state = deviceType;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedDeviceProvider =
    StateNotifierProvider<SelectedDeviceNotifier, String?>((ref) {
  return SelectedDeviceNotifier();
});















