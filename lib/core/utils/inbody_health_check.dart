import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

class InBodyHealthCheck {
  InBodyHealthCheck._();

  static const Duration _responseTimeout = Duration(milliseconds: 3000);
  static const int _maxBufferSize = 512;

  static const List<int> _connectionCheckPacket = [
    0x16, 0x16, 0x01, 0x30, 0x30, 0x02, 0x52, 0x45, 0x03, 0x17,
  ];

  static Future<bool> checkConnection(
    String deviceType, {
    String? deviceName,
  }) async {
    try {
      final mapping = await ServiceLocator()
          .deviceUsbMappingStorage
          .getMappingByDeviceType(deviceType);

      if (mapping == null) return false;

      if (deviceName != null) {
        final lower = deviceName.toLowerCase();
        final isInBody = lower.contains('인바디') || lower.contains('inbody');
        if (!isInBody) return false;
      }

      return await _performHealthCheck(
        vid: mapping.vid,
        pid: mapping.pid,
        baudRate: mapping.baudRate,
        deviceType: deviceType,
      );
    } catch (e) {
      FlutterErrorLogger.device(
        '[InBodyHealthCheck] 연결 확인 오류: $e',
        errorCode: 'HCK-001',
        severity: 'ERROR',
        deviceType: 'BP',
      );
      return false;
    }
  }

  static Future<bool> _performHealthCheck({
    required int vid,
    required int pid,
    required int baudRate,
    String? deviceType,
  }) async {
    if (MeasurementListener().isRestarting) return true;

    if (deviceType != null && MeasurementListener().isPortInUse(deviceType)) {
      // InBody BPBIO320/750은 idle 상태에서 CON 패킷에 응답하지 않는 특성이 있어
      // CON ping 대신 USB 장치 물리 존재 여부(VID/PID 스캔)로 연결을 판단한다.
        // 다만 열린 포트가 stale해져 실제 측정 데이터가 안 들어오는 현장이 있어,
        // UI 연결 상태는 물리 존재 기준으로 유지하되 백그라운드 CON ping으로
        // 통신 무응답 누적 시 MeasurementListener가 포트를 자동 재오픈하게 한다.
      final usbDevices = await UsbSerial.listDevices();
      final physicallyPresent = usbDevices.any((d) => d.vid == vid && d.pid == pid);
      if (!physicallyPresent) {
        FlutterErrorLogger.device(
          '[InBodyHealthCheck] ping 결과: 미연결 (USB 장치 없음)',
          errorCode: 'HCK-001',
          severity: 'ERROR',
          deviceType: 'BP',
          extraContext: {'vid': vid, 'pid': pid},
        );
        } else {
          unawaited(MeasurementListener().pingInBody(deviceType));
      }
      return physicallyPresent;
    }

    UsbPort? port;
    try {
      final usbDevices = await UsbSerial.listDevices();
      final device = usbDevices.cast<UsbDevice?>().firstWhere(
            (d) => d?.vid == vid && d?.pid == pid,
            orElse: () => null,
          );

      if (device == null) {
        FlutterErrorLogger.device('[InBodyHealthCheck] USB 장치 목록에 없음');
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
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      await port.write(Uint8List.fromList(_connectionCheckPacket));

      final response = await _readResponse(port, timeout: _responseTimeout);

      if (response == null || response.isEmpty) {
        FlutterErrorLogger.device(
          '[InBodyHealthCheck] CON 응답 없음 → 미연결',
          errorCode: 'HCK-001',
          severity: 'ERROR',
          deviceType: 'BP',
        );
        return false;
      }

      final isConnected = _hasConResponse(response);
      if (!isConnected) {
        FlutterErrorLogger.device(
          '[InBodyHealthCheck] CON 응답 파싱 실패 → 미연결',
          errorCode: 'HCK-001',
          severity: 'ERROR',
          deviceType: 'BP',
        );
      }
      return isConnected;
    } catch (e) {
      FlutterErrorLogger.device(
        '[InBodyHealthCheck] Connection Check 오류: $e',
        errorCode: 'HCK-001',
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

        final etxIdx = buffer.indexOf(0x03);
        if (etxIdx == -1) return;

        final frameEnd = etxIdx + 2;
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

  static bool _hasConResponse(Uint8List response) {
    try {
      final filtered = response.where((b) => b != 0x00).toList();
      final str = String.fromCharCodes(filtered);
      return str.contains('CON') || str.contains('Con');
    } catch (_) {
      return false;
    }
  }
}
