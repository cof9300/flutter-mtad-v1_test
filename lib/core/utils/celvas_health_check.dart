import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

/// 셀바스 BP-500 연결 상태 확인 (EP1:PC [P3] 프로토콜)
///
/// 통신 규격: 38400bps, 8Bit, No Parity, 1Stop (실측 동작 기준; 문서상 2Stop이나 실기기는 1Stop으로 동작)
///
/// 연결 확인 방식:
///   1. MeasurementListener가 포트 점유 중
///      → pingCelvas() 를 통해 열린 포트로 ENQ 전송 후 R1 응답 대기
///      → 태블릿 USB 연결 여부와 무관하게 혈압계 실제 응답만으로 판단
///   2. 포트 미사용 상태
///      → 임시 포트를 열어 ENQ 전송 후 R1 응답 대기
class CelvasHealthCheck {
  CelvasHealthCheck._();

  static const int _baudRate = 38400;
  // BP210 실기기는 38400/1stop/R1로 동작(스펙상 4800이나 현장에서는 4800 통신 불가).
  // BP250과의 차이는 헬스체크에 ENQ 대신 버전조회(0x56)를 쓰는 것뿐이다.
  static const int _bp250BaudRate = 38400;
  static const Duration _responseTimeout = Duration(milliseconds: 1500);
  static const int _maxBufferSize = 512;

  /// 상태 문의: STX(0x02) + ENQ(0x05) + ETX(0x03) + SUM(0x0a)
  static const List<int> _enqPacket = [0x02, 0x05, 0x03, 0x0a];

  /// 버전 문의(BP250): STX(0x02) + V(0x56) + ETX(0x03) + SUM(0x5b)
  static const List<int> _versionPacket = [0x02, 0x56, 0x03, 0x5b];

  /// 마지막으로 로그를 남긴 연결 상태(deviceType별). 상태가 바뀔 때만 로그를 남겨
  /// 동일 상태가 반복될 때 발생하던 로그 폭증을 방지한다.
  /// 값: 'connected' | 'idle_present' | 'absent'
  static final Map<String, String> _lastLoggedStatus = {};

  static void _logStatusTransition(
    String deviceType,
    String status,
    String message,
    String severity,
  ) {
    final key = deviceType.toUpperCase();
    if (_lastLoggedStatus[key] == status) return; // 동일 상태 → 로그 생략
    _lastLoggedStatus[key] = status;
    FlutterErrorLogger.device(
      message,
      errorCode: 'HCK-002',
      severity: severity,
      deviceType: 'BP',
    );
  }

  static Future<bool> checkConnection(
    String deviceType, {
    String? deviceName,
    bool isBp250 = false,
  }) async {
    try {
      final mapping = await ServiceLocator()
          .deviceUsbMappingStorage
          .getMappingByDeviceType(deviceType);

      if (mapping == null) return false;

      if (deviceName != null) {
        final lower = deviceName.toLowerCase();
        final isCelvas =
            lower.contains('셀바스') || lower.contains('celvas');
        if (!isCelvas) return false;
      }

      return await _performHealthCheck(
        vid: mapping.vid,
        pid: mapping.pid,
        deviceType: deviceType,
        isBp250: isBp250,
      );
    } catch (e) {
      FlutterErrorLogger.device(
        '[CelvasHealthCheck] 연결 확인 오류: $e',
        errorCode: 'HCK-002',
        severity: 'ERROR',
        deviceType: 'BP',
      );
      return false;
    }
  }

