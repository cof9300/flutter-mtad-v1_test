import 'package:flutter_template/data/repository/usb_repository.dart';
import 'package:flutter_template/data/local/device_usb_mapping_storage.dart';

class UsbService {
  final UsbRepository _usbRepository;
  final DeviceUsbMappingStorage _mappingStorage;

  UsbService(this._usbRepository, this._mappingStorage);

  Stream<List<dynamic>> get devicesStream => _usbRepository.devicesStream;

  Future<List<dynamic>> getAvailableDevices() {
    return _usbRepository.getAvailableDevices();
  }

  void startDeviceScanning({Duration interval = const Duration(seconds: 2)}) {
    _usbRepository.startDeviceScanning(interval: interval);
  }

  void stopDeviceScanning() {
    _usbRepository.stopDeviceScanning();
  }

  Future<bool> isDeviceConnected(String deviceType) async {
    final mapping = await _mappingStorage.getMappingByDeviceType(deviceType);
    if (mapping == null) return false;
    return _usbRepository.isDeviceConnected(
      vid: mapping.vid,
      pid: mapping.pid,
      portName: mapping.portName,
    );
  }

  void dispose() {
    _usbRepository.dispose();
  }
}






