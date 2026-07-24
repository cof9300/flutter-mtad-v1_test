import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_template/config/bluetooth_constants.dart';
import 'package:flutter_template/core/utils/omron_bp_parser.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/services/optimized_network_logger.dart';
import 'dart:convert';

enum BleConnectionStatus { disconnected, connecting, connected, disconnecting }

class BleService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _bpDataSubscription;
  Timer? _connectionTimer;

  final StreamController<BleConnectionStatus> _connectionStatusController =
      StreamController<BleConnectionStatus>.broadcast();

  BleConnectionStatus _currentStatus = BleConnectionStatus.disconnected;
  
  DateTime? _lastDataTime;
  BloodPressureResult? _lastData;
  
  final List<BloodPressureResult> _dataBuffer = [];
  Timer? _dataBufferTimer;
  static const Duration _dataBufferWaitDuration = Duration(seconds: 2);

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Stream<BleConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  BleConnectionStatus get currentStatus => _currentStatus;

  bool get isConnected => _connectedDevice?.isConnected ?? false;

  BluetoothAdapterState? _lastAdapterState;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  BleService() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _lastAdapterState = state;
    });
    
    // 연결 상태 변경 시 자동으로 혈압 서비스 설정
    _connectionStatusController.stream.listen((status) async {
      if (status == BleConnectionStatus.connected && _connectedDevice != null) {
        // 연결된 기기가 혈압계인지 확인 (서비스 UUID로 확인)
        try {
          await Future.delayed(const Duration(milliseconds: 1000)); // 연결 안정화 대기
          final services = await discoverServices();
          bool isBloodPressureDevice = false;
          for (var service in services) {
            final uuid = service.uuid.toString().toUpperCase();
            if (uuid.contains(BluetoothConstants.bloodPressureServiceUuid)) {
              isBloodPressureDevice = true;
              break;
            }
          }
          
          if (isBloodPressureDevice) {
            debugPrint('[BleService] Blood pressure device detected, setting up BP service...');
            await setupBloodPressureService();
          }
        } catch (e) {
          debugPrint('[BleService] Error auto-setting up BP service: $e');
        }
      } else if (status == BleConnectionStatus.disconnected) {
        await _bpDataSubscription?.cancel();
        _bpDataSubscription = null;
        // _dataBufferTimer는 취소하지 않음:
        // OMRON 등 BLE 혈압계는 데이터 전송 직후 연결을 끊는 경우가 많아,
        // 타이머를 여기서 취소하면 버퍼에 쌓인 측정 결과가 유실됨.
        // 타이머가 만료되면 _processBufferedData가 결과를 처리하고 버퍼를 초기화함.
      }
    });
    
    // 전역으로 주기적으로 혈압계 연결 시도 시작
    _startPeriodicBpConnection();
  }
  
  /// 전역으로 주기적으로 혈압계 연결 시도 시작
  ///
  /// 활성화된 혈압계가 있으면 주기적으로 연결을 시도합니다.
  void _startPeriodicBpConnection() {
    _connectionTimer?.cancel();
    
    // 5초마다 연결 시도
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // 이미 연결되어 있으면 스킵
        if (_connectedDevice != null && _connectedDevice!.isConnected) {
          return;
        }
        
        await tryConnectSavedBloodPressureDevices();
      } catch (e) {
        debugPrint('[BleService] Error in periodic BP connection: $e');
      }
    });
    
    // 즉시 한 번 시도
    tryConnectSavedBloodPressureDevices();
  }

  Future<void> waitForAdapterOn() async {
    final current =
        _lastAdapterState ?? await FlutterBluePlus.adapterState.first;
    if (current == BluetoothAdapterState.on) {
      return;
    }

    await FlutterBluePlus.adapterState.firstWhere(
      (s) => s == BluetoothAdapterState.on,
    );
  }

  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          return false;
        }
      }

      return allGranted;
    } catch (e) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluePlus.bondedDevices;
    } catch (e) {
      return [];
    }
  }

  Future<List<BluetoothDevice>> scanForOmronDevices() async {
    final foundDevices = <String, BluetoothDevice>{};
    final processedDevices = <String>{};

    StreamSubscription<List<ScanResult>>? subscription;

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final device = result.device;
          final deviceName = device.platformName.toUpperCase();
          final deviceId = device.remoteId.str;

          if (processedDevices.contains(deviceId)) {
            continue;
          }
          processedDevices.add(deviceId);

          bool isOmronDevice = false;

          final omronKeywords = [
            'OMRON',
            'HEM-',
            'HEM',
            'BLESMART',
            'BP',
          ];

          for (var keyword in omronKeywords) {
            if (deviceName.contains(keyword.toUpperCase())) {
              isOmronDevice = true;
              break;
            }
          }

          if (!isOmronDevice &&
              result.advertisementData.serviceUuids.isNotEmpty) {
            for (var uuid in result.advertisementData.serviceUuids) {
              if (uuid.toString().toUpperCase().contains('1810')) {
                isOmronDevice = true;
                break;
              }
            }
          }

          if (!isOmronDevice && device.servicesList.isNotEmpty) {
            for (var service in device.servicesList) {
              final uuid = service.uuid.toString().toUpperCase();
              if (uuid.contains('1810')) {
                isOmronDevice = true;
                break;
              }
            }
          }

          if (isOmronDevice) {
            foundDevices[deviceId] = device;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
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
    } catch (e) {
    }
  }

  Future<void> connect(
    BluetoothDevice device, {
    required bool autoConnect,
  }) async {
    try {
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        _handleConnectionStateChange(device, state);
      });

      if (device.isConnected) {
        _updateConnectionStatus(BleConnectionStatus.connected);
        return;
      }

      _updateConnectionStatus(BleConnectionStatus.connecting);

      await device.connect(
        autoConnect: autoConnect,
        mtu: null,
        license: License.free,
      );
      _connectedDevice = device;
    } catch (e) {
      _updateConnectionStatus(BleConnectionStatus.disconnected);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    try {
      _updateConnectionStatus(BleConnectionStatus.disconnecting);

      await _connectedDevice!.disconnect();
      _connectedDevice = null;

      _updateConnectionStatus(BleConnectionStatus.disconnected);
    } catch (e) {
      rethrow;
    }
  }

  /// MAC 주소로 연결 해제
  ///
  /// [macAddress]: 연결 해제할 기기의 MAC 주소
  Future<void> disconnectByMacAddress(String macAddress) async {
    try {
      if (_connectedDevice != null && _connectedDevice!.remoteId.str == macAddress) {
        await disconnect();
      }
    } catch (e) {
      // 에러 무시
    }
  }

  /// OS 레벨에서 블루투스 페어링 제거
  ///
  /// [macAddress]: 제거할 기기의 MAC 주소
  Future<void> removeBond(String macAddress) async {
    try {
      // 현재 연결된 기기인지 확인하고 연결 해제
      if (_connectedDevice != null && _connectedDevice!.remoteId.str == macAddress) {
        await disconnect();
      }
      
      // MAC 주소로 디바이스 객체 생성
      final device = BluetoothDevice.fromId(macAddress);
      
      // 페어링 제거
      await device.removeBond();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null || !_connectedDevice!.isConnected) {
      throw Exception('No device connected');
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      return services;
    } catch (e) {
      rethrow;
    }
  }

  Future<BluetoothService?> findService(
    String serviceUuid, {
    List<BluetoothService>? services,
  }) async {
    services ??= await discoverServices();

    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains(
        serviceUuid.toUpperCase(),
      )) {
        return service;
      }
    }

    return null;
  }

  BluetoothCharacteristic? findCharacteristic(
    BluetoothService service,
    String characteristicUuid,
  ) {
    for (var characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toUpperCase().contains(
        characteristicUuid.toUpperCase(),
      )) {
        return characteristic;
      }
    }

    return null;
  }

  Future<StreamSubscription<List<int>>> subscribeToCharacteristic(
    BluetoothCharacteristic characteristic,
    void Function(List<int> data) onData,
  ) async {
    try {
      await characteristic.setNotifyValue(true);

      return characteristic.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          onData(value);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> writeCharacteristic(
    BluetoothCharacteristic characteristic,
    List<int> data,
  ) async {
    try {
      await characteristic.write(data);
    } catch (e) {
      rethrow;
    }
  }

  void _handleConnectionStateChange(
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) {
    switch (state) {
      case BluetoothConnectionState.connected:
        _updateConnectionStatus(BleConnectionStatus.connected);
        break;
      case BluetoothConnectionState.disconnected:
        if (_connectedDevice?.remoteId.str == device.remoteId.str) {
          _updateConnectionStatus(BleConnectionStatus.disconnected);
        }
        break;
      case BluetoothConnectionState.connecting:
        _updateConnectionStatus(BleConnectionStatus.connecting);
        break;
      case BluetoothConnectionState.disconnecting:
        _updateConnectionStatus(BleConnectionStatus.disconnecting);
        break;
    }
  }

  void _updateConnectionStatus(BleConnectionStatus status) {
    _currentStatus = status;
    _connectionStatusController.add(status);
  }

  /// 혈압 서비스 설정 및 구독
  ///
  /// 연결된 기기에서 Blood Pressure Service를 찾아 혈압 측정 데이터를 구독합니다.
  Future<void> setupBloodPressureService() async {
    try {
      if (_connectedDevice == null || !_connectedDevice!.isConnected) {
        debugPrint('[BleService] No device connected for BP service setup');
        return;
      }

      final services = await discoverServices();

      // Blood Pressure Service 찾기
      BluetoothService? bpService;
      for (var service in services) {
        final uuid = service.uuid.toString().toUpperCase();
        if (uuid.contains(BluetoothConstants.bloodPressureServiceUuid)) {
          bpService = service;
          break;
        }
      }

      if (bpService == null) {
        debugPrint('[BleService] Blood Pressure Service not found');
        return;
      }

      // 혈압 측정 데이터 구독
      await _subscribeToBloodPressureMeasurement(bpService);
      debugPrint('[BleService] Subscribed to BP measurement - waiting for data...');
    } catch (e) {
      debugPrint('[BleService] Error setting up Blood Pressure Service: $e');
    }
  }

  /// Blood Pressure Measurement 구독
  ///
  /// [service]: Blood Pressure Service
  Future<void> _subscribeToBloodPressureMeasurement(
    BluetoothService service,
  ) async {
    try {
      // BP Measurement Characteristic 찾기
      final characteristic = findCharacteristic(
        service,
        BluetoothConstants.bloodPressureMeasurementCharUuid,
      );

      if (characteristic == null) {
        debugPrint('[BleService] Blood Pressure Measurement Characteristic not found');
        return;
      }

      // 기존 구독 취소 (중복 방지)
      await _bpDataSubscription?.cancel();
      _bpDataSubscription = null;

      // 새로운 구독 시작
      _bpDataSubscription = await subscribeToCharacteristic(
        characteristic,
        _handleBloodPressureData,
      );

      debugPrint('[BleService] Subscribed to Blood Pressure Measurement');
    } catch (e) {
      debugPrint('[BleService] Error subscribing to BP measurement: $e');
      rethrow;
    }
  }

  /// 혈압 데이터 처리
  ///
  /// BLE로 수신된 혈압 측정 데이터를 파싱하고 콘솔에 로그로 출력합니다.
  ///
  /// [data]: Blood Pressure Measurement 데이터
  void _handleBloodPressureData(List<int> data) async {
    try {
      // 현재 연결된 기기가 활성화되어 있는지 확인
      if (_connectedDevice == null) {
        debugPrint('[BleService] No connected device, ignoring BP data');
        return;
      }
      
      final macAddress = _connectedDevice!.remoteId.str;
      final storage = ServiceLocator().deviceBluetoothMappingStorage;
      final bpMappings = await storage.getMappingsByDeviceType('BP');
      
      final mapping = bpMappings.firstWhere(
        (m) => m.macAddress == macAddress,
        orElse: () => DeviceBluetoothMapping(
          deviceType: 'BP',
          deviceName: 'Unknown',
          macAddress: macAddress,
          deviceId: macAddress,
          isEnabled: false,
        ),
      );
      
      // 비활성화된 기기에서 온 데이터는 무시
      if (!mapping.isEnabled) {
        debugPrint('[BleService] Device is disabled, ignoring BP data from: $macAddress');
        return;
      }
      
      // 데이터 파싱
      final bpData = OmronBpParser.parse(data);
      final now = DateTime.now();

      // 수신된 혈압 데이터 로그 전송
      OptimizedNetworkLogger().log(
        '[블루투스 혈압 데이터 수신] 기기: ${mapping.deviceName} (${macAddress}), '
        '수축기: ${bpData.systolic}mmHg, 이완기: ${bpData.diastolic}mmHg, '
        '맥박: ${bpData.pulse}bpm, 측정시간: ${bpData.measuredAt}, '
        '현재시간: $now, 원본데이터: ${base64Encode(data)}',
        level: 'INFO',
      );

      // 데이터를 버퍼에 추가
      _dataBuffer.add(bpData);
      debugPrint('[BleService] 데이터 버퍼에 추가됨 (총 ${_dataBuffer.length}개). 측정시간: ${bpData.measuredAt}');

      // 기존 타이머 취소
      _dataBufferTimer?.cancel();

      // 새로운 타이머 시작 (2초 후 가장 최근 데이터 처리)
      _dataBufferTimer = Timer(_dataBufferWaitDuration, () {
        _processBufferedData(mapping, macAddress);
      });
    } catch (e) {
      debugPrint('[BleService] Error handling blood pressure data: $e');
    }
  }

  /// 버퍼에 쌓인 데이터 처리
  ///
  /// 가장 최근 타임스탬프를 가진 데이터만 처리합니다.
  void _processBufferedData(DeviceBluetoothMapping mapping, String macAddress) {
    if (_dataBuffer.isEmpty) {
      return;
    }

    // 타임스탬프 기준으로 정렬 (가장 최근 것이 마지막)
    _dataBuffer.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    // 가장 최근 데이터 선택
    final latestData = _dataBuffer.last;
    final now = DateTime.now();

    debugPrint('[BleService] 버퍼에서 데이터 처리 시작. 총 ${_dataBuffer.length}개 중 가장 최근 데이터 선택');
    debugPrint('선택된 데이터 - 측정시간: ${latestData.measuredAt}, 수축기: ${latestData.systolic}mmHg, 이완기: ${latestData.diastolic}mmHg');

    // 중복 데이터 확인
    if (_isDuplicateData(latestData)) {
      debugPrint('[BleService] Duplicate BP data ignored: $latestData');
      
      OptimizedNetworkLogger().log(
        '[블루투스 혈압 데이터 폐기] 중복 데이터로 인해 무시됨. '
        '기기: ${mapping.deviceName} (${macAddress}), '
        '수축기: ${latestData.systolic}mmHg, 이완기: ${latestData.diastolic}mmHg, '
        '맥박: ${latestData.pulse}bpm, 측정시간: ${latestData.measuredAt}',
        level: 'WARN',
      );
      
      _dataBuffer.clear();
      return;
    }

    // 데이터 저장
    _lastDataTime = DateTime.now();
    _lastData = latestData;

    // 콘솔 로그 출력
    debugPrint('========================================');
    debugPrint('[BleService] 새로운 혈압 측정 데이터 수신! (버퍼에서 ${_dataBuffer.length}개 중 최신 데이터)');
    debugPrint('수축기 혈압 (Systolic): ${latestData.systolic} mmHg');
    debugPrint('이완기 혈압 (Diastolic): ${latestData.diastolic} mmHg');
    debugPrint('맥박 (Pulse): ${latestData.pulse} bpm');
    debugPrint('측정 시간: ${latestData.measuredAt}');
    debugPrint('현재 시간: $now');
    final timeDifference = now.difference(latestData.measuredAt).abs();
    debugPrint('시간 차이: ${timeDifference.inSeconds}초');
    debugPrint('========================================');

    // 유효한 데이터 처리 완료 로그 전송
    OptimizedNetworkLogger().log(
      '[블루투스 혈압 데이터 처리 완료] 버퍼에서 ${_dataBuffer.length}개 중 가장 최근 데이터로 처리됨. '
      '기기: ${mapping.deviceName} (${macAddress}), '
      '수축기: ${latestData.systolic}mmHg, 이완기: ${latestData.diastolic}mmHg, '
      '맥박: ${latestData.pulse}bpm, 측정시간: ${latestData.measuredAt}, '
      '현재시간: $now, 시간차이: ${timeDifference.inSeconds}초',
      level: 'INFO',
    );

    // 기존 측정 로직에 데이터 전달
    MeasurementListener().addBloodPressureResult(latestData);

    // 버퍼 초기화
    _dataBuffer.clear();
  }

  /// 중복 데이터 확인
  ///
  /// 같은 데이터가 짧은 시간 내에 여러 번 수신되는 것을 방지합니다.
  ///
  /// [newData]: 확인할 새 데이터
  /// Returns: 중복 여부
  bool _isDuplicateData(BloodPressureResult newData) {
    if (_lastDataTime == null || _lastData == null) {
      return false;
    }

    final now = DateTime.now();
    final timeDiff = now.difference(_lastDataTime!);

    // 시간 간격 확인
    if (timeDiff.inSeconds >=
        BluetoothConstants.duplicateDataThresholdSeconds) {
      return false;
    }

    // 데이터 값 비교
    return _lastData!.systolic == newData.systolic &&
        _lastData!.diastolic == newData.diastolic &&
        _lastData!.pulse == newData.pulse;
  }

  /// 저장된 활성화된 혈압계에 자동 연결 시도
  ///
  /// 저장된 혈압계 중 활성화된 기기에 자동으로 연결을 시도합니다.
  /// 혈압계는 측정 후에만 잠깐 연결되므로, 주기적으로 호출해야 합니다.
  Future<void> tryConnectSavedBloodPressureDevices() async {
    try {
      // 저장된 혈압계 매핑 가져오기
      final storage = ServiceLocator().deviceBluetoothMappingStorage;
      final bpMappings = await storage.getMappingsByDeviceType('BP');
      
      // 이미 연결된 기기가 비활성화되어 있으면 연결 해제
      if (_connectedDevice != null && _connectedDevice!.isConnected) {
        final connectedMacAddress = _connectedDevice!.remoteId.str;
        final connectedMapping = bpMappings.firstWhere(
          (m) => m.macAddress == connectedMacAddress,
          orElse: () => DeviceBluetoothMapping(
            deviceType: 'BP',
            deviceName: 'Unknown',
            macAddress: connectedMacAddress,
            deviceId: connectedMacAddress,
            isEnabled: false,
          ),
        );
        
        if (!connectedMapping.isEnabled) {
          debugPrint('[BleService] Connected device is disabled, disconnecting: $connectedMacAddress');
          await disconnect();
        } else {
          debugPrint('[BleService] Already connected to enabled device: $connectedMacAddress');
          return;
        }
      }
      
      // 활성화된 혈압계만 필터링
      final enabledMappings = bpMappings.where((m) => m.isEnabled).toList();
      
      if (enabledMappings.isEmpty) {
        debugPrint('[BleService] No enabled blood pressure devices found');
        return;
      }

      debugPrint('[BleService] Found ${enabledMappings.length} enabled BP device(s), attempting to connect...');

      // 각 활성화된 혈압계에 연결 시도
      for (final mapping in enabledMappings) {
        try {
          // MAC 주소로 디바이스 객체 생성
          final device = BluetoothDevice.fromId(mapping.macAddress);
          
          debugPrint('[BleService] Attempting to connect to saved BP device: ${mapping.deviceName} (${mapping.macAddress})');
          
          // autoConnect: true로 연결 시도 (혈압계가 측정 후 연결될 때까지 대기)
          await connect(device, autoConnect: true);
          
          debugPrint('[BleService] Successfully connected to: ${mapping.deviceName}');
          break; // 첫 번째 성공한 기기만 연결
        } catch (e) {
          debugPrint('[BleService] Failed to connect to ${mapping.deviceName}: $e');
          // 다음 기기 시도
          continue;
        }
      }
    } catch (e) {
      debugPrint('[BleService] Error in tryConnectSavedBloodPressureDevices: $e');
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _bpDataSubscription?.cancel();
    _connectionTimer?.cancel();
    _dataBufferTimer?.cancel();
    _dataBuffer.clear();
    _connectedDevice?.clearGattCache();
    _connectedDevice?.disconnect();
    _connectionStatusController.close();
  }
}
