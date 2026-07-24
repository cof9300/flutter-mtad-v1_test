import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/config/alco_usb_constants.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/data/local/device_usb_mapping_storage.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';

class AlcoUsbService {
  final DeviceUsbMappingStorage _mappingStorage;

  UsbPort? _port;
  bool _isConnected = false;
  Timer? _keepAliveTimer;
  StreamSubscription<Uint8List>? _inputSubscription;

  final List<int> _rxBuffer = [];
  int _lastStateCode = 0;
  int _keepAliveFailCount = 0;

  // 기기로부터 마지막으로 유효 패킷을 수신한 시각.
  // FTDI USB 어댑터는 물리적으로 제거돼도 write()가 즉시 실패하지 않아
  // write 실패 기반 해제 감지가 동작하지 않는 경우가 있다.
  // keep-alive를 보내면 기기는 매번 응답하므로, 일정 시간 응답이 없으면 연결 해제로 판정한다.
  DateTime? _lastRxTime;

  // 현재 연결된 포트의 deviceName(portName).
  // 인바디(BP)와 음주(AL)가 동일한 FTDI VID/PID(1027:24577)를 공유하는 현장에서,
  // BP 선택 로직이 "AL이 점유 중인 포트"를 배제할 수 있도록 노출한다.
  String? _connectedPortName;

  static const int _maxKeepAliveFailures = 5;

  /// 마지막 응답 수신 후 이 시간(ms)을 초과하면 물리적 연결 해제로 간주.
  /// keep-alive 간격(1500ms)의 약 4배 → 응답이 3회 이상 연속 누락된 경우.
  static const int _responseTimeoutMs = 6000;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  final StreamController<AlcoNotification> _notificationController =
      StreamController<AlcoNotification>.broadcast();

  bool get isConnected => _isConnected;

  /// 응답 수신 여부까지 반영한 "실제 연결" 판정.
  /// isConnected 플래그는 FTDI 어댑터 물리 제거 시에도 stale하게 true로 남을 수 있으므로,
  /// 최근 _responseTimeoutMs 내에 기기 응답을 받았는지로 보강 판정한다.
  /// 연결 상태 모니터링/네비게이션 분기 등 "정말 연결됐는가" 판단에는 이 값을 사용한다.
  bool get isConnectedReliable {
    if (!_isConnected) return false;
    final lastRx = _lastRxTime;
    if (lastRx == null) return false;
    return DateTime.now().difference(lastRx).inMilliseconds <= _responseTimeoutMs;
  }

  /// USB 포트가 현재 열려있는지 여부.
  /// AlcoUsbService가 포트를 점유 중일 때는 Android의 UsbManager.getDeviceList()가
  /// 기기를 물리적으로 제거한 후에도 포트를 닫기 전까지 제거된 기기를 반환할 수 있다.
  /// 이 플래그로 AlcoUsbService가 관리 중인지 판단할 수 있다.
  bool get isPortOpen => _port != null;

  /// AlcoUsbService(AL)가 현재 점유 중인 포트 이름(deviceName). 미연결 시 null.
  /// 동일 VID/PID를 공유하는 인바디(BP) 선택 로직에서 이 포트를 배제하는 데 사용한다.
  String? get connectedPortName => _isConnected ? _connectedPortName : null;

  Stream<bool> get connectionStatusStream => _statusController.stream;
  Stream<AlcoNotification> get alcoNotificationStream =>
      _notificationController.stream;

  AlcoUsbService(this._mappingStorage);

  String _stateName(int code) {
    switch (code) {
      case AlcoUsbConstants.stateReady:       return 'READY(0x01)';
      case AlcoUsbConstants.stateWarmUp:      return 'WARM_UP(0x05)';
      case AlcoUsbConstants.stateWaitBlowing: return 'WAIT_BLOWING(0x06)';
      case AlcoUsbConstants.stateBlowing:     return 'BLOWING(0x07)';
      case AlcoUsbConstants.stateAnalyzing:   return 'ANALYZING(0x08)';
      case AlcoUsbConstants.stateResult:      return 'RESULT(0x09)';
      case AlcoUsbConstants.stateSleep:       return 'SLEEP(0x0C)';
      case AlcoUsbConstants.stateError:       return 'ERROR(0x81)';
      default: return '0x${code.toRadixString(16).padLeft(2, '0')}';
    }
  }

