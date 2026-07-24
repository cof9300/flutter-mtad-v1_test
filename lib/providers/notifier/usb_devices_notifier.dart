import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/usb_device_info.dart';
import 'package:flutter_template/config/service_locator.dart';

class UsbDevicesNotifier extends StateNotifier<List<UsbDeviceInfo>> {
  UsbDevicesNotifier() : super([]) {
    _init();
  }

  void _init() {
    final usbService = ServiceLocator().usbService;
    usbService.devicesStream.listen((devices) {
      state = List<UsbDeviceInfo>.from(devices);
    });
    usbService.startDeviceScanning();
  }

  @override
  void dispose() {
    ServiceLocator().usbService.stopDeviceScanning();
    super.dispose();
  }
}

final usbDevicesProvider =
    StateNotifierProvider<UsbDevicesNotifier, List<UsbDeviceInfo>>((ref) {
  return UsbDevicesNotifier();
});

