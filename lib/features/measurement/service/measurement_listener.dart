import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/features/measurement/parser/bp500_parser.dart';
import 'package:flutter_template/features/measurement/parser/amp_bp868_parser.dart';
import 'package:flutter_template/features/measurement/parser/bp250_parser.dart';
import 'package:flutter_template/features/measurement/parser/inbody_parser.dart';
import 'package:flutter_template/features/measurement/parser/hc_parser.dart';
import 'package:flutter_template/features/measurement/parser/hrv_frame.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

class MeasurementListener {
  static final MeasurementListener _instance = MeasurementListener._internal();
  factory MeasurementListener() => _instance;
  MeasurementListener._internal();

  final Map<String, UsbPort?> _activePorts = {};
  // 각 deviceType이 점유 중인 포트의 deviceName(portName).
  // 동일 VID/PID(FTDI)를 공유하는 음주(AL)와 인바디(BP)가 서로의 포트를
  // 빼앗지 않도록 상호 배제하는 데 사용한다.
  final Map<String, String> _activePortNames = {};
  final Map<String, StreamSubscription<Uint8List>?> _subscriptions = {};
  final Map<String, List<int>> _buffers = {};

  final Set<String> _celvasDeviceTypes = {};
  final Map<String, DateTime> _lastR1Response = {};

  // ─── 셀바스 ACCUNIQ BP250 (신규 프로토콜) ─────────────────────────────────
  // BP500과 달리: 4800bps/2Stop, 데이터 패킷 포맷 상이, 측정값 있을 때만 ENQ에 응답,
  // 결과는 15초 후 자동 삭제, EOT(0x04) 수신 후 ACK(0x06)로 삭제, 헬스체크는 버전조회(0x56).
  final Set<String> _bp250DeviceTypes = {};
  // 해당 BP 기기로부터 마지막으로 유효 프레임을 수신한 시각 (버전조회 헬스체크 liveness 판단용)
  final Map<String, DateTime> _lastBpRxTime = {};
  // BP250 중복 emit 방지용: 마지막으로 emit한 결과 시그니처와 시각
  final Map<String, String> _lastBp250Signature = {};
  final Map<String, DateTime> _lastBp250EmitTime = {};

  final Map<String, DateTime> _lastInBodyConResponse = {};
  final Map<String, DateTime> _lastInBodyUserActivity = {};
  final Map<String, DateTime> _lastInBodyPingAttemptTime = {};
  final Map<String, DateTime> _portOpenTime = {};
  final Map<String, int> _inBodyPingFailureCount = {};
  final Map<String, DateTime> _inBodyFailureStreakStart = {};
  final Map<String, int> _celvasPingFailureCount = {};

  // ─── 자율신경계(HRV, MP-SDK) ────────────────────────────────────────────
  final Map<String, HrvFrameDecoder> _hrvDecoders = {};
  final Map<String, DateTime> _lastHrvInfoResponse = {};
  final Map<String, int> _hrvPingFailureCount = {};
  final Map<String, DateTime> _hrvFailureStreakStart = {};
  static const Duration _hrvRecoveryThreshold = Duration(seconds: 30);

  // BPBIO320/750은 장시간 idle 후 USB 포트가 열린 채로 통신만 멈추는 현장이 있다.
  // 물리 USB는 존재하므로 UI는 연결됨을 유지하되, CON 무응답이 지속되면 포트를 재오픈한다.
  static const Duration _inBodyRecoveryThreshold = Duration(seconds: 60);

  // ─── 셀바스 ENQ 무응답 복구 ───────────────────────────────────────────────
  // BP-500(EP1:PC P3)은 정상 상태라면 유휴일 때도 ENQ에 R1(전부 0)으로 반드시 응답한다.
  // 따라서 ENQ 무응답이 일정 시간 이상 지속되면 "유휴"가 아니라 공유 포트 통신이
  // 깨진 상태이며, 이 경우 측정 결과(R1)가 폴링되지 못해 결과가 지연된다.
  // 무응답 연속 구간의 시작 시각을 기록해 임계 시간을 넘으면 포트를 재오픈해 복구한다.
  //
  // 단, 일부 기기(태블릿 등)는 유휴 시 ENQ에 원래 응답하지 않는다.
  // 이 경우 복구 로직을 반복 실행하면 재오픈 무한 루프가 발생한다.
  // _celvasEnqEverResponded: 현재 포트 인스턴스에서 유예기간 외에 진짜 ENQ 응답을
  // 한 번이라도 받은 적 있으면 true. 한 번도 없으면 "원래 무응답 기기"로 보고
  // 포트 복구를 건너뛴다.
  final Map<String, DateTime> _celvasFailureStreakStart = {};
  final Map<String, bool> _celvasEnqEverResponded = {};
  static const Duration _celvasRecoveryThreshold = Duration(seconds: 30);

  bool _isRestarting = false;
  bool _isStartingListening = false;

  // ─── 앱 최초 시작 시 셀바스 이전 저장 데이터 무시 ──────────────────────────
  // 앱이 꺼져 있던 동안 기기에 저장된 측정 결과가 앱 시작 직후에 전송되는 것을 방지한다.
  // 앱이 완전히 종료(kill)되면 static 변수가 초기화되므로, 재실행 시 다시 적용된다.
  static bool _startupClearDone = false;
  bool _pendingStartupClear = false;
  DateTime? _startupClearDeadline;

  /// health check ping 진행 중인 기기 타입 목록
  /// ping 중 수신된 BP 결과는 혈압 스트림에 emit하지 않음 (오작동 방지)
  final Set<String> _pingInProgress = {};

  /// ENQ 패킷: STX(0x02) + ENQ(0x05) + ETX(0x03) + SUM(0x0a)
  static const List<int> _enqPacket = [0x02, 0x05, 0x03, 0x0a];

  /// ACK 패킷: STX(0x02) + ACK(0x06) + ETX(0x03) + SUM(0x0b)
  static const List<int> _ackPacket = [0x02, 0x06, 0x03, 0x0b];

  /// 버전 문의 패킷(BP250): STX(0x02) + V(0x56) + ETX(0x03) + SUM(0x5b)
  /// 측정 결과와 무관하게 상시 응답하므로 유휴 무응답 기기의 헬스체크에 사용한다.
  static const List<int> _versionPacket = [0x02, 0x56, 0x03, 0x5b];

  /// EOT(혈압 정보 전송 종료): 0x04
  static const int _eot = 0x04;

  static const int _maxBufferSize = 500;

  final StreamController<BloodPressureResult> _bloodPressureController =
      StreamController<BloodPressureResult>.broadcast();
  final StreamController<HeightWeightResult> _heightWeightController =
      StreamController<HeightWeightResult>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  final StreamController<String> _rawDataController =
      StreamController<String>.broadcast();

  // ─── 자율신경계(HRV) 측정 스트림 ────────────────────────────────────────
  final StreamController<HrvBasicResult> _hrvResultController =
      StreamController<HrvBasicResult>.broadcast();
  final StreamController<HrvLiveData> _hrvLiveDataController =
      StreamController<HrvLiveData>.broadcast();
  final StreamController<int> _hrvStatusController =
      StreamController<int>.broadcast();
  final StreamController<int> _hrvErrorController =
      StreamController<int>.broadcast();

