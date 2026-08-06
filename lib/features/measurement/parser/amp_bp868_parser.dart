import 'dart:convert';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

/// 에이엠피올 (AMP BP 868F) 통신 프로토콜 파서
/// 프로토콜 문서: AMP-RND-0001
///
/// 시작/종료 구분자: 0x5E ('^')
/// 패킷 구조: 0x5E + 수축기(3자) + 평균(3자) + 이완기(3자) + 맥박(3자) + (부정맥 1자) + 0x5E
class AMP868Parser {
  static const int headerByte = 0x5E; // '^'

  /// 바이트 스트림이 AMP BP 868F 포맷인지 검사
  static bool canParseBytes(List<int> bytes) {
    if (bytes.length < 14) return false;
    int firstIdx = bytes.indexOf(headerByte);
    if (firstIdx == -1) return false;
    int secondIdx = bytes.indexOf(headerByte, firstIdx + 1);
    if (secondIdx == -1) return false;
    
    int length = secondIdx - firstIdx - 1;
    return length >= 12 && length <= 13;
  }

  /// 문자열 포맷이 AMP BP 868F 검사
  static bool canParse(String data) {
    if (data.isEmpty) return false;
    final trimmed = data.trim();
    if (trimmed.startsWith('^') && trimmed.endsWith('^') && trimmed.length >= 14) {
      return true;
    }
    return false;
  }

  /// 바이트 수신 데이터를 BloodPressureResult 모델로 파싱
  static BloodPressureResult? parseBytes(List<int> bytes) {
    try {
      int firstIdx = bytes.indexOf(headerByte);
      if (firstIdx == -1) return null;
      int secondIdx = bytes.indexOf(headerByte, firstIdx + 1);
      if (secondIdx == -1) return null;

      final payloadBytes = bytes.sublist(firstIdx + 1, secondIdx);
      final payloadStr = ascii.decode(payloadBytes).trim();

      return parsePayload(payloadStr);
    } catch (e, stackTrace) {
      FlutterErrorLogger.logError('[AMP868Parser] 바이트 파싱 예외 발생', e, stackTrace);
      return null;
    }
  }

  /// 문자열 데이터를 BloodPressureResult 모델로 파싱
  static BloodPressureResult? parseString(String data) {
    try {
      final trimmed = data.trim();
      int firstIdx = trimmed.indexOf('^');
      int lastIdx = trimmed.lastIndexOf('^');

      if (firstIdx == -1 || lastIdx == -1 || firstIdx == lastIdx) {
        return null;
      }

      final payloadStr = trimmed.substring(firstIdx + 1, lastIdx).trim();
      return parsePayload(payloadStr);
    } catch (e, stackTrace) {
      FlutterErrorLogger.logError('[AMP868Parser] 문자열 파싱 예외 발생', e, stackTrace);
      return null;
    }
  }

  /// 내부 페이로드 파싱 (12자 또는 13자 ASCII 숫자)
  /// 수축기(3) + 평균(3) + 이완기(3) + 맥박(3) [+ 부정맥(1)]
  static BloodPressureResult? parsePayload(String payload) {
    try {
      if (payload.length < 12) {
        FlutterErrorLogger.logWarning('[AMP868Parser] 페이로드 길이가 부족함: $payload');
        return null;
      }

      final sysStr = payload.substring(0, 3);
      final meanStr = payload.substring(3, 6);
      final diaStr = payload.substring(6, 9);
      final pulseStr = payload.substring(9, 12);

      final systolic = int.parse(sysStr);
      final diastolic = int.parse(diaStr);
      final pulse = int.parse(pulseStr);

      FlutterErrorLogger.logInfo(
        '[AMP868Parser] 파싱 성공 -> 수축기: $systolic, 평균: $meanStr, 이완기: $diastolic, 맥박: $pulse',
      );

      return BloodPressureResult(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        measuredAt: DateTime.now(),
        deviceModel: '에이엠피올 (BP868F)',
      );
    } catch (e, stackTrace) {
      FlutterErrorLogger.logError('[AMP868Parser] 페이로드 파싱 실패: $payload', e, stackTrace);
      return null;
    }
  }
}
