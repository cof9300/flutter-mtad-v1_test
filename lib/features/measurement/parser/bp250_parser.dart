import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

/// 셀바스 ACCUNIQ BP Series(BP210/BP250 등) 혈압 데이터 패킷 파서
///
/// 통신 사양: 4800bps, 8Bit, 2Stop, No Parity
///
/// 혈압 데이터 패킷 (STX/ETX/BCC 제거 후 ASCII, 콤마 구분):
///   <ID(4)>,<Date(YY/MM/DD)>,<Time(HH/MM)>,<SYS>,<MEAN>,<DIA>,<PULSE>,<Reserved 1~6>
///   예) 0000,19/06/28,12/42,120,093,080,072,...
///
/// BP500(R1,...) 패킷과 구분:
///   - BP250: parts[1](Date), parts[2](Time)에 '/' 포함
///   - BP500: parts[0]=='R1', Date는 'YYMMDD'(슬래시 없음)
class BP250Parser {
  BP250Parser._();

  /// ACCUNIQ 혈압 데이터 패킷이고 실제 측정값이 있는지 확인
  static bool canParse(String rawData) {
    if (rawData.isEmpty) return false;
    final parts = rawData.split(',');
    if (parts.length < 7) return false;

    final date = parts[1].trim(); // YY/MM/DD
    final time = parts[2].trim(); // HH/MM
    // BP500(R1) 및 기타 패킷과 구분: 날짜/시간 필드에 '/' 가 있어야 한다.
    if (!date.contains('/') || !time.contains('/')) return false;

    final sys = int.tryParse(parts[3].trim());
    final dia = int.tryParse(parts[5].trim());
    final pulse = int.tryParse(parts[6].trim());
    if (sys == null || dia == null || pulse == null) return false;

    // 측정 결과 없음(전부 0)은 무시
    if (sys == 0 && dia == 0 && pulse == 0) return false;

    return true;
  }

  /// 패킷 파싱 → BloodPressureResult
  ///
  /// 필드 인덱스:
  ///   [0] ID(4)
  ///   [1] Date(YY/MM/DD)
  ///   [2] Time(HH/MM)
  ///   [3] SYS(최고혈압)
  ///   [4] MEAN(평균혈압)
  ///   [5] DIA(최저혈압)
  ///   [6] PULSE(맥박)
  ///   [7..] Reserved
  static BloodPressureResult parse(String rawData) {
    final parts = rawData.split(',');
    if (parts.length < 7) {
      throw FormatException('Invalid BP250 packet', rawData);
    }

    final systolic = int.tryParse(parts[3].trim());
    final diastolic = int.tryParse(parts[5].trim());
    final pulse = int.tryParse(parts[6].trim());

    if (systolic == null || diastolic == null || pulse == null) {
      throw FormatException('Failed to parse BP250 values', rawData);
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