  void _log(String msg) =>
      FlutterErrorLogger.logInfo('${LogCategory.alcoUsb} $msg');

  void _logWarn(String msg) =>
      FlutterErrorLogger.logWarning('${LogCategory.alcoUsb} $msg');

  void _logErr(String msg, [Object? e]) =>
      FlutterErrorLogger.logError('${LogCategory.alcoUsb} $msg', e);

  Future<void> tryConnectSavedDevice() async {
    _log('저장된 기기 연결 시도 시작');
    try {
      final mapping = await _mappingStorage.getMappingByDeviceType('AL');
      if (mapping == null) {
        _logWarn('저장된 매핑 없음 — 연결 중단');
        return;
      }
      _log('저장된 매핑 확인 — VID:0x${mapping.vid.toRadixString(16)} PID:0x${mapping.pid.toRadixString(16)} PORT:"${mapping.portName}"');

      final devices = await UsbSerial.listDevices();
      _log('USB 기기 목록 조회 — ${devices.length}개 감지');
      for (final d in devices) {
        _log('  └ 기기: ${d.deviceName} VID:0x${d.vid?.toRadixString(16)} PID:0x${d.pid?.toRadixString(16)}');
      }

      // 동일 VID/PID(FTDI) 후보 전체
      List<UsbDevice> pool = devices
          .where((d) => d.vid == mapping.vid && d.pid == mapping.pid)
          .toList();

      // 이 VID/PID가 다른 기기(예: 인바디 BP)와 공유되는지 확인한다.
      // 인바디 BPBIO와 음주 AF-50U는 동일 FTDI(1027:24577)를 쓰는 현장이 있어,
      // 이 경우 VID/PID만으로는 두 기기를 구분할 수 없다.
      final allMappings = await _mappingStorage.getMappings();
      final sharedWithOther = allMappings.any((m) =>
          m.deviceType != 'AL' &&
          m.vid == mapping.vid &&
          m.pid == mapping.pid);

      // 인바디(BP)가 점유 중인 동일 VID/PID 포트는 음주 후보에서 절대 제외한다.
      final bpPort = MeasurementListener().activePortName('BP');
      if (bpPort != null) {
        final excluded = pool.where((d) => d.deviceName != bpPort).toList();
        if (excluded.length != pool.length) {
          _log('BP 점유 포트 제외 — $bpPort');
        }
        pool = excluded;
      }

      if (pool.isEmpty) {
        _logWarn('일치하는 기기 없음 (VID/PID 불일치 또는 BP 점유) — 연결 중단');
        return;
      }

      // 저장 portName 완전 일치 후보 탐색
      UsbDevice? exact;
      if (mapping.portName.isNotEmpty) {
        for (final d in pool) {
          if (d.deviceName == mapping.portName) {
            exact = d;
            break;
          }
        }
      }

      UsbDevice selected;
      if (exact != null) {
        // 1순위: 저장 portName 완전 일치 — 항상 안전.
        selected = exact;
      } else if (sharedWithOther) {
        // VID/PID를 다른 기기와 공유하는데 정확한 portName 매칭이 없다.
        // 이 상태에서 fallback으로 임의 포트를 잡으면, 물리적으로 빠진 음주 대신
        // 인바디 포트를 가로채 인바디 통신을 망가뜨릴 수 있다.
        // 단, BP 점유 포트를 제외하고 후보가 정확히 1개만 남았고 BP가 실제 연결
        // 상태라면(= 나머지는 음주 포트로 확정 가능) 그 포트만 허용한다.
        if (bpPort != null && pool.length == 1) {
          selected = pool.first;
          _log('BP 점유 포트 제외 후 단일 후보 → 음주로 확정 (${selected.deviceName})');
        } else {
          _logWarn(
            '음주 portName 매칭 없음 + 동일 VID/PID 공유(BP) → '
            '인바디 포트 오인 방지를 위해 연결 보류 (저장:"${mapping.portName}")',
          );
          return;
        }
      } else {
        // 공유되지 않는 단독 VID/PID — 경로 변경 대응으로 첫 후보 사용.
        selected = pool.first;
      }

      _log('일치 기기 발견: ${selected.deviceName} — 연결 시도');
      await _connect(selected);

      // 재삽입으로 경로가 바뀐 경우, 실제 연결 성공한 포트를 저장소에 반영한다.
      // (런타임 연결을 신뢰 기준으로 삼아 어드민 표시가 정확 매칭만으로 동작하도록)
      if (_isConnected && selected.deviceName != mapping.portName) {
        await _mappingStorage.saveMapping(DeviceUsbMapping(
          deviceType: mapping.deviceType,
          portName: selected.deviceName,
          vid: mapping.vid,
          pid: mapping.pid,
          baudRate: mapping.baudRate,
        ));
        _log('포트 경로 갱신 저장 — ${mapping.portName} → ${selected.deviceName}');
      }
    } catch (e) {
      _logErr('tryConnectSavedDevice 예외', e);
      debugPrint('[AlcoUsbService] tryConnectSavedDevice failed: $e');
    }
  }

