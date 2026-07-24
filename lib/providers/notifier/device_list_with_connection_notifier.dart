import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/device.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/providers/notifier/device_usb_mappings_notifier.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/core/utils/inbody_health_check.dart';
import 'package:flutter_template/core/utils/celvas_health_check.dart';
import 'package:flutter_template/core/utils/hrv_health_check.dart';

class DeviceConnectionStatusNotifier extends StateNotifier<Map<String, bool>> {
  DeviceConnectionStatusNotifier(this._ref) : super({}) {
    _startMonitoring();
  }

  final Ref _ref;
  Map<String, bool> _previousState = {};

  void _startMonitoring() async {
    await Future.delayed(Duration(milliseconds: 500));
    await _safeCheckAllDeviceConnections();
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 5));
      if (mounted) {
        await _safeCheckAllDeviceConnections();
        return true;
      }
      return false;
    });
  }

  /// USB 작업 hang으로 인한 모니터링 루프 동결을 방지하기 위한 타임아웃 래퍼
  Future<void> _safeCheckAllDeviceConnections() async {
    try {
      await _checkAllDeviceConnections().timeout(
        const Duration(seconds: 20),
      );
    } catch (_) {
      // 타임아웃 또는 예외 발생 시 해당 사이클만 스킵하고 다음 사이클 진행
    }
  }

  Future<void> _checkAllDeviceConnections() async {
    final mappings = _ref.read(deviceUsbMappingsProvider);
    final bluetoothMappings = _ref.read(deviceBluetoothMappingsProvider);
    final devices = _ref.read(deviceListProvider);
    final newState = <String, bool>{};

    for (final mapping in mappings) {
      bool isConnected;

      if (mapping.deviceType.toUpperCase() == 'AL') {
        final alcoUsb = ServiceLocator().alcoUsbService;
        if (alcoUsb.isConnectedReliable) {
          // AlcoUsbService가 연결 관리 중 + 최근 응답 수신 확인 → 연결로 신뢰
          isConnected = true;
        } else if (alcoUsb.isPortOpen) {
          // 포트는 열려있으나 _isConnected=false: cleanup 진행 중 → 미연결 처리
          isConnected = false;
        } else {
          // AlcoUsbService가 아직 연결하지 않은 경우(측정화면 진입 전 등)
          // → VID/PID 스캔으로 물리 연결 여부 확인
          isConnected = await ServiceLocator().usbService.isDeviceConnected(
                mapping.deviceType,
              );
        }
      } else if (mapping.deviceType.toUpperCase() == 'BP') {
        // device list에서 해당 device 찾기
        final device = devices.firstWhere(
          (d) => d.type == mapping.deviceType,
          orElse: () => Device(type: mapping.deviceType, name: ''),
        );

        final deviceName = device.name.toLowerCase();
        final isInBody =
            deviceName.contains('인바디') || deviceName.contains('inbody');
        final isCelvas =
            deviceName.contains('셀바스') || deviceName.contains('celvas');
        // 셀바스 ACCUNIQ BP250/BP210 신규 프로토콜 기기 식별 (product 명에 모델명 포함)
        final isBp250 = deviceName.contains('bp250') ||
            deviceName.contains('bp210') ||
            deviceName.contains('accuniq') ||
            deviceName.contains('250');

        if (isInBody) {
          // 인바디 혈압계는 헬스체크 함수 사용
          isConnected = await InBodyHealthCheck.checkConnection(
            mapping.deviceType,
            deviceName: device.name,
          );
        } else if (isCelvas) {
          // BP250은 헬스체크 전에 먼저 등록해야 _processData가 BP250 프로토콜로 라우팅된다.
          if (isBp250) {
            MeasurementListener().registerCelvasBp250Device(mapping.deviceType);
          }
          // 셀바스 혈압계는 헬스체크 함수 사용 (BP250은 버전조회 방식)
          isConnected = await CelvasHealthCheck.checkConnection(
            mapping.deviceType,
            deviceName: device.name,
            isBp250: isBp250,
          );
          // 연결 상태에 따라 MeasurementListener에 셀바스 기기 등록/해제
          if (isConnected) {
            if (isBp250) {
              MeasurementListener()
                  .registerCelvasBp250Device(mapping.deviceType);
            } else {
              MeasurementListener().registerCelvasDevice(mapping.deviceType);
            }
          } else {
            if (isBp250) {
              MeasurementListener()
                  .unregisterCelvasBp250Device(mapping.deviceType);
            } else {
              MeasurementListener().unregisterCelvasDevice(mapping.deviceType);
            }
          }
        } else {
          // 다른 혈압계는 기존 방식 사용
          isConnected = await ServiceLocator().usbService.isDeviceConnected(
                mapping.deviceType,
              );
        }
      } else if (mapping.deviceType.toUpperCase() == 'ST') {
        // 자율신경계는 헬스체크 함수 사용 (정보조회 0x49 / 정보응답 0x69)
        isConnected = await HrvHealthCheck.checkConnection(mapping.deviceType);
      } else {
        // 다른 기기는 기존 방식 사용
        isConnected = await ServiceLocator().usbService.isDeviceConnected(
              mapping.deviceType,
            );
      }

      newState[mapping.deviceType] = isConnected;
    }

    for (final bluetoothMapping in bluetoothMappings) {
      if (bluetoothMapping.isEnabled) {
        final deviceType = bluetoothMapping.deviceType;
        final hasUsbConnection = newState[deviceType] ?? false;
        if (!hasUsbConnection) {
          if (deviceType.toUpperCase() == 'AL') {
            newState[deviceType] = ServiceLocator().alcoBleService.isConnected;
          } else {
            newState[deviceType] = true;
          }
        }
      }
    }

    if (mounted) {
      final hasConnectionChanged =
          _hasConnectionChanged(_previousState, newState);
      final shouldRestart = _shouldRestartListening(_previousState, newState);
      state = newState;
      _previousState = Map<String, bool>.from(newState);

      if (hasConnectionChanged && shouldRestart) {
        await MeasurementListener().restartListening();
      }
    }
  }

  bool _hasConnectionChanged(
      Map<String, bool> oldState, Map<String, bool> newState) {
    if (oldState.length != newState.length) return true;
    for (final key in newState.keys) {
      if (oldState[key] != newState[key]) return true;
    }
    return false;
  }

  /// 포트가 이미 열려있는 기기의 논리적 연결 해제(RS232 분리 등)는
  /// restartListening을 호출하지 않는다. 포트를 불필요하게 닫으면
  /// 재연결 시 태블릿 USB까지 뺐다 꽂아야 하는 문제가 생긴다.
  bool _shouldRestartListening(
    Map<String, bool> oldState,
    Map<String, bool> newState,
  ) {
    for (final key in newState.keys) {
      if (oldState[key] == newState[key]) continue;

      final wasConnected = oldState[key] == true;
      final isNowConnected = newState[key] == true;

      // 미연결 → 연결: 이미 포트가 열려있거나 재연결된 것이므로 restart 불필요
      if (!wasConnected && isNowConnected) continue;

      // 연결 → 미연결 전환인데 포트가 아직 열려있으면 restart 불필요
      // (USB 어댑터는 태블릿에 그대로 꽂혀있고, 반대쪽만 빠진 경우)
      if (wasConnected &&
          !isNowConnected &&
          MeasurementListener().isPortInUse(key)) {
        continue;
      }

      return true;
    }
    return false;
  }

  bool isDeviceConnected(String deviceType) {
    return state[deviceType] ?? false;
  }
}

final deviceConnectionStatusProvider =
    StateNotifierProvider<DeviceConnectionStatusNotifier, Map<String, bool>>(
        (ref) {
  return DeviceConnectionStatusNotifier(ref);
});

final deviceListWithConnectionProvider = Provider<List<Device>>((ref) {
  final devices = ref.watch(deviceListProvider);
  final connectionStatus = ref.watch(deviceConnectionStatusProvider);

  return devices.map((device) {
    final isConnected = connectionStatus[device.type] ?? false;
    return device.copyWith(isConnected: isConnected);
  }).toList();
});