  Stream<BloodPressureResult> get bloodPressureStream =>
      _bloodPressureController.stream;
  Stream<HeightWeightResult> get heightWeightStream =>
      _heightWeightController.stream;
  Stream<String> get logStream => _logController.stream;
  Stream<String> get rawDataStream => _rawDataController.stream;

  Stream<HrvBasicResult> get hrvResultStream => _hrvResultController.stream;
  Stream<HrvLiveData> get hrvLiveDataStream => _hrvLiveDataController.stream;
  Stream<int> get hrvStatusStream => _hrvStatusController.stream;
  Stream<int> get hrvErrorStream => _hrvErrorController.stream;

  void simulateAmpMeasurement() {
    final result = BloodPressureResult(
      systolic: 120,
      diastolic: 80,
      pulse: 75,
      measuredAt: DateTime.now(),
      deviceModel: '에이엠피올 (BP868F)',
    );
    _bloodPressureController.add(result);
  }

  // ─── Celvas 등록/해제 ──────────────────────────────────────────────────

  void registerCelvasDevice(String deviceType) {
    _celvasDeviceTypes.add(deviceType.toUpperCase());
  }

  void unregisterCelvasDevice(String deviceType) {
    _celvasDeviceTypes.remove(deviceType.toUpperCase());
  }

  bool _isCelvas(String deviceType) =>
      _celvasDeviceTypes.contains(deviceType.toUpperCase());

  // ─── 셀바스 BP250 등록/해제 ────────────────────────────────────────────
  // BP250은 ACK 전송이 필요하므로 _celvasDeviceTypes에도 함께 등록한다.

  void registerCelvasBp250Device(String deviceType) {
    final key = deviceType.toUpperCase();
    _bp250DeviceTypes.add(key);
    _celvasDeviceTypes.add(key);
  }

  void unregisterCelvasBp250Device(String deviceType) {
    final key = deviceType.toUpperCase();
    _bp250DeviceTypes.remove(key);
    _celvasDeviceTypes.remove(key);
  }

  bool _isCelvasBp250(String deviceType) =>
      _bp250DeviceTypes.contains(deviceType.toUpperCase());

  bool isCelvasBp250Registered(String deviceType) =>
      _bp250DeviceTypes.contains(deviceType.toUpperCase());

  // ─── 헬스체크용 ping ─────────────────────────────────────────────────
  //
  // MeasurementListener가 이미 포트를 점유 중일 때 CelvasHealthCheck가
  // 별도 포트를 열 수 없으므로, 이 메서드를 통해 열린 포트로 ENQ를 전송하고
  // R1 응답 수신 여부로 기기 연결 상태를 확인한다.