  Future<void> _connect(UsbDevice device) async {
    _log('_connect 시작 — 기기:${device.deviceName} VID:0x${device.vid?.toRadixString(16)} PID:0x${device.pid?.toRadixString(16)}');
    try {
      if (_isConnected) {
        _log('이미 연결된 상태 — _connect 건너뜀');
        return;
      }

      final port = await device.create();
      if (port == null) {
        _logWarn('port.create() 실패 (null 반환) — 연결 중단');
        return;
      }
      _log('port.create() 성공');

      final opened = await port.open();
      if (!opened) {
        _logWarn('port.open() 실패 (false 반환) — 연결 중단');
        return;
      }
      _log('port.open() 성공');

      await port.setDTR(true);
      await port.setRTS(true);
      _log('DTR/RTS 설정 완료');

      await port.setPortParameters(
        AlcoUsbConstants.baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      _log('포트 파라미터 설정 완료 — baud:${AlcoUsbConstants.baudRate} 8N1');

      _port = port;
      _connectedPortName = device.deviceName;
      _isConnected = true;
      _lastStateCode = 0;
      _keepAliveFailCount = 0;
      _lastRxTime = DateTime.now();
      _rxBuffer.clear();
      _updateStatus(true);
      _log('연결 상태 업데이트 완료 — isConnected=true');

      _inputSubscription = port.inputStream?.listen(
        _onData,
        onError: (e) {
          _logErr('inputStream 오류', e);
        },
        onDone: _onDisconnected,
        cancelOnError: false,
      );
      _log('inputStream 수신 시작');

      try {
        await port.write(Uint8List.fromList(_buildPacket(_buildKeepAlivePayload())));
        _log('초기 KeepAlive 패킷 전송 성공');
      } catch (e) {
        _logWarn('초기 KeepAlive 패킷 전송 실패: $e');
      }

      _startKeepAlive();
      _log('기기 연결 완료 ✓');
    } catch (e) {
      _logErr('_connect 예외 — 연결 실패', e);
      debugPrint('[AlcoUsbService] _connect error: $e');
      await _cleanup();
    }
  }

  void _onData(Uint8List data) {
    try {
      // 데이터 수신 hex 덤프는 서버 로그가 폭증하여 큐가 가득 차므로 debug 출력만 한다.
      debugPrint('[AlcoUsbService] rx ${data.length}B');
      _lastRxTime = DateTime.now();
      _rxBuffer.addAll(data);
      _processBuffer();
    } catch (e) {
      _logErr('_onData 처리 예외', e);
      debugPrint('[AlcoUsbService] _onData error: $e');
    }
  }

  void _processBuffer() {
    while (_rxBuffer.isNotEmpty) {
      final stxIdx = _rxBuffer.indexOf(AlcoUsbConstants.stx);
      if (stxIdx < 0) {
        _rxBuffer.clear();
        return;
      }
      if (stxIdx > 0) {
        _rxBuffer.removeRange(0, stxIdx);
      }
      if (_rxBuffer.length < 2) return;

      final ntx = _rxBuffer[1];
      final totalLength = 2 + ntx + 2;
      if (_rxBuffer.length < totalLength) {
        // 패킷 미완성: 추가 수신 대기 (조용히 처리)
        return;
      }

      final packet = _rxBuffer.sublist(0, totalLength);
      _rxBuffer.removeRange(0, totalLength);

      final etxByte = packet[totalLength - 2];
      if (etxByte != AlcoUsbConstants.etx) {
        debugPrint('[AlcoUsbService] ETX mismatch — dropped');
        continue;
      }

      final receivedCrc = packet[totalLength - 1];
      int computedCrc = 0;
      for (int i = 0; i < totalLength - 1; i++) {
        computedCrc ^= packet[i];
      }
      if (computedCrc != receivedCrc) {
        debugPrint('[AlcoUsbService] CRC mismatch — dropped');
        continue;
      }

      final payload = packet.sublist(2, 2 + ntx);
      _handlePayload(payload);
    }
  }

  void _handlePayload(List<int> payload) {
    if (payload.length < AlcoUsbConstants.rxStateIndex + 1) {
      _logWarn('페이로드 길이 부족 — ${payload.length}바이트 (최소 ${AlcoUsbConstants.rxStateIndex + 1} 필요)');
      return;
    }

    final notification = AlcoNotification.fromUsbPayload(payload);
    final prevState = _lastStateCode;
    _lastStateCode = notification.stateCode;

    final stateChanged = prevState != notification.stateCode;
    final stateLabel = _stateName(notification.stateCode);

    if (stateChanged) {
      _log('━━ 상태 변경: ${_stateName(prevState)} → $stateLabel '
          '(battery:${notification.battery} rawBac:${notification.rawBacValue})');
    }

    if (notification.rawBacValue > 0) {
      _log('BAC 값 감지 — rawBac:${notification.rawBacValue}');
    }

    if (notification.stateCode == AlcoUsbConstants.stateError) {
      _logWarn('오류 상태 수신 — errorCode:0x${notification.errorCode.toRadixString(16)}');
    }

    // 기기가 정밀모드로 응답하는 경우 즉시 감지모드 전환 명령 전송
    // (기기 자체 저장 모드가 정밀로 설정된 경우 강제 교정)
    if (notification.isDeviceInPrecisionMode &&
        notification.stateCode == AlcoUsbConstants.stateReady) {
      _logWarn('기기가 정밀모드로 응답 — 감지모드로 강제 전환 시도');
      _port?.write(Uint8List.fromList(_buildPacket(_buildKeepAlivePayload())))
          .catchError((e) {
        _logWarn('감지모드 전환 명령 전송 실패: $e');
      });
    }

    _notificationController.add(notification);
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _log('KeepAlive 타이머 시작 — 간격:${AlcoUsbConstants.keepAliveIntervalMs}ms');
    _keepAliveTimer = Timer.periodic(
      const Duration(milliseconds: AlcoUsbConstants.keepAliveIntervalMs),
      (_) => _keepAliveTick(),
    );
  }

  /// 기기를 화면과 무관하게 "항상 측정모드(armed)"로 유지하는 keep-alive.
  ///
  /// 프로토콜(2.1.2, PAYLOAD[0]):
  ///  - 0x01 = 측정 프로세스 진행 → READY에서 보내면 Warming Up→Blow 대기로 진입,
  ///           진행 중 계속 보내면 그 상태를 유지(반복 0x01은 재시작이 아님).
  ///  - 0x00 = 측정 프로세스 대기(standby) 겸 통신 유지. 결과/에러를 0x00으로 ack하면 대기로 복귀.
  ///  - Sleep(0x0C)에서는 WakeUp(0x02 @ payload[8])으로 깨운다.
  ///
  /// 윈도우 키오스크처럼 어느 화면에서 불어도 측정이 동작하도록, 연결되어 있는 한
  /// 항상 측정 프로세스를 진행/재무장한다. 결과의 "소비"는 측정화면 구독 측에서만 한다.
  Future<void> _keepAliveTick() async {
    if (!_isConnected) return;
    try {
      final int state = _lastStateCode;
      final List<int> payload;
      final String cmdLabel;

      if (state == AlcoUsbConstants.stateSleep) {
        // Sleep 상태에서만 WakeUp(0x02) 전송
        payload = _buildWakeUpPayload();
        cmdLabel = 'WAKE_UP';
        _lastStateCode = 0;
        _log('Sleep 상태 감지 → WakeUp 명령 전송');
      } else if (state == AlcoUsbConstants.stateReady ||
          state == AlcoUsbConstants.stateWarmUp ||
          state == AlcoUsbConstants.stateWaitBlowing ||
          state == AlcoUsbConstants.stateBlowing) {
        // READY/WARM_UP/WAIT_BLOWING/BLOWING: 측정 프로세스 진행(0x01)을 계속 보내
        // 기기를 항상 측정모드(블로우 대기)로 유지한다.
        payload = _buildStartPayload();
        cmdLabel = 'MEASURE_PROCEED(0x01)';
      } else {
        // RESULT/ERROR/ANALYZING/초기/기타: 0x00으로 대기 복귀 겸 통신 유지.
        // 결과/에러는 여기서 0x00 ack → 기기가 READY로 복귀하면 다음 틱에 0x01로 재무장.
        payload = _buildKeepAlivePayload();
        cmdLabel = 'STANDBY_KEEPALIVE(0x00)';
      }

      await _port?.write(Uint8List.fromList(_buildPacket(payload)));
      _keepAliveFailCount = 0;
      debugPrint('[AlcoUsbService] KeepAlive 전송: $cmdLabel');

      // write 성공 여부와 별개로, 기기 응답이 일정 시간 끊기면 물리적 해제로 간주.
      // (FTDI 어댑터 제거 시 write는 성공하나 응답이 더 이상 오지 않는 경우 대응)
      final lastRx = _lastRxTime;
      if (lastRx != null &&
          DateTime.now().difference(lastRx).inMilliseconds > _responseTimeoutMs) {
        _logWarn('기기 응답 ${_responseTimeoutMs}ms 이상 없음 — 물리적 연결 해제로 판정');
        _onDisconnected();
      }
    } catch (e) {
      _keepAliveFailCount++;
      _logWarn('KeepAlive 전송 실패 ($_keepAliveFailCount/$_maxKeepAliveFailures): $e');
      debugPrint('[AlcoUsbService] keepAlive error ($_keepAliveFailCount): $e');
      if (_keepAliveFailCount >= _maxKeepAliveFailures) {
        _logErr('KeepAlive $_maxKeepAliveFailures회 연속 실패 — 연결 해제 처리');
        _onDisconnected();
      }
    }
  }

  /// 측정 프로세스 진행(0x01)을 즉시 1회 전송해 측정화면 진입 직후 바로 무장되도록 한다.
  /// (keep-alive가 어차피 항상 0x01로 무장하지만, 진입 latency를 줄이기 위한 즉시 전송)
  Future<void> sendWarmUpCommand() async {
    if (!_isConnected || _port == null) {
      _logWarn('sendWarmUpCommand 실패 — 기기 미연결');
      throw Exception('AL USB device not connected');
    }
    _log('WarmUp(Start) 명령 전송 시도');
    await _port!.write(Uint8List.fromList(_buildPacket(_buildStartPayload())));
    _log('WarmUp(Start) 명령 전송 완료');
    debugPrint('[AlcoUsbService] Sent Start command');
  }

  /// 측정 화면 이탈/측정 완료 시 호출되지만, 기기는 화면과 무관하게 항상 측정모드를
  /// 유지해야 하므로(윈도우 키오스크 동작) 측정을 중단시키지 않는다(의도적 no-op).
  /// 결과를 화면에서만 쓰는 것은 알림 스트림 구독/해제로 처리한다.
  Future<void> sendStandbyCommand() async {
    // no-op: keep-alive가 기기를 계속 측정모드로 유지한다.
  }

  List<int> _buildKeepAlivePayload() {
    final now = DateTime.now();
    final payload = List<int>.filled(AlcoUsbConstants.txPayloadLength, 0);
    payload[0] = AlcoUsbConstants.cmdKeepAlive;
    payload[1] = now.year & 0xFF;
    payload[2] = (now.year >> 8) & 0xFF;
    payload[3] = now.month;
    payload[4] = now.day;
    payload[5] = now.hour;
    payload[6] = now.minute;
    payload[7] = now.second;
    payload[8] = AlcoUsbConstants.modeDetect;
    payload[13] = AlcoUsbConstants.defaultAlarmLimit & 0xFF;
    payload[14] = (AlcoUsbConstants.defaultAlarmLimit >> 8) & 0xFF;
    payload[15] = AlcoUsbConstants.unitBac;
    payload[16] = AlcoUsbConstants.defaultSound;
    payload[17] = AlcoUsbConstants.defaultDetectCountLimit & 0xFF;
    payload[18] = (AlcoUsbConstants.defaultDetectCountLimit >> 8) & 0xFF;
    payload[19] = AlcoUsbConstants.defaultPrecisionCountLimit & 0xFF;
    payload[20] = (AlcoUsbConstants.defaultPrecisionCountLimit >> 8) & 0xFF;
    payload[21] = AlcoUsbConstants.defaultCalibrationPeriodMonths;
    return payload;
  }

  List<int> _buildWakeUpPayload() {
    final payload = _buildKeepAlivePayload();
    payload[8] = AlcoUsbConstants.cmdSleepWakeUp;
    return payload;
  }

  List<int> _buildStartPayload() {
    final payload = _buildKeepAlivePayload();
    payload[0] = AlcoUsbConstants.cmdStart;
    return payload;
  }

  List<int> _buildPacket(List<int> payload) {
    final ntx = payload.length;
    final frame = [AlcoUsbConstants.stx, ntx, ...payload, AlcoUsbConstants.etx];
    int crc = 0;
    for (final b in frame) {
      crc ^= b;
    }
    return [...frame, crc];
  }

  void _onDisconnected() {
    _log('연결 해제 감지 — cleanup 시작');
    _cleanup();
  }

  Future<void> _cleanup() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    try {
      await _port?.close();
    } catch (_) {}
    _port = null;
    _connectedPortName = null;
    _rxBuffer.clear();
    _lastStateCode = 0;
    _keepAliveFailCount = 0;
    _lastRxTime = null;
    if (_isConnected) {
      _isConnected = false;
      _updateStatus(false);
      _log('연결 해제 완료 — isConnected=false');
    }
  }

  Future<void> disconnect() async {
    _log('disconnect() 호출');
    await _cleanup();
  }

  void _updateStatus(bool connected) {
    _statusController.add(connected);
  }

  void dispose() {
    _keepAliveTimer?.cancel();
    _inputSubscription?.cancel();
    _port?.close();
    _statusController.close();
    _notificationController.close();
  }
}
