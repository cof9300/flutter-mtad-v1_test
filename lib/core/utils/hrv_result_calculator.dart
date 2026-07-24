import 'package:intl/intl.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';

/// 자율신경계(HRV) 측정 결과의 단계(등급) 산출과
/// set-result API(device: 'ST') 전송용 24개 필드 매핑을 담당한다.
///
/// 기준값은 MP-SDK Interface 사양서(Basic)의 "결과 기준값" 표를 그대로 따른다.
/// - 5단계 점수(심박수/신체적·정신적 스트레스/피로도/스트레스 대처능력 등): 20점 단위 균등 구간.
/// - 혈관탄성도(동맥/말초) 3단계: 30 / 70 기준 (표준이하 · 표준 · 표준이상).
/// - 대표 혈관 단계(1~7)는 기기가 직접 산출하는 단계값으로, "N단계" 텍스트로 표시한다.
/// - 자율신경 균형도 단계(1~5)도 기기가 직접 산출한다.
class HrvResultCalculator {
  HrvResultCalculator._();

  /// 0~100 점수를 5단계로 변환.
  /// 매우나쁨(매우낮음): x < 20
  /// 나쁨(낮음): 20 <= x < 40
  /// 정상: 40 <= x < 60
  /// 좋음(높음): 60 <= x < 80
  /// 매우좋음(매우높음): 80 <= x
  static int step5(double score) {
    if (score >= 80) return 5;
    if (score >= 60) return 4;
    if (score >= 40) return 3;
    if (score >= 20) return 2;
    return 1;
  }

  /// 혈관탄성도(동맥/말초) 전용 3단계.
  /// 표준이하: x < 30 / 표준: 30 <= x <= 70 / 표준이상: 70 < x
  static int elasticityStep3(double score) {
    if (score > 70) return 3;
    if (score >= 30) return 2;
    return 1;
  }

  static const List<String> _step5Labels = <String>[
    '', // index 0 미사용
    '매우나쁨',
    '나쁨',
    '정상',
    '좋음',
    '매우좋음',
  ];

  /// 심박수(MeanHR Score) 전용 5단계 라벨.
  static const List<String> _heartRateStep5Labels = <String>[
    '', // index 0 미사용
    '매우낮음',
    '낮음',
    '정상',
    '높음',
    '매우높음',
  ];

  static const List<String> _elasticityStep3Labels = <String>[
    '', // index 0 미사용
    '표준이하',
    '표준',
    '표준이상',
  ];

  static String step5Label(int step) => _step5Labels[step.clamp(1, 5)];

  static String heartRateStep5Label(int step) =>
      _heartRateStep5Labels[step.clamp(1, 5)];

  static String elasticityStep3Label(int step) =>
      _elasticityStep3Labels[step.clamp(1, 3)];

  /// 자율신경 균형도 단계(1~5, 기기 원본값)의 표시 텍스트.
  static String balanceStageLabel(int stage) {
    switch (stage) {
      case 1:
        return '교감 항진, 매우 불균형';
      case 2:
        return '교감 항진, 불균형';
      case 3:
        return '균형';
      case 4:
        return '부교감 항진, 불균형';
      case 5:
        return '부교감 항진, 매우 불균형';
      default:
        return '-';
    }
  }

  /// 대표 혈관 단계(1~7, 기기 원본값)의 표시 텍스트.
  /// 사양서: 0x01 → 1단계, 0x02 → 2단계, ..., 0x07 → 7단계.
  static String vascularStageLabel(int stage) => '${stage.clamp(1, 7)}단계';

  /// float32 파싱 오차 등으로 발생하는 긴 소수점을 소수점 1자리로 정리한다.
  static double _round1(double value) =>
      double.parse(value.toStringAsFixed(1));

  /// MP-SDK 기본 결과(HrvBasicResult)를 set-result API(device: 'ST')에
  /// 전송할 평탄화된(flat) 24개 필드 Map으로 변환한다.
  /// 소수점이 포함된 점수 값은 모두 소수점 1자리까지만 전달한다.
  static Map<String, dynamic> createResultData({
    required HrvBasicResult result,
    DateTime? measuredAt,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final dateText = dateFormat.format(measuredAt ?? DateTime.now());

    return {
      'heartrate_avg': result.averageHeartRate,
      'heartrate_score': _round1(result.meanHrScore),
      'heartrate_step': step5(result.meanHrScore),
      'heartrate_ng': result.abnormalBeatCount,
      'jayul_activity_score': _round1(result.tpScore),
      'jayul_activity_step': step5(result.tpScore),
      'piro_score': _round1(result.lfScore),
      'piro_step': step5(result.lfScore),
      'heart_stability_score': _round1(result.hfScore),
      'heart_stability_step': step5(result.hfScore),
      'jayul_balance_step': result.balanceStage,
      'physical_stress_score': _round1(result.psiScore),
      'physical_stress_step': step5(result.psiScore),
      'mental_stress_score': _round1(result.ratioScore),
      'mental_stress_step': step5(result.ratioScore),
      'stress_ability_score': _round1(result.sdnnScore),
      'stress_ability_step': step5(result.sdnnScore),
      'total_grade': _round1(result.totalScore),
      'dongmaek_tansung_score': _round1(result.arterialElasticityScore),
      'dongmaek_tansung_step': elasticityStep3(result.arterialElasticityScore),
      'malcho_tansung_score': _round1(result.peripheralElasticityScore),
      'malcho_tansung_step': elasticityStep3(result.peripheralElasticityScore),
      'bloodvessel_age': result.vascularAge,
      'bloodvessel_score': _round1(result.vascularHealthScore),
      'bloodvessel_step': result.representativeVascularStage,
      'bloodvessel_step_status':
          vascularStageLabel(result.representativeVascularStage),
      'datatime': dateText,
    };
  }
}