  static Future<bool> _performHealthCheck({
    required int vid,
    required int pid,
    String? deviceType,
    bool isBp250 = false,
  }) async {
    // ── Case 1: MeasurementListener가 포트를 점유 중 ────────────────────
    // 별도 포트를 열 수 없으므로 MeasurementListener의 ping을 사용한다.
    // - BP500: ENQ(0x05)에 R1 응답으로 판단
    // - BP250: 유휴 시 ENQ 무응답이므로 버전조회(0x56) 응답으로 판단 (+ENQ로 결과 폴링)
    // 어느 쪽이든 무응답 시 VID/PID 물리 존재 여부를 fallback으로 사용한다.
    if (deviceType != null && MeasurementListener().isPortInUse(deviceType)) {
      final isAlive = isBp250
          ? await MeasurementListener().pingCelvasBp250(
              deviceType,
              timeout: _responseTimeout,
            )
          : await MeasurementListener().pingCelvas(
              deviceType,
              timeout: _responseTimeout,
            );

      if (isAlive) {
        // ENQ 정상 응답 → 연결 (상태 변경 시에만 로그)
        _logStatusTransition(
          deviceType,
          'connected',
          '[CelvasHealthCheck] ENQ 응답 정상 → 연결',
          'INFO',
        );
        return true;
      }

      // ENQ 실패 → USB 어댑터의 물리적 존재 여부로 fallback 판단
      // (어댑터가 없으면 실제 연결 끊김; 어댑터가 있으면 기기 유휴 등으로 무응답)
      final usbDevices = await UsbSerial.listDevices();
      final physicallyPresent = usbDevices.any(
        (d) => d.vid == vid && d.pid == pid,
      );

      if (physicallyPresent) {
        // 유휴 셀바스는 ENQ에 응답하지 않을 수 있으므로 물리 존재로 연결 판단.
        // 동일 상태가 반복될 때 로그 폭증을 막기 위해 상태 전환 시에만 1회 로그.
        _logStatusTransition(
          deviceType,
          'idle_present',
          '[CelvasHealthCheck] ENQ 무응답이나 USB 장치 물리 존재 확인 → 연결로 판단 (유휴 상태 추정)',
          'INFO',
        );
      } else {
        _logStatusTransition(
          deviceType,
          'absent',
          '[CelvasHealthCheck] ENQ 무응답 + USB 장치 없음 → 미연결',
          'WARN',
        );
      }
      return physicallyPresent;
    }

    // ── Case 2: 포트 미사용 → 직접 ENQ 전송 ────────────────────────────
    UsbPort? port;
    try {
      final usbDevices = await UsbSerial.listDevices();
      final device = usbDevices.cast<UsbDevice?>().firstWhere(
            (d) => d?.vid == vid && d?.pid == pid,
            orElse: () => null,
          );

      if (device == null) {
        FlutterErrorLogger.device(
          '[CelvasHealthCheck] USB 장치 목록에 없음',
          errorCode: 'DEV-002',
          severity: 'ERROR',
          deviceType: 'BP',
          extraContext: {'vid': vid, 'pid': pid},
        );
        return false;
      }

      port = await device.create();
      if (port == null) return false;

      final opened = await port.open();
      if (!opened) {
        await port.close();
        return false;
      }

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        isBp250 ? _bp250BaudRate : _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // BP250: 유휴 시 ENQ 무응답 → 상시 응답하는 버전조회(0x56)로 판단
      await port.write(
        Uint8List.fromList(isBp250 ? _versionPacket : _enqPacket),
      );

      final response = await _readResponse(port, timeout: _responseTimeout);

      if (response == null || response.isEmpty) {
        FlutterErrorLogger.device(
          '[CelvasHealthCheck] ${isBp250 ? "버전조회" : "ENQ"} 응답 없음 → 미연결',
          errorCode: 'HCK-002',
          severity: 'WARN',
          deviceType: 'BP',
        );
        return false;
      }

      // BP250: 버전 응답(임의 ASCII)이 비어있지 않으면 연결로 판단
      // BP500: STX(0x02) + 'R'(0x52) 로 시작하는 R1 패킷
      final isConnected = isBp250
          ? (response.isNotEmpty)
          : (response.length >= 2 &&
              response[0] == 0x02 &&
              response[1] == 0x52); // 'R'

      if (!isConnected) {
        FlutterErrorLogger.device(
          '[CelvasHealthCheck] ${isBp250 ? "버전조회" : "ENQ"} 응답 파싱 실패 → 미연결',
          errorCode: 'HCK-002',
          severity: 'WARN',
          deviceType: 'BP',
        );
      }
      return isConnected;
    } catch (e) {
      FlutterErrorLogger.device(
        '[CelvasHealthCheck] 직접 ENQ 오류: $e',
        errorCode: 'HCK-002',
        severity: 'ERROR',
        deviceType: 'BP',
      );
      return false;
    } finally {
      if (port != null) {
        try {
          await port.close();
        } catch (_) {}
      }
    }
  }

  /// ETX(0x03) + SUM 까지 완전한 패킷 수신 후 반환, 타임아웃 시 null
  static Future<Uint8List?> _readResponse(
    UsbPort port, {
    required Duration timeout,
  }) async {
    final completer = Completer<Uint8List?>();
    StreamSubscription<Uint8List>? subscription;
    final buffer = <int>[];

    final timer = Timer(timeout, () {
      subscription?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    subscription = port.inputStream?.listen(
      (data) {
        buffer.addAll(data);
        if (buffer.length > _maxBufferSize) buffer.clear();

        final stxIdx = buffer.indexOf(0x02);
        if (stxIdx == -1) return;
        if (stxIdx > 0) buffer.removeRange(0, stxIdx);

        final etxIdx = buffer.indexOf(0x03, 1);
        if (etxIdx == -1) return;

        final frameEnd = etxIdx + 2; // ETX + SUM
        if (buffer.length < frameEnd) return;

        final frame = Uint8List.fromList(buffer.sublist(0, frameEnd));
        subscription?.cancel();
        timer.cancel();
        if (!completer.isCompleted) completer.complete(frame);
      },
      onError: (_) {
        subscription?.cancel();
        timer.cancel();
        if (!completer.isCompleted) completer.complete(null);
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(null);
      },
      cancelOnError: false,
    );

    return completer.future;
  }
}
