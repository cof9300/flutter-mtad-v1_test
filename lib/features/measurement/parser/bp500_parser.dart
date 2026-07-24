import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

/// 셀바스 BP-500 EP1:PC [P3] 프로토콜 파서
///
/// 응답 패킷 구조 (STX/ETX/SUM 제거 후 ASCII 문자열):
///   R1,<ID(9)>,<YYMMDD>,<HHMMSS>,<SYS>,<MEAN>,<DIAS>,<PULSE>,<예비x4>,<심부담x5>,<맥압x3>
///   (P3 추가 필드 심부담·맥압은 수신되나 현재 파싱 대상에서 제외)
///
/// 측정 결과 없음: 모든 항목이 ASCII '0'으로 채워짐 → 무시
/// 측정 결과 있음: 년월일시분초, SYS/MEAN/DIAS/PULSE에 실제 값
class BP500Parser {
  BP500Parser._();

  /// R1로 시작하고 실제 측정 값이 있는 패킷인지 확인
  static bool canParse(String rawData) {
    if (rawData.isEmpty) return false;
    final parts = rawData.split(',');
    if (parts.length < 8 || parts[0].trim() != 'R1') return false;

    // 측정 결과 없음: 날짜(parts[2])가 "000000"이거나 SYS(parts[4])가 "000"
    final dateStr = parts[2].trim();
    final sysStr = parts[4].trim();
    final noMeasurement =
        dateStr.isEmpty || int.tryParse(sysStr) == 0;

    return !noMeasurement;
  }

  /// 패킷 파싱 → BloodPressureResult
  ///
  /// 필드 인덱스:
  ///   [0] R1
  ///   [1] ID (9 bytes)
  ///   [2] YYMMDD
  ///   [3] HHMMSS
  ///   [4] SYS
  ///   [5] MEAN
  ///   [6] DIAS
  ///   [7] PULSE
  ///   [8..11] 예비
  static BloodPressureResult parse(String rawData) {
    final parts = rawData.split(',');

    if (parts.length < 8 || parts[0].trim() != 'R1') {
      throw FormatException('Invalid BP500 packet', rawData);
    }

    final sysStr = parts[4].trim();
    final diasStr = parts[6].trim();
    final pulseStr = parts[7].trim();

    final systolic = int.tryParse(sysStr);
    final diastolic = int.tryParse(diasStr);
    final pulse = int.tryParse(pulseStr);

    if (systolic == null || diastolic == null || pulse == null) {
      throw FormatException('Failed to parse BP values', rawData);
    }

    if (systolic == 0 && diastolic == 0 && pulse == 0) {
      throw FormatException('No measurement data (all zeros)', rawData);
    }

    // 기기 내장 시계는 실제 시간과 맞지 않을 수 있으므로 키오스크/앱의 현재 시간을 사용한다.
    final measuredAt = DateTime.now();

    return BloodPressureResult(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      measuredAt: measuredAt,
    );
  }
}
