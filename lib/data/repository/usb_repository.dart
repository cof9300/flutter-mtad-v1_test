import 'dart:async';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/data/model/usb_device_info.dart';

class UsbRepository {
  Timer? _scanTimer;
  final StreamController<List<UsbDeviceInfo>> _devicesController =
      StreamController<List<UsbDeviceInfo>>.broadcast();

  Stream<List<UsbDeviceInfo>> get devicesStream => _devicesController.stream;

  Future<List<UsbDeviceInfo>> getAvailableDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      final deviceInfoList = devices
          .map((device) => UsbDeviceInfo(
                portName: device.deviceName,
                vid: device.vid ?? 0,
                pid: device.pid ?? 0,
                deviceName: device.deviceName,
                productName: device.productName,
                manufacturerName: device.manufacturerName,
              ))
          .toList();
      _devicesController.add(deviceInfoList);
      return deviceInfoList;
    } catch (e) {
      _devicesController.add([]);
      return [];
    }
  }

  void startDeviceScanning({Duration interval = const Duration(seconds: 2)}) {
    _scanTimer?.cancel();
    getAvailableDevices();
    _scanTimer = Timer.periodic(interval, (_) {
      getAvailableDevices();
    });
  }

  void stopDeviceScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  Future<bool> isDeviceConnected({
    required int vid,
    required int pid,
    String? portName,
  }) async {
    try {
      final devices = await UsbSerial.listDevices();
      // 재부팅 시 Android가 USB 경로를 재할당하므로 VID/PID만으로 연결 여부 확인
      return devices.any((device) => device.vid == vid && device.pid == pid);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    stopDeviceScanning();
    _devicesController.close();
  }
}






