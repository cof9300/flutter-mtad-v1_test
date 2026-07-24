import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_template/config/alco_bluetooth_constants.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';

enum AlcoBleConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class AlcoBleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Timer? _reconnectTimer;

  final StreamController<AlcoBleConnectionStatus> _statusController =
      StreamController<AlcoBleConnectionStatus>.broadcast();

  final StreamController<AlcoNotification> _notificationController =
      StreamController<AlcoNotification>.broadcast();

  AlcoBleConnectionStatus _currentStatus = AlcoBleConnectionStatus.disconnected;

  BluetoothAdapterState? _lastAdapterState;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<AlcoBleConnectionStatus> get connectionStatusStream => _statusController.stream;
  Stream<AlcoNotification> get alcoNotificationStream => _notificationController.stream;
  AlcoBleConnectionStatus get currentStatus => _currentStatus;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  AlcoBleService() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _lastAdapterState = state;
    });

    _statusController.stream.listen((status) async {
      if (status == AlcoBleConnectionStatus.connected && _connectedDevice != null) {
        try {
          await Future.delayed(
            const Duration(milliseconds: AlcoBluetoothConstants.connectionStabilizeMs),
          );
          await setupAlcoService();
        } catch (e) {
          debugPrint('[AlcoBleService] Error setting up alco service on connect: $e');
        }
      } else if (status == AlcoBleConnectionStatus.disconnected) {
        await _notifySubscription?.cancel();
        _notifySubscription = null;
        _writeChar = null;
      }
    });

    _startPeriodicReconnect();
  }

  void _startPeriodicReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      const Duration(seconds: AlcoBluetoothConstants.periodicReconnectSeconds),
      (timer) async {
        try {
          if (_connectedDevice != null && _connectedDevice!.isConnected) return;
          await tryConnectSavedAlcoDevice();
        } catch (e) {
          debugPrint('[AlcoBleService] Error in periodic reconnect: $e');
        }
      },
    );
    tryConnectSavedAlcoDevice();
  }

  Future<void> waitForAdapterOn() async {
    final current = _lastAdapterState ?? await FlutterBluePlus.adapterState.first;
    if (current == BluetoothAdapterState.on) return;
    await FlutterBluePlus.adapterState.firstWhere((s) => s == BluetoothAdapterState.on);
  }

  Future<bool> requestPermissions() async {
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final allGranted = statuses.values.every((s) => s.isGranted);
      if (!allGranted) {
        final locationStatus = await Permission.location.request();
        return locationStatus.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> scanForAlcoDevices() async {
    final foundDevices = <String, BluetoothDevice>{};
    final processedIds = <String>{};
    StreamSubscription<List<ScanResult>>? subscription;

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: AlcoBluetoothConstants.scanTimeoutSeconds),
      );

      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final device = result.device;
          final id = device.remoteId.str;
          if (processedIds.contains(id)) continue;
          processedIds.add(id);

          final name = device.platformName.toUpperCase();
          if (name.startsWith(AlcoBluetoothConstants.scanNamePrefix.toUpperCase())) {
            foundDevices[id] = device;
          }
        }
      });

      await Future.delayed(
        const Duration(seconds: AlcoBluetoothConstants.scanTimeoutSeconds),
      );
    } finally {
      await subscription?.cancel();
      await FlutterBluePlus.stopScan();
    }

    return foundDevices.values.toList();
  }

  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }

  Future<void> connect(BluetoothDevice device, {required bool autoConnect}) async {
    try {
      _connectionStateSubscription?.cancel();
      _connectedDevice = device;
      _updateStatus(AlcoBleConnectionStatus.connecting);

      _connectionStateSubscription = device.connectionState.listen((state) {
        _handleConnectionStateChange(device, state);
      });

      if (device.isConnected) {
        _updateStatus(AlcoBleConnectionStatus.connected);
        return;
      }

      await device.connect(autoConnect: autoConnect, mtu: null, license: License.free);
    } catch (e) {
      _connectedDevice = null;
      _updateStatus(AlcoBleConnectionStatus.disconnected);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) return;
    try {
      _updateStatus(AlcoBleConnectionStatus.disconnecting);
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeChar = null;
      _updateStatus(AlcoBleConnectionStatus.disconnected);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnectByMacAddress(String macAddress) async {
    try {
      if (_connectedDevice != null && _connectedDevice!.remoteId.str == macAddress) {
        await disconnect();
      }
    } catch (_) {}
  }

  Future<void> removeBond(String macAddress) async {
    try {
      if (_connectedDevice != null && _connectedDevice!.remoteId.str == macAddress) {
        await disconnect();
      }
      final device = BluetoothDevice.fromId(macAddress);
      await device.removeBond();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null || !_connectedDevice!.isConnected) {
      throw Exception('No alco device connected');
    }
    return await _connectedDevice!.discoverServices();
  }

  Future<void> setupAlcoService() async {
    try {
      if (_connectedDevice == null || !_connectedDevice!.isConnected) {
        debugPrint('[AlcoBleService] No device connected for service setup');
        return;
      }

      final services = await discoverServices();

      BluetoothService? alcoService;
      for (final service in services) {
        if (service.uuid.toString().toUpperCase().contains(
          AlcoBluetoothConstants.serviceUuid.toUpperCase(),
        )) {
          alcoService = service;
          break;
        }
      }

      if (alcoService == null) {
        debugPrint('[AlcoBleService] FFE0 service not found');
        return;
      }

      BluetoothCharacteristic? notifyChar;
      BluetoothCharacteristic? writeChar;

      for (final char in alcoService.characteristics) {
        final uuid = char.uuid.toString().toUpperCase();
        if (uuid.contains(AlcoBluetoothConstants.notifyCharUuid.toUpperCase())) {
          notifyChar = char;
        }
        if (uuid.contains(AlcoBluetoothConstants.writeCharUuid.toUpperCase())) {
          writeChar = char;
        }
      }

      if (notifyChar != null) {
        await _notifySubscription?.cancel();
        await notifyChar.setNotifyValue(true);
        _notifySubscription = notifyChar.onValueReceived.listen((data) {
          if (data.isNotEmpty) {
            _handleNotification(data);
          }
        });
        debugPrint('[AlcoBleService] Subscribed to DA01 notify');
      }

      if (writeChar != null) {
        _writeChar = writeChar;
        final packet = _buildStandbyPacket();
        await writeChar.write(packet);
        debugPrint('[AlcoBleService] Sent Standby command via DA20');
      }
    } catch (e) {
      debugPrint('[AlcoBleService] Error in setupAlcoService: $e');
    }
  }

  List<int> _buildStandbyPacket() {
    final now = DateTime.now();
    final year = now.year;
    return [
      AlcoBluetoothConstants.cmdStandby,
      (year >> 8) & 0xFF,
      year & 0xFF,
      now.month,
      now.day,
      now.hour,
      now.minute,
      AlcoBluetoothConstants.defaultAlarmLimit,
      AlcoBluetoothConstants.defaultUnit,
    ];
  }

  Future<void> sendWarmUpCommand() async {
    if (_writeChar == null) throw Exception('Write characteristic not available');
    await _writeChar!.write(_buildWarmUpPacket());
    debugPrint('[AlcoBleService] Sent WarmUp command via DA20');
  }

  List<int> _buildWarmUpPacket() {
    final now = DateTime.now();
    final year = now.year;
    return [
      AlcoBluetoothConstants.cmdWarmUp,
      (year >> 8) & 0xFF,
      year & 0xFF,
      now.month,
      now.day,
      now.hour,
      now.minute,
      AlcoBluetoothConstants.defaultAlarmLimit,
      AlcoBluetoothConstants.defaultUnit,
    ];
  }

  void _handleNotification(List<int> data) {
    if (data.isEmpty) return;
    final notification = AlcoNotification.fromBytes(data);
    _notificationController.add(notification);

    final hex = data
        .asMap()
        .entries
        .map((e) => '[${e.key}]:0x${e.value.toRadixString(16).padLeft(2, '0')}')
        .join(' ');
    debugPrint('[AlcoBleService] PKT state=0x${notification.stateCode.toRadixString(16)} len=${data.length}: $hex');

    if (notification.stateCode == AlcoBluetoothConstants.stateResult ||
        notification.stateCode == AlcoBluetoothConstants.stateError) {
      debugPrint('[AlcoBleService] RESULT BYTES len=${data.length}: $hex');
      for (int i = 0; i + 1 < data.length; i++) {
        final pair = ((data[i] & 0xFF) << 8) | (data[i + 1] & 0xFF);
        final bac = pair / 10000.0;
        if (pair > 0 && bac < 1.0) {
          debugPrint('[AlcoBleService] Candidate BAC at byte[$i-${i+1}]: raw=$pair → $bac%');
        }
      }
      if (data.length >= 16) {
        final b13 = data[13] & 0xFF;
        final b14 = data[14] & 0xFF;
        final b15 = data[15] & 0xFF;
        final bacRaw = (b13 << 8) | b14;
        debugPrint(
          '[AlcoBleService] 0x09 파싱 — '
          'byte[13]=0x${b13.toRadixString(16).padLeft(2, '0')} '
          'byte[14]=0x${b14.toRadixString(16).padLeft(2, '0')} '
          'byte[15]=0x${b15.toRadixString(16).padLeft(2, '0')} '
          '→ BAC raw=$bacRaw (${(bacRaw / 10000.0).toStringAsFixed(4)}%), '
          'error=0x${b15.toRadixString(16)}',
        );
      }
    }

    debugPrint(
      '[AlcoBleService] Notification — state: 0x${notification.stateCode.toRadixString(16)}, '
      'rawBac: ${notification.rawBacValue}, '
      'bacValue: ${(notification.rawBacValue / 10000.0).toStringAsFixed(4)}%, '
      'error: 0x${notification.errorCode.toRadixString(16)}',
    );
  }

  Future<void> tryConnectSavedAlcoDevice() async {
    try {
      final storage = ServiceLocator().deviceBluetoothMappingStorage;
      final alMappings = await storage.getMappingsByDeviceType('AL');

      if (_connectedDevice != null && _connectedDevice!.isConnected) {
        final macAddress = _connectedDevice!.remoteId.str;
        final mapping = alMappings.firstWhere(
          (m) => m.macAddress == macAddress,
          orElse: () => DeviceBluetoothMapping(
            deviceType: 'AL',
            deviceName: 'Unknown',
            macAddress: macAddress,
            deviceId: macAddress,
            isEnabled: false,
          ),
        );
        if (!mapping.isEnabled) {
          debugPrint('[AlcoBleService] Connected AL device is disabled, disconnecting');
          await disconnect();
        } else {
          return;
        }
      }

      final enabledMappings = alMappings.where((m) => m.isEnabled).toList();
      if (enabledMappings.isEmpty) return;

      for (final mapping in enabledMappings) {
        try {
          final device = BluetoothDevice.fromId(mapping.macAddress);
          debugPrint('[AlcoBleService] Attempting auto-connect to: ${mapping.deviceName}');
          await connect(device, autoConnect: true);
          break;
        } catch (e) {
          debugPrint('[AlcoBleService] Auto-connect failed for ${mapping.deviceName}: $e');
        }
      }
    } catch (e) {
      debugPrint('[AlcoBleService] Error in tryConnectSavedAlcoDevice: $e');
    }
  }

  void _handleConnectionStateChange(
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) {
    switch (state) {
      case BluetoothConnectionState.connected:
        _updateStatus(AlcoBleConnectionStatus.connected);
        break;
      case BluetoothConnectionState.disconnected:
        if (_currentStatus == AlcoBleConnectionStatus.connecting) break;
        if (_connectedDevice?.remoteId.str == device.remoteId.str) {
          _connectedDevice = null;
          _updateStatus(AlcoBleConnectionStatus.disconnected);
        }
        break;
      case BluetoothConnectionState.connecting:
        _updateStatus(AlcoBleConnectionStatus.connecting);
        break;
      case BluetoothConnectionState.disconnecting:
        _updateStatus(AlcoBleConnectionStatus.disconnecting);
        break;
    }
  }

  void _updateStatus(AlcoBleConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _notifySubscription?.cancel();
    _reconnectTimer?.cancel();
    _connectedDevice?.clearGattCache();
    _connectedDevice?.disconnect();
    _statusController.close();
    _notificationController.close();
  }
}