  Future<bool> pingCelvas(
    String deviceType, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;

    final key = deviceType.toUpperCase();
    final now = DateTime.now();

    // 포트 오픈 직후 5초 이내는 연결로 간주 (USB-RS232 드라이버 초기화 대기)
    // 이전 30초는 끊김 감지 지연(30초 딜레이)을 유발하므로 5초로 단축
    final openTime = _portOpenTime[key];
    if (openTime != null &&
        now.difference(openTime) < const Duration(seconds: 5)) {
      return true;
    }

    if (_pingInProgress.contains(key)) {
      return (_celvasPingFailureCount[key] ?? 0) < 2;
    }

    _pingInProgress.add(key);
    final pingTime = DateTime.now();

    // try/finally로 _pingInProgress를 반드시 정리한다.
    // (write가 행으로 멈추면 키가 영구히 남아 이후 ENQ 폴링이 완전히 중단되고,
    //  그 결과 측정값(R1)이 폴링되지 못해 결과가 수 분간 지연되던 문제를 방지)
    try {
      try {
        await port
            .write(Uint8List.fromList(_enqPacket))
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        _registerCelvasPingFailure(key);
        return (_celvasPingFailureCount[key] ?? 0) < 2;
      }

      final deadline = pingTime.add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 100));
        final lastResponse = _lastR1Response[key];
        if (lastResponse != null && lastResponse.isAfter(pingTime)) {
          _celvasPingFailureCount[key] = 0;
          _celvasFailureStreakStart.remove(key);
          // 유예기간 없이 진짜 ENQ 응답을 받은 적 있음 → 이 기기는 ENQ 폴링을 지원한다.
          _celvasEnqEverResponded[key] = true;
          return true;
        }
      }

      _registerCelvasPingFailure(key);
      return (_celvasPingFailureCount[key] ?? 0) < 2;
    } finally {
      _pingInProgress.remove(key);
    }
  }

  /// 셀바스 ENQ 무응답 1회를 기록하고, 무응답이 임계 시간 이상 지속되면
  /// 공유 포트가 깨진 것으로 보고 포트를 재오픈해 결과 폴링을 복구한다.
  ///
  /// 단, 이번 포트 인스턴스에서 한 번도 진짜 ENQ 응답을 받지 못한 경우에는
  /// "유휴 시 ENQ에 응답하지 않는 기기"로 보고 복구를 건너뛴다.
  /// (그렇지 않으면 태블릿처럼 유휴 무응답 기기에서 재오픈 무한 루프 발생)
  void _registerCelvasPingFailure(String key) {
    final failures = (_celvasPingFailureCount[key] ?? 0) + 1;
    // 카운트는 2에서 캡(연결 판정용). 복구 트리거는 시간 기반 streak으로 판단한다.
    _celvasPingFailureCount[key] = failures > 2 ? 2 : failures;

    final streakStart = _celvasFailureStreakStart[key] ??= DateTime.now();
    final streakDuration = DateTime.now().difference(streakStart);
    debugPrint(
      '[MeasurementListener] 셀바스 ENQ 무응답 (count=$failures, streak=${streakDuration.inSeconds}s, everResponded=${_celvasEnqEverResponded[key] ?? false})',
    );

    // 이 포트에서 한 번도 ENQ 응답을 받지 못했으면 유휴 무응답 기기 → 복구 불필요
    if (_celvasEnqEverResponded[key] != true) return;

    if (streakDuration >= _celvasRecoveryThreshold &&
        !_isRestarting &&
        _activePorts[key] != null) {
      // 쿨다운: 재오픈 후 다시 임계 시간이 지나야 재시도하도록 streak을 리셋한다.
      _celvasFailureStreakStart[key] = DateTime.now();
      _celvasPingFailureCount[key] = 0;
      FlutterErrorLogger.device(
        '[MeasurementListener] 셀바스 ENQ ${streakDuration.inSeconds}초 이상 무응답 → 포트 재오픈으로 결과 폴링 복구 시도',
        errorCode: 'HCK-003',
        severity: 'WARN',
        deviceType: 'BP',
      );
      unawaited(restartDevice(key));
    }
  }

  /// 셀바스 ACCUNIQ BP250 헬스체크 + 결과 폴링.
  ///
  /// BP250은 측정 결과가 있을 때만 ENQ(0x05)에 응답하고 유휴 시에는 응답하지 않으므로
  /// 연결 상태 판단(liveness)은 측정 결과와 무관하게 상시 응답하는 버전 문의(0x56)로 한다.
  /// 동시에 ENQ(0x05)도 전송해 저장된 결과가 있으면 데이터 패킷이 폴링되도록 한다.
  /// (데이터/EOT 처리 및 ACK 전송은 inputStream 수신부 _processData에서 수행)
  Future<bool> pingCelvasBp250(
    String deviceType, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;

    final key = deviceType.toUpperCase();
    final now = DateTime.now();

    final openTime = _portOpenTime[key];
    if (openTime != null &&
        now.difference(openTime) < const Duration(seconds: 5)) {
      return true;
    }

    if (_pingInProgress.contains(key)) {
      return (_celvasPingFailureCount[key] ?? 0) < 2;
    }

    _pingInProgress.add(key);
    final pingTime = DateTime.now();

    try {
      try {
        // 결과 폴링용 ENQ + liveness용 버전 문의를 함께 전송
        await port
            .write(Uint8List.fromList(_enqPacket))
            .timeout(const Duration(seconds: 2));
        await port
            .write(Uint8List.fromList(_versionPacket))
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        _registerCelvasPingFailure(key);
        return (_celvasPingFailureCount[key] ?? 0) < 2;
      }

      final deadline = pingTime.add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 100));
        final lastRx = _lastBpRxTime[key];
        if (lastRx != null && lastRx.isAfter(pingTime)) {
          _celvasPingFailureCount[key] = 0;
          _celvasFailureStreakStart.remove(key);
          // 버전 문의는 상시 응답하므로 한 번이라도 응답 시 복구 로직 활성화
          _celvasEnqEverResponded[key] = true;
          return true;
        }
      }

      _registerCelvasPingFailure(key);
      return (_celvasPingFailureCount[key] ?? 0) < 2;
    } finally {
      _pingInProgress.remove(key);
    }
  }

  // ─── 자율신경계(HRV) 헬스체크용 ping ────────────────────────────────────
  //
  // MeasurementListener가 이미 포트를 점유 중일 때 HrvHealthCheck가
  // 별도 포트를 열 수 없으므로, 이 메서드를 통해 열린 포트로 정보조회(0x49)를
  // 전송하고 정보응답(0x69) 수신 여부로 기기 연결 상태를 확인한다.
  Future<bool> pingHrv(
    String deviceType, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;

    final key = deviceType.toUpperCase();
    final now = DateTime.now();

    final openTime = _portOpenTime[key];
    if (openTime != null &&
        now.difference(openTime) < const Duration(seconds: 5)) {
      return true;
    }

    if (_pingInProgress.contains(key)) {
      return (_hrvPingFailureCount[key] ?? 0) < 2;
    }

    _pingInProgress.add(key);
    final pingTime = DateTime.now();

    try {
      try {
        await port
            .write(HrvFrameEncoder.infoRequest())
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        _registerHrvPingFailure(key);
        return (_hrvPingFailureCount[key] ?? 0) < 2;
      }

      final deadline = pingTime.add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 100));
        final lastResponse = _lastHrvInfoResponse[key];
        if (lastResponse != null && lastResponse.isAfter(pingTime)) {
          _hrvPingFailureCount[key] = 0;
          _hrvFailureStreakStart.remove(key);
          return true;
        }
      }

      _registerHrvPingFailure(key);
      return (_hrvPingFailureCount[key] ?? 0) < 2;
    } finally {
      _pingInProgress.remove(key);
    }
  }

  /// HRV 정보조회 무응답 1회를 기록하고, 무응답이 임계 시간 이상 지속되면
  /// 포트를 재오픈해 통신 복구를 시도한다.
  void _registerHrvPingFailure(String key) {
    final failures = (_hrvPingFailureCount[key] ?? 0) + 1;
    _hrvPingFailureCount[key] = failures > 2 ? 2 : failures;

    final streakStart = _hrvFailureStreakStart[key] ??= DateTime.now();
    final streakDuration = DateTime.now().difference(streakStart);
    debugPrint(
      '[MeasurementListener] HRV 정보조회 무응답 (count=$failures, streak=${streakDuration.inSeconds}s)',
    );

    if (streakDuration >= _hrvRecoveryThreshold &&
        !_isRestarting &&
        _activePorts[key] != null) {
      _hrvFailureStreakStart[key] = DateTime.now();
      _hrvPingFailureCount[key] = 0;
      FlutterErrorLogger.device(
        '[MeasurementListener] HRV 정보조회 ${streakDuration.inSeconds}초 이상 무응답 → 포트 재오픈으로 복구 시도',
        errorCode: 'HCK-004',
        severity: 'WARN',
        deviceType: 'ST',
      );
      unawaited(restartDevice(key));
    }
  }

  static const List<int> _inBodyConnectionCheckPacket = [
    0x16,
    0x16,
    0x01,
    0x30,
    0x30,
    0x02,
    0x52,
    0x45,
    0x03,
    0x17,
  ];

  Future<bool> pingInBody(
    String deviceType, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    if (_isRestarting) return true;

    final port = _activePorts[deviceType];
    if (port == null) return false;

    final key = deviceType.toUpperCase();
    final now = DateTime.now();

    final openTime = _portOpenTime[key];
    if (openTime != null &&
        now.difference(openTime) < const Duration(seconds: 8)) {
      return true;
    }

    final lastUserActivity = _lastInBodyUserActivity[key];
    if (lastUserActivity != null &&
        now.difference(lastUserActivity) < const Duration(seconds: 90)) {
      return true;
    }

    final lastCon = _lastInBodyConResponse[key];
    if (lastCon != null &&
        now.difference(lastCon) < const Duration(seconds: 30)) {
      return true;
    }

    if (_pingInProgress.contains(key)) {
      return lastCon != null &&
          now.difference(lastCon) < const Duration(seconds: 30);
    }

    final lastAttempt = _lastInBodyPingAttemptTime[key];
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _getInBodyPingInterval(key)) {
      return lastCon != null &&
          now.difference(lastCon) < const Duration(seconds: 30);
    }
    _lastInBodyPingAttemptTime[key] = now;

    _pingInProgress.add(key);
    final pingTime = DateTime.now();

    try {
      await port
          .write(Uint8List.fromList(_inBodyConnectionCheckPacket))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      _pingInProgress.remove(key);
      _registerInBodyPingFailure(key);
      return false;
    }

    final deadline = pingTime.add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
      final lastResponse = _lastInBodyConResponse[key];
      if (lastResponse != null && lastResponse.isAfter(pingTime)) {
        _inBodyPingFailureCount[key] = 0;
        _inBodyFailureStreakStart.remove(key);
        _pingInProgress.remove(key);
        return true;
      }
    }
    _registerInBodyPingFailure(key);
    _pingInProgress.remove(key);
    return false;
  }

  /// 인바디 CON 무응답을 기록하고, 무응답이 일정 시간 이상 지속되면
  /// 포트를 재오픈한다. USB 물리 존재만으로는 열린 포트가 stale해진 상태를
  /// 구분할 수 없어 장시간 idle 후 측정 무반응이 발생할 수 있다.
  void _registerInBodyPingFailure(String key) {
    final failures = (_inBodyPingFailureCount[key] ?? 0) + 1;
    _inBodyPingFailureCount[key] = failures;

    final streakStart = _inBodyFailureStreakStart[key] ??= DateTime.now();
    final streakDuration = DateTime.now().difference(streakStart);

    FlutterErrorLogger.device(
      '[MeasurementListener] InBody CON 패킷 무응답 (연속 ${failures}회, streak=${streakDuration.inSeconds}s) → 다음 CON 전송까지 ${_getInBodyPingInterval(key).inSeconds}초 대기',
      errorCode: 'HCK-001',
      severity: 'WARN',
      deviceType: 'BP',
      extraContext: {
        'consecutiveCount': failures,
        'streakSeconds': streakDuration.inSeconds,
      },
    );

    if (streakDuration >= _inBodyRecoveryThreshold &&
        !_isRestarting &&
        _activePorts[key] != null) {
      _inBodyFailureStreakStart[key] = DateTime.now();
      _inBodyPingFailureCount[key] = 0;
      FlutterErrorLogger.device(
        '[MeasurementListener] InBody CON ${streakDuration.inSeconds}초 이상 무응답 → 포트 재오픈으로 idle stale 통신 복구 시도',
        errorCode: 'HCK-001',
        severity: 'WARN',
        deviceType: 'BP',
      );
      unawaited(restartDevice(key));
    }
  }

  /// 연속 실패 횟수에 따라 CON 패킷 전송 간격을 늘려 장치 과부하를 방지한다.
  /// UI 헬스체크 결과는 호출 때마다 즉시 반환되며, 여기서 제한하는 것은
  /// 실제 CON 패킷 전송 빈도뿐이다.
  ///
  /// 실패 0회: 5s / 1회: 10s / 2회 이상: 30s(최대)
  /// - 첫 실패 후 최대 30초 이내 복구 감지 가능
  /// - 장치 미응답 시 CON 전송: 분당 최대 2회 (기존 12회에서 감소)
  Duration _getInBodyPingInterval(String key) {
    final failures = _inBodyPingFailureCount[key] ?? 0;
    if (failures == 0) return const Duration(seconds: 5);
    if (failures == 1) return const Duration(seconds: 10);
    return const Duration(seconds: 30);
  }

  // ─── 시작 / 재시작 / 종료 ─────────────────────────────────────────────

  Future<void> startListening() async {
    if (_isStartingListening) return;
    _isStartingListening = true;
    try {
      final mappings =
          await ServiceLocator().deviceUsbMappingStorage.getMappings();

      for (final mapping in mappings) {
        if (mapping.deviceType.toUpperCase() == 'AL') continue;
        await _startListeningToDevice(
            mapping.deviceType, mapping.vid, mapping.pid, mapping.baudRate,
            portName: mapping.portName);
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> stopDevice(String deviceType) async {
    _cleanupDevice(deviceType);
  }

  Future<void> restartDevice(String deviceType) async {
    _cleanupDevice(deviceType);
    final mapping = await ServiceLocator()
        .deviceUsbMappingStorage
        .getMappingByDeviceType(deviceType);
    if (mapping != null) {
      await _startListeningToDevice(
        mapping.deviceType,
        mapping.vid,
        mapping.pid,
        mapping.baudRate,
        portName: mapping.portName,
      );
    }
  }

  /// 실제 연결에 성공한 포트 경로를 저장소의 매핑에 반영한다(변경된 경우에만).
  Future<void> _persistResolvedPortName(
      String deviceType, String newPortName) async {
    try {
      final storage = ServiceLocator().deviceUsbMappingStorage;
      final m = await storage.getMappingByDeviceType(deviceType);
      if (m == null || m.portName == newPortName) return;
      await storage.saveMapping(DeviceUsbMapping(
        deviceType: m.deviceType,
        portName: newPortName,
        vid: m.vid,
        pid: m.pid,
        baudRate: m.baudRate,
      ));
      FlutterErrorLogger.device(
        '[MeasurementListener] $deviceType 포트 경로 갱신 저장 — ${m.portName} → $newPortName',
      );
    } catch (_) {}
  }

  Future<void> restartListening() async {
    FlutterErrorLogger.device('[MeasurementListener] restartListening 시작');
    _isRestarting = true;
    try {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 500));
      await startListening().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          FlutterErrorLogger.device(
            '[MeasurementListener] restartListening 타임아웃 (15초 초과) — 강제 종료',
            errorCode: 'DEV-010',
            severity: 'WARN',
          );
        },
      );
      FlutterErrorLogger.device(
          '[MeasurementListener] restartListening 완료 - 활성 포트: ${_activePorts.keys.join(", ")}');
    } finally {
      _isRestarting = false;
    }
  }

  Future<UsbDevice?> _selectUsbDeviceForListening({
    required String deviceType,
    required List<UsbDevice> devices,
    required int vid,
    required int pid,
    required int baudRate,
    String? portName,
  }) async {
    final candidates =
        devices.where((d) => d.vid == vid && d.pid == pid).toList();
    if (candidates.isEmpty) return null;

    // 인바디 BPBIO는 음주(AF-50U)와 같은 FTDI VID/PID(1027:24577)를 쓰는 현장이 있다.
    // AL이 현재 점유 중인 포트는 절대 후보로 삼지 않는다(음주 통신 방해 방지).
    final alPort = ServiceLocator().alcoUsbService.connectedPortName;
    final selectable = alPort == null
        ? candidates
        : candidates.where((d) => d.deviceName != alPort).toList();

    UsbDevice? findExact(List<UsbDevice> pool) {
      if (portName == null || portName.isEmpty) return null;
      for (final d in pool) {
        if (d.deviceName == portName) return d;
      }
      return null;
    }

    final isInBody = deviceType.toUpperCase() == 'BP' &&
        baudRate == 9600 &&
        !_isCelvas(deviceType) &&
        !_isCelvasBp250(deviceType);

    if (!isInBody) {
      // 셀바스 등: AL 점유 포트 제외 후 저장 portName 우선, 없으면 첫 후보.
      final pool = selectable.isNotEmpty ? selectable : candidates;
      return findExact(pool) ?? pool.first;
    }

    // ── 인바디(BP) 선택 ──────────────────────────────────────────────
    if (selectable.isEmpty) {
      // 남은 후보가 전부 AL 점유 포트뿐 → 연결 보류(AL 포트를 빼앗지 않음).
      FlutterErrorLogger.device(
        '[MeasurementListener] InBody 후보가 AL 점유 포트뿐 → 연결 보류',
        errorCode: 'HCK-001',
        severity: 'WARN',
        deviceType: 'BP',
      );
      return null;
    }

    if (selectable.length == 1) {
      // AL 점유 포트를 제외하고 남은 유일한 FTDI 포트 → 인바디로 확정.
      // (portName이 재삽입으로 바뀌어도 AL 포트만 알면 인바디를 특정할 수 있다.)
      final only = selectable.first;
      FlutterErrorLogger.device(
        '[MeasurementListener] InBody 단일 후보 선택 - ${only.deviceName} (AL 점유 포트 제외 후 유일)',
        errorCode: 'HCK-001',
        severity: 'INFO',
        deviceType: 'BP',
      );
      return only;
    }

    // AL 미연결 등으로 동일 VID/PID 후보가 여럿 → CON(RE) 프로브로 인바디 식별.
    final exact = findExact(selectable);
    final probeOrder = <UsbDevice>[
      if (exact != null) exact,
      ...selectable.where((d) => d.deviceName != exact?.deviceName),
    ];
    for (final candidate in probeOrder) {
      final responded = await _probeInBodyCon(candidate, baudRate: baudRate);
      FlutterErrorLogger.device(
        '[MeasurementListener] InBody 포트 후보 검사 - ${candidate.deviceName} CON=${responded ? "OK" : "NO"}',
        errorCode: 'HCK-001',
        severity: responded ? 'INFO' : 'WARN',
        deviceType: 'BP',
      );
      if (responded) return candidate;
    }

    // CON 무응답: 저장 포트가 있으면 그 포트만 사용(다른 후보는 건드리지 않음).
    if (exact != null) {
      FlutterErrorLogger.device(
        '[MeasurementListener] InBody CON 무응답 → 저장 포트 사용 (${exact.deviceName})',
        errorCode: 'HCK-001',
        severity: 'WARN',
        deviceType: 'BP',
      );
      return exact;
    }

    FlutterErrorLogger.device(
      '[MeasurementListener] InBody 식별 실패(CON 무응답·저장 포트 없음) → 연결 보류',
      errorCode: 'HCK-001',
      severity: 'WARN',
      deviceType: 'BP',
    );
    return null;
  }

  Future<bool> _probeInBodyCon(
    UsbDevice device, {
    required int baudRate,
  }) async {
    UsbPort? probePort;
    StreamSubscription<Uint8List>? subscription;
    final completer = Completer<bool>();
    final buffer = <int>[];
    Timer? timer;

    try {
      probePort = await device.create().timeout(const Duration(seconds: 3));
      if (probePort == null) return false;

      final opened = await probePort.open().timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
      if (!opened) return false;

      await probePort
          .setPortParameters(
            baudRate,
            UsbPort.DATABITS_8,
            UsbPort.STOPBITS_1,
            UsbPort.PARITY_NONE,
          )
          .timeout(const Duration(seconds: 3));
      try {
        await probePort.setDTR(true).timeout(const Duration(seconds: 1));
        await probePort.setRTS(true).timeout(const Duration(seconds: 1));
      } catch (_) {}

      timer = Timer(const Duration(milliseconds: 1200), () {
        if (!completer.isCompleted) completer.complete(false);
      });

      subscription = probePort.inputStream?.listen(
        (data) {
          buffer.addAll(data);
          if (buffer.length > _maxBufferSize) buffer.clear();
          final str = _decode(buffer.where((b) => b != 0x00).toList());
          if (str != null &&
              (str.toUpperCase().contains('CON') ||
                  str.toUpperCase().contains('SCON') ||
                  str.toUpperCase().contains('DCON') ||
                  str.toUpperCase().contains('PCON'))) {
            if (!completer.isCompleted) completer.complete(true);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(false);
        },
        cancelOnError: false,
      );

      await probePort
          .write(Uint8List.fromList(_inBodyConnectionCheckPacket))
          .timeout(const Duration(seconds: 2));
      return await completer.future;
    } catch (_) {
      return false;
    } finally {
      timer?.cancel();
      try {
        await subscription?.cancel();
      } catch (_) {}
      try {
        await probePort?.close();
      } catch (_) {}
    }
  }

  Future<void> _startListeningToDevice(
      String deviceType, int vid, int pid, int baudRate,
      {String? portName}) async {
    if (_activePorts[deviceType] != null) return;

    try {
      final devices = await UsbSerial.listDevices();
      FlutterErrorLogger.device(
          '[MeasurementListener] USB 장치 목록 (${devices.length}개): '
          '${devices.map((d) => 'vid=${d.vid} pid=${d.pid} name=${d.deviceName}').join(', ')}');

      final device = await _selectUsbDeviceForListening(
        deviceType: deviceType,
        devices: devices,
        vid: vid,
        pid: pid,
        baudRate: baudRate,
        portName: portName,
      );
      if (device == null) {
        throw Exception(
            'Device not found: vid=$vid pid=$pid portName=$portName');
      }

      FlutterErrorLogger.device(
          '[MeasurementListener] $deviceType 장치 발견 - vid=${device.vid} pid=${device.pid} name=${device.deviceName}');

      final port = await device.create().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          FlutterErrorLogger.device(
              '[MeasurementListener] $deviceType 포트 생성 타임아웃');
          return null;
        },
      );
      if (port == null) {
        FlutterErrorLogger.device('[MeasurementListener] $deviceType 포트 생성 실패');
        return;
      }

      bool opened = false;
      try {
        opened = await port.open().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            FlutterErrorLogger.device(
                '[MeasurementListener] $deviceType 포트 열기 타임아웃 (5초 초과)');
            return false;
          },
        );
      } catch (e) {
        FlutterErrorLogger.device(
            '[MeasurementListener] $deviceType 포트 열기 예외: $e');
      }
      if (!opened) {
        FlutterErrorLogger.device(
            '[MeasurementListener] 포트 열기 실패 - $deviceType (이미 점유 중일 수 있음)');
        try {
          await port.close();
        } catch (_) {}
        return;
      }

      FlutterErrorLogger.device(
          '[MeasurementListener] $deviceType 포트 열림 - baudRate=$baudRate');

      try {
        // 셀바스 BP250(ACCUNIQ)은 4800bps/2Stop 사양. 그 외 기기는 1Stop.
        final stopBits =
            baudRate == 4800 ? UsbPort.STOPBITS_2 : UsbPort.STOPBITS_1;
        await port
            .setPortParameters(
              baudRate,
              UsbPort.DATABITS_8,
              stopBits,
              UsbPort.PARITY_NONE,
            )
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        FlutterErrorLogger.device(
            '[MeasurementListener] $deviceType setPortParameters 실패: $e');
        try {
          await port.close();
        } catch (_) {}
        return;
      }

      try {
        await port.setDTR(true).timeout(const Duration(seconds: 3));
        await port.setRTS(true).timeout(const Duration(seconds: 3));
      } catch (e) {
        FlutterErrorLogger.device(
            '[MeasurementListener] $deviceType DTR/RTS 설정 실패 (무시): $e');
      }

      if (deviceType.toUpperCase() == 'ST') {
        try {
          await port
              .setFlowControl(UsbPort.FLOW_CONTROL_OFF)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          FlutterErrorLogger.device(
              '[MeasurementListener] $deviceType flowControl 설정 실패 (무시): $e');
        }
        _hrvDecoders[deviceType.toUpperCase()] = HrvFrameDecoder();
      }

      _activePorts[deviceType] = port;
      _activePortNames[deviceType.toUpperCase()] = device.deviceName;
      _buffers[deviceType] = [];
      _portOpenTime[deviceType.toUpperCase()] = DateTime.now();

      // 재삽입 등으로 portName이 바뀐 경우, 실제 연결에 성공한 포트 경로를
      // 저장소에 반영한다. 런타임 연결이 "어떤 포트가 이 기기인지"의 신뢰 기준이므로,
      // 어드민 화면도 이 갱신된 portName(정확 매칭)만으로 정확히 표시된다.
      if (portName != null && portName != device.deviceName) {
        unawaited(_persistResolvedPortName(deviceType, device.deviceName));
      }

      _subscriptions[deviceType] = port.inputStream?.listen(
        (data) => _onDataReceived(deviceType, data),
        onError: (e) {
          FlutterErrorLogger.device(
              '[MeasurementListener] $deviceType 스트림 오류: $e');
          _handleError(deviceType);
        },
        onDone: () => _handleDisconnection(deviceType),
        cancelOnError: false,
      );

      FlutterErrorLogger.device(
          '[MeasurementListener] $deviceType 수신 대기 시작 (inputStream=${port.inputStream != null ? "OK" : "NULL"})');
    } catch (e) {
      FlutterErrorLogger.device('[MeasurementListener] $deviceType 연결 실패: $e');
      return;
    }
  }

  // ─── 데이터 수신 ──────────────────────────────────────────────────────

  void _onDataReceived(String deviceType, Uint8List data) {
    if (deviceType.toUpperCase() == 'ST') {
      _processHrvData(deviceType, data);
      return;
    }

    final buffer = _buffers[deviceType];
    if (buffer == null) return;
    buffer.addAll(data);

    // BP250 진단용 원시 수신 로그 (어떤 바이트가 들어오는지 확인)
    if (_isCelvasBp250(deviceType)) {
      FlutterErrorLogger.device(
        '[BP250] 원시 수신 (${data.length}bytes): ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}',
        errorCode: 'BP250-RX',
        severity: 'INFO',
        deviceType: 'BP',
      );
    }

    if (AMP868Parser.canParseBytes(buffer)) {
      final ampResult = AMP868Parser.parseBytes(buffer);
      if (ampResult != null) {
        int firstIdx = buffer.indexOf(AMP868Parser.headerByte);
        int secondIdx = buffer.indexOf(AMP868Parser.headerByte, firstIdx + 1);
        if (firstIdx != -1 && secondIdx != -1) {
          buffer.removeRange(0, secondIdx + 1);
        }
        FlutterErrorLogger.logInfo('[MeasurementListener] 에이엠피올 BP 868F 결과 파싱 완료 -> 수축기: ${ampResult.systolic}, 이완기: ${ampResult.diastolic}, 맥박: ${ampResult.pulse}');
        _bloodPressureController.add(ampResult);
        return;
      }
    }

    if (deviceType.toUpperCase() == 'HS') {
      FlutterErrorLogger.device(
          '[HS] 원시 데이터 수신 (${data.length}bytes): ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      _processHcBuffer(deviceType, buffer);
      return;
    }

    while (buffer.isNotEmpty) {
      final stxIndex = buffer.indexOf(0x02);
      final etxIndex = buffer.indexOf(0x03);
      final rsIndex = buffer.indexOf(0x1E);

      if (rsIndex != -1) {
        if (etxIndex == -1) {
          if (buffer.length > _maxBufferSize) buffer.clear();
          break;
        }

        final packetData = buffer.sublist(0, etxIndex);
        final removeLength =
            (etxIndex + 2 <= buffer.length) ? etxIndex + 2 : etxIndex + 1;
        buffer.removeRange(0, removeLength);

        final filteredBytes = packetData.where((b) => b != 0x00).toList();
        final dataString = _decode(filteredBytes);
        if (dataString == null) continue;

        _rawDataController.add(dataString);
        _processData(deviceType, dataString);
      } else if (stxIndex != -1 && etxIndex != -1 && stxIndex < etxIndex) {
        if (stxIndex > 0) buffer.removeRange(0, stxIndex);

        final etxAfter = buffer.indexOf(0x03, 1);
        if (etxAfter == -1) break;
        if (buffer.length < etxAfter + 2) break;

        final packet = buffer.sublist(0, etxAfter + 2);
        buffer.removeRange(0, etxAfter + 2);

        if (_validateChecksum(packet)) {
          final dataBytes = packet.sublist(1, etxAfter);
          final dataString = _decode(dataBytes);
          if (dataString == null) continue;

          _rawDataController.add(dataString);
          _processData(deviceType, dataString);
        }
      } else if (etxIndex != -1 && stxIndex == -1) {
        final packetData = buffer.sublist(0, etxIndex);
        final removeLength =
            (etxIndex + 2 <= buffer.length) ? etxIndex + 2 : etxIndex + 1;
        buffer.removeRange(0, removeLength);

        final filteredBytes = packetData.where((b) => b != 0x00).toList();
        final dataString = _decode(filteredBytes);
        if (dataString == null) continue;

        _rawDataController.add(dataString);
        _processData(deviceType, dataString);
      } else {
        if (buffer.length > _maxBufferSize) buffer.clear();
        break;
      }
    }
  }

  /// 자율신경계(HRV) MP-SDK 프레임 디코딩. 정보응답(0x69) 수신 시각을
  /// 기록해 pingHrv()의 헬스체크 판단에 사용하며, 측정 관련 메시지
  /// (Measure Data/Result/Status/Error)는 각 스트림으로 전달한다.
  void _processHrvData(String deviceType, Uint8List data) {
    final key = deviceType.toUpperCase();
    final decoder = _hrvDecoders.putIfAbsent(key, () => HrvFrameDecoder());
    final frames = decoder.add(data);
    for (final frame in frames) {
      _rawDataController.add(
        'HRV code=0x${frame.code.toRadixString(16).padLeft(2, '0')} len=${frame.data.length}',
      );
      switch (frame.code) {
        case HrvProtocol.codeInfo:
          _lastHrvInfoResponse[key] = DateTime.now();
          break;
        case HrvProtocol.codeMeasureData:
          final liveData = HrvLiveData.parse(frame.data);
          if (liveData != null && !_hrvResultController.isClosed) {
            _hrvLiveDataController.add(liveData);
          }
          break;
        case HrvProtocol.codeResult:
          // 추가 HRV(0x48)/APG(0x41) 결과는 무시하고 기본 결과(Basic)만 처리한다.
          if (frame.data.isNotEmpty &&
              frame.data[0] != HrvResultRequestType.hrv &&
              frame.data[0] != HrvResultRequestType.apg) {
            final result = HrvBasicResult.parse(frame.data);
            if (!_hrvResultController.isClosed) {
              _hrvResultController.add(result);
            }
          }
          break;
        case HrvProtocol.codeStatus:
          if (frame.data.isNotEmpty && !_hrvStatusController.isClosed) {
            _hrvStatusController.add(frame.data[0]);
          }
          break;
        case HrvProtocol.codeError:
          if (frame.data.isNotEmpty && !_hrvErrorController.isClosed) {
            _hrvErrorController.add(frame.data[0]);
          }
          break;
      }
    }
  }

  /// 자율신경계(HRV) 측정 시작 명령(Start Message, 0x44) 전송.
  /// previewTime: 10~30초, measureTime: 60초 또는 150초.
  Future<bool> startHrvMeasurement(
    String deviceType, {
    int previewTime = 10,
    int measureTime = 60,
    int sensorType = HrvSensorType.finger,
    required int gender,
    required int age,
    int referenceType = HrvReferenceType.asian,
  }) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;
    try {
      await port.write(HrvFrameEncoder.start(
        previewTime: previewTime,
        measureTime: measureTime,
        sensorType: sensorType,
        gender: gender,
        age: age,
        referenceType: referenceType,
      ));
      return true;
    } catch (e) {
      FlutterErrorLogger.device('[MeasurementListener] HRV 측정 시작 명령 전송 실패: $e');
      return false;
    }
  }

  /// 자율신경계(HRV) 측정 중지 명령(Stop Message, 0x50) 전송.
  Future<bool> stopHrvMeasurement(String deviceType) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;
    try {
      await port.write(HrvFrameEncoder.stop());
      return true;
    } catch (e) {
      FlutterErrorLogger.device('[MeasurementListener] HRV 측정 중지 명령 전송 실패: $e');
      return false;
    }
  }

  /// 자율신경계(HRV) 결과 재요청(Result Request Message, 0x52) 전송.
  Future<bool> requestHrvResult(
    String deviceType, {
    int type = HrvResultRequestType.basic,
  }) async {
    final port = _activePorts[deviceType];
    if (port == null) return false;
    try {
      await port.write(HrvFrameEncoder.resultRequest(type));
      return true;
    } catch (e) {
      FlutterErrorLogger.device('[MeasurementListener] HRV 결과 재요청 전송 실패: $e');
      return false;
    }
  }

  void _processHcBuffer(String deviceType, List<int> buffer) {
    while (buffer.isNotEmpty) {
      final stxIndex = buffer.indexOf(0x02);
      final etxIndex = buffer.indexOf(0x03);

      FlutterErrorLogger.device(
          '[HS] 버퍼 처리 중 (${buffer.length}bytes) stx=$stxIndex etx=$etxIndex');

      if (stxIndex != -1 && etxIndex != -1 && stxIndex < etxIndex) {
        final payload = buffer.sublist(stxIndex + 1, etxIndex);
        buffer.removeRange(0, etxIndex + 1);

        final dataString = _decode(payload);
        FlutterErrorLogger.device('[HS] 패킷 추출됨: "$dataString"');
        if (dataString == null || dataString.isEmpty) continue;

        _rawDataController.add(dataString);
        _processData(deviceType, dataString);
      } else if (stxIndex != -1 && etxIndex == -1) {
        if (buffer.length > _maxBufferSize) buffer.clear();
        break;
      } else if (stxIndex == -1 && etxIndex != -1) {
        buffer.removeRange(0, etxIndex + 1);
      } else {
        if (buffer.length > _maxBufferSize) buffer.clear();
        break;
      }
    }
  }

  String? _decode(List<int> bytes) {
    try {
      return ascii.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        try {
          return String.fromCharCodes(bytes);
        } catch (_) {
          return null;
        }
      }
    }
  }

  bool _validateChecksum(List<int> packet) {
    if (packet.length < 3) return false;

    final etxIndex = packet.indexOf(0x03, 1);
    if (etxIndex == -1 || etxIndex + 1 >= packet.length) return false;

    int sum = 0;
    for (int i = 0; i <= etxIndex; i++) {
      sum += packet[i];
    }

    return (sum & 0xFF) == packet[etxIndex + 1];
  }

  void _processData(String deviceType, String dataString) {
    if (deviceType.toUpperCase() == 'BP') {
      final bpKey = deviceType.toUpperCase();
      // 어떤 BP 프레임이든 수신되면 liveness 갱신 (BP250 버전조회 헬스체크 판단용)
      _lastBpRxTime[bpKey] = DateTime.now();

      // R1 응답은 측정값 유무와 관계없이 기기 생존 신호 → ping 응답 감지에 사용
      if (dataString.startsWith('R1')) {
        _lastR1Response[bpKey] = DateTime.now();
      }

      // ── 셀바스 BP250/BP210(ACCUNIQ) 처리 ────────────────────────────────
      if (_isCelvasBp250(deviceType)) {
        final canBp250 = BP250Parser.canParse(dataString);
        final canBp500 = BP500Parser.canParse(dataString);
        FlutterErrorLogger.device(
          '[BP250] 프레임: "$dataString" (bp250=$canBp250, r1=$canBp500, eot=${dataString.codeUnits.contains(_eot)})',
          errorCode: 'BP250-FRAME',
          severity: 'INFO',
          deviceType: 'BP',
        );
        // EOT(0x04) 수신 = 혈압 정보 전송 종료 → ACK로 기기 저장 결과 삭제
        if (dataString.codeUnits.contains(_eot)) {
          _sendCelvasAck(deviceType);
          return;
        }

        // 1) ACCUNIQ 콤마 포맷 (스펙 기준). ACK는 EOT 수신 후 전송.
        if (canBp250) {
          try {
            _emitBp250Result(deviceType, bpKey, BP250Parser.parse(dataString),
                ackImmediately: false);
            return;
          } catch (_) {}
        }
        // 2) BP500 R1 포맷 fallback (이 기기가 R1으로 응답하는 경우).
        //    R1 프로토콜은 EOT가 없으므로 결과 수신 즉시 ACK 전송.
        if (canBp500) {
          try {
            _emitBp250Result(deviceType, bpKey, BP500Parser.parse(dataString),
                ackImmediately: true);
            return;
          } catch (_) {}
        }
        // BP250로 등록된 기기는 InBody 파싱 경로를 타지 않는다.
        return;
      }

      if (BP500Parser.canParse(dataString)) {
        try {
          final result = BP500Parser.parse(dataString);
          _celvasPingFailureCount[deviceType.toUpperCase()] = 0;

          // 앱 최초 시작 직후 윈도우 내 첫 번째 셀바스 결과: 오프라인 중 저장된 이전 데이터
          // 프로토콜 사양에 따라 ACK(0x06)를 전송해 기기 저장소를 삭제하고, 스트림에는 emit하지 않는다.
          if (_isCelvas(deviceType) && _pendingStartupClear) {
            final deadline = _startupClearDeadline;
            if (deadline != null && DateTime.now().isBefore(deadline)) {
              _pendingStartupClear = false;
              _startupClearDeadline = null;
              _sendCelvasAck(deviceType);
              FlutterErrorLogger.system(
                '[시작초기화] 앱 시작 전 셀바스 저장 데이터 ACK 삭제 완료 (SYS=${result.systolic}, DIA=${result.diastolic})',
              );
              return;
            }
            _pendingStartupClear = false;
            _startupClearDeadline = null;
          }

          _bloodPressureController.add(result);
          if (_isCelvas(deviceType)) {
            _sendCelvasAck(deviceType);
          }
          return;
        } catch (_) {}
      }

      final inBodyKey = deviceType.toUpperCase();
      final inBodyNow = DateTime.now();

      if (dataString.toUpperCase().contains('CON')) {
        _lastInBodyConResponse[inBodyKey] = inBodyNow;
      } else {
        _lastInBodyUserActivity[inBodyKey] = inBodyNow;
        _lastInBodyConResponse[inBodyKey] = inBodyNow;
      }

      if (InBodyParser.canParse(dataString)) {
        try {
          final result = InBodyParser.parse(dataString);
          _bloodPressureController.add(result);
          return;
        } catch (_) {}
      }
    } else if (deviceType.toUpperCase() == 'HS') {
      FlutterErrorLogger.device('[HS] _processData 진입: "$dataString"');
      if (HcParser.canParse(dataString)) {
        try {
          final result = HcParser.parse(dataString);
          FlutterErrorLogger.device(
              '[HS] 파싱 성공 - height=${result.height} weight=${result.weight} bmi=${result.bmi}');
          _heightWeightController.add(result);
        } catch (e) {
          FlutterErrorLogger.device('[HS] 파싱 예외: $e');
        }
      } else {
        FlutterErrorLogger.device('[HS] canParse 실패: "$dataString"');
      }
    }
  }

  /// 앱이 처음 시작될 때 호출한다.
  /// 이후 셀바스로부터 수신되는 첫 번째 BP 결과를 [windowSeconds] 이내라면
  /// ACK로 삭제 처리하고 스트림에 emit하지 않는다.
  /// — 프로토콜 근거: EP1:PC [P3] 측정 결과 삭제 요청 STX(0x02) ACK(0x06) ETX(0x03) SUM(0x0b)
  void beginStartupClear({int windowSeconds = 15}) {
    if (_startupClearDone) return;
    _startupClearDone = true;
    _pendingStartupClear = true;
    _startupClearDeadline =
        DateTime.now().add(Duration(seconds: windowSeconds));
    FlutterErrorLogger.system(
      '[시작초기화] 셀바스 이전 저장 데이터 무시 윈도우 시작 (${windowSeconds}초)',
    );
  }

  /// BP250/BP210 결과 emit 공통 처리 (시작초기화 무시 + 중복 emit 방지 + ACK).
  void _emitBp250Result(
    String deviceType,
    String bpKey,
    BloodPressureResult result, {
    required bool ackImmediately,
  }) {
    _celvasPingFailureCount[bpKey] = 0;

    // 앱 시작 직후 윈도우 내 첫 결과: 오프라인 중 저장된 이전 데이터 → ACK 삭제 후 무시
    if (_pendingStartupClear) {
      final deadline = _startupClearDeadline;
      if (deadline != null && DateTime.now().isBefore(deadline)) {
        _pendingStartupClear = false;
        _startupClearDeadline = null;
        _sendCelvasAck(deviceType);
        FlutterErrorLogger.system(
          '[시작초기화] 앱 시작 전 BP250 저장 데이터 ACK 삭제 완료 (SYS=${result.systolic}, DIA=${result.diastolic})',
        );
        return;
      }
      _pendingStartupClear = false;
      _startupClearDeadline = null;
    }

    // 중복 emit 방지: 동일 결과가 짧은 시간 내 재폴링되어도 한 번만 emit
    final signature =
        '${result.systolic}/${result.diastolic}/${result.pulse}/${result.measuredAt.toIso8601String()}';
    final lastSig = _lastBp250Signature[bpKey];
    final lastEmit = _lastBp250EmitTime[bpKey];
    final isDuplicate = lastSig == signature &&
        lastEmit != null &&
        DateTime.now().difference(lastEmit) < const Duration(seconds: 20);
    if (!isDuplicate) {
      _lastBp250Signature[bpKey] = signature;
      _lastBp250EmitTime[bpKey] = DateTime.now();
      _bloodPressureController.add(result);
    }
    if (ackImmediately) _sendCelvasAck(deviceType);
  }

  void _sendCelvasAck(String deviceType) {
    final port = _activePorts[deviceType];
    if (port == null) return;
    port.write(Uint8List.fromList(_ackPacket));
  }

  // ─── 연결 해제 / 정리 ─────────────────────────────────────────────────

  void _handleError(String deviceType) => _cleanupDevice(deviceType);
  void _handleDisconnection(String deviceType) => _cleanupDevice(deviceType);

  void _cleanupDevice(String deviceType) {
    _subscriptions[deviceType]?.cancel();
    _subscriptions.remove(deviceType);
    _activePorts[deviceType]?.close();
    _activePorts.remove(deviceType);
    _activePortNames.remove(deviceType.toUpperCase());
    _buffers.remove(deviceType);
    _lastR1Response.remove(deviceType.toUpperCase());
    _lastInBodyConResponse.remove(deviceType.toUpperCase());
    _lastInBodyUserActivity.remove(deviceType.toUpperCase());
    _lastInBodyPingAttemptTime.remove(deviceType.toUpperCase());
    _inBodyPingFailureCount.remove(deviceType.toUpperCase());
    _inBodyFailureStreakStart.remove(deviceType.toUpperCase());
    _celvasPingFailureCount.remove(deviceType.toUpperCase());
    _celvasFailureStreakStart.remove(deviceType.toUpperCase());
    _celvasEnqEverResponded.remove(deviceType.toUpperCase());
    _lastBpRxTime.remove(deviceType.toUpperCase());
    _pingInProgress.remove(deviceType.toUpperCase());
    _portOpenTime.remove(deviceType.toUpperCase());
    _hrvDecoders.remove(deviceType.toUpperCase());
    _lastHrvInfoResponse.remove(deviceType.toUpperCase());
    _hrvPingFailureCount.remove(deviceType.toUpperCase());
    _hrvFailureStreakStart.remove(deviceType.toUpperCase());
  }

  Future<void> stopListening() async {
    for (final deviceType in _activePorts.keys.toList()) {
      _cleanupDevice(deviceType);
    }
  }

  void addBloodPressureResult(BloodPressureResult result) {
    _bloodPressureController.add(result);
  }

  bool isPortInUse(String deviceType) => _activePorts[deviceType] != null;

  /// 지정 deviceType(예: 'BP')이 현재 점유 중인 포트 이름(deviceName). 미점유 시 null.
  /// 동일 VID/PID를 공유하는 음주(AL) 선택 로직이 이 포트를 배제하는 데 사용한다.
  String? activePortName(String deviceType) =>
      _activePortNames[deviceType.toUpperCase()];

  bool get isRestarting => _isRestarting;

  bool isPortInUseByVidPid(int vid, int pid) => false;

  void dispose() {
    stopListening();
    _bloodPressureController.close();
    _heightWeightController.close();
    _logController.close();
    _rawDataController.close();
    _hrvResultController.close();
    _hrvLiveDataController.close();
    _hrvStatusController.close();
    _hrvErrorController.close();
  }
}
