import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/features/measurement/parser/hrv_frame.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

/// 자율신경계(HRV, MP-SDK) 연결 상태 확인
///
/// 통신 규격: 115200bps, 8Bit, No Parity, 1Stop
///
/// 연결 확인 방식:
///   1. MeasurementListener가 포트 점유 중
///      → pingHrv() 를 통해 열린 포트로 정보조회(0x49) 전송 후 정보응답(0x69) 대기
///   2. 포트 미사용 상태
///      → 임시 포트를 열어 정보조회 전송 후 정보응답 대기
class HrvHealthCheck {
  HrvHealthCheck._();

  static const int _baudRate = 115200;
  static const Duration _responseTimeout = Duration(milliseconds: 1500);

  static Future<bool> checkConnection(String deviceType) async {
    try {
      final mapping = await ServiceLocator()
          .deviceUsbMappingStorage
          .getMappingByDeviceType(deviceType);

      if (mapping == null) return false;

      return await _performHealthCheck(
        vid: mapping.vid,
        pid: mapping.pid,
        deviceType: deviceType,
      );
    } catch (e) {
      FlutterErrorLogger.device(
        '[HrvHealthCheck] 연결 확인 오류: $e',
        errorCode: 'HCK-004',
        severity: 'ERROR',
        deviceType: 'ST',
      );
      return false;
    }
  }

  static Future<bool> _performHealthCheck({
    required int vid,
    required int pid,
    String? deviceType,
  }) async {
    // ── Case 1: MeasurementListener가 포트를 점유 중 ────────────────────
    if (deviceType != null && MeasurementListener().isPortInUse(deviceType)) {
      final isAlive = await MeasurementListener().pingHrv(
        deviceType,
        timeout: _responseTimeout,
      );

      if (isAlive) return true;

      // 정보조회 무응답 → USB 어댑터의 물리적 존재 여부로 fallback 판단
      final usbDevices = await UsbSerial.listDevices();
      final physicallyPresent =
          usbDevices.any((d) => d.vid == vid && d.pid == pid);

      if (!physicallyPresent) {
        FlutterErrorLogger.device(
          '[HrvHealthCheck] 정보조회 무응답 + USB 장치 없음 → 미연결',
          errorCode: 'HCK-004',
          severity: 'WARN',
          deviceType: 'ST',
        );
      }
      return physicallyPresent;
    }

    // ── Case 2: 포트 미사용 → 직접 정보조회 전송 ────────────────────────
    UsbPort? port;
    try {
      final usbDevices = await UsbSerial.listDevices();
      final device = usbDevices.cast<UsbDevice?>().firstWhere(
            (d) => d?.vid == vid && d?.pid == pid,
            orElse: () => null,
          );

      if (device == null) {
        FlutterErrorLogger.device(
          '[HrvHealthCheck] USB 장치 목록에 없음',
          errorCode: 'HCK-004',
          severity: 'ERROR',
          deviceType: 'ST',
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
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      try {
        await port.setFlowControl(UsbPort.FLOW_CONTROL_OFF);
      } catch (_) {}

      final gotInfo = await _sendAndAwaitInfo(port, timeout: _responseTimeout);

      if (!gotInfo) {
        FlutterErrorLogger.device(
          '[HrvHealthCheck] 정보조회 응답 없음 → 미연결',
          errorCode: 'HCK-004',
          severity: 'WARN',
          deviceType: 'ST',
        );
      }
      return gotInfo;
    } catch (e) {
      FlutterErrorLogger.device(
        '[HrvHealthCheck] 직접 정보조회 오류: $e',
        errorCode: 'HCK-004',
        severity: 'ERROR',
        deviceType: 'ST',
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

  static Future<bool> _sendAndAwaitInfo(
    UsbPort port, {
    required Duration timeout,
  }) async {
    final completer = Completer<bool>();
    StreamSubscription<Uint8List>? subscription;
    final decoder = HrvFrameDecoder();

    final timer = Timer(timeout, () {
      subscription?.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    subscription = port.inputStream?.listen(
      (data) {
        final frames = decoder.add(data);
        for (final frame in frames) {
          if (frame.code == HrvProtocol.codeInfo) {
            subscription?.cancel();
            timer.cancel();
            if (!completer.isCompleted) completer.complete(true);
            return;
          }
        }
      },
      onError: (_) {
        subscription?.cancel();
        timer.cancel();
        if (!completer.isCompleted) completer.complete(false);
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(false);
      },
      cancelOnError: false,
    );

    await port.write(HrvFrameEncoder.infoRequest());
    return completer.future;
  }
}
