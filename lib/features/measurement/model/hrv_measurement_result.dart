import 'dart:typed_data';

import 'package:flutter_template/features/measurement/parser/hrv_frame.dart';

/// 자율신경계(HRV) 측정 완료 결과 + 측정 시각.
/// 결과화면/문자전송 등 UI에서 측정 시각이 함께 필요한 경우 이 래퍼를 사용한다.
class HrvMeasurementResult {
  final HrvBasicResult basic;
  final DateTime measuredAt;

  const HrvMeasurementResult({
    required this.basic,
    required this.measuredAt,
  });
}

/// 자율신경계(HRV) 측정 중 실시간으로 전달되는 Measure Data Message(0x6D) 파싱 결과.
class HrvLiveData {
  final int heartRate;
  final int spo2;
  final int measureError;
  final int sampleCount;

  const HrvLiveData({
    required this.heartRate,
    required this.spo2,
    required this.measureError,
    required this.sampleCount,
  });

  /// 수신된 Pulse Wave 개수 / 500 = 경과 시간(초). (500Hz 샘플링)
  double get elapsedSeconds => sampleCount / 500.0;

  bool get hasFingerError =>
      measureError == HrvMeasureErrorCode.fingerOut ||
      measureError == HrvMeasureErrorCode.sensorDisconnected;

  static HrvLiveData? parse(Uint8List data) {
    if (data.length < 3) return null;
    final int pulseByteLen = data.length - 3;
    final int count = pulseByteLen ~/ 2;
    return HrvLiveData(
      heartRate: data[data.length - 3],
      spo2: data[data.length - 2],
      measureError: data[data.length - 1],
      sampleCount: count,
    );
  }
}

/// 자율신경계(HRV) 측정 완료 후 전달되는 기본 Result Message(0x72) 파싱 결과.
/// PDF "MP-SDK Interface 사양서(Basic)" 3.2.2.1 기본 결과 Message 구조 참고.
class HrvBasicResult {
  final int resultType;
  final int gender;
  final int age;
  final int referenceType;
  final int calculationTime;

  final int averageHeartRate; // 평균 심박수
  final int abnormalBeatCount; // 이상 심박수 개수
  final double meanHrScore; // 심박수 점수
  final double sdnnScore; // 스트레스 대처능력 점수
  final double rmssdScore;
  final double psiScore; // 신체적 스트레스 점수
  final double hrviScore;
  final double tpScore; // 자율신경 활성도 점수
  final double lfScore; // 피로도 점수
  final double hfScore; // 심장 안정도 점수
  final double ratioScore; // 정신적 스트레스 점수
  final double lfNormScore; // 자율신경 균형도 점수
  final int balanceStage; // 자율신경 균형도 단계 (1~5)
  final double totalScore; // 종합점수

  final double arterialElasticityScore; // 동맥혈관탄성도 점수
  final double peripheralElasticityScore; // 말초혈관탄성도 점수
  final int vascularAge; // 혈관연령
  final double vascularHealthScore; // 혈관건강점수
  final int representativeVascularStage; // 대표 혈관 단계 (1~7)
  final List<double> vascularStagePercents;
  final int spo2;

  const HrvBasicResult({
    required this.resultType,
    required this.gender,
    required this.age,
    required this.referenceType,
    required this.calculationTime,
    required this.averageHeartRate,
    required this.abnormalBeatCount,
    required this.meanHrScore,
    required this.sdnnScore,
    required this.rmssdScore,
    required this.psiScore,
    required this.hrviScore,
    required this.tpScore,
    required this.lfScore,
    required this.hfScore,
    required this.ratioScore,
    required this.lfNormScore,
    required this.balanceStage,
    required this.totalScore,
    required this.arterialElasticityScore,
    required this.peripheralElasticityScore,
    required this.vascularAge,
    required this.vascularHealthScore,
    required this.representativeVascularStage,
    required this.vascularStagePercents,
    required this.spo2,
  });

  bool get isGenderMale => gender == HrvGenderCode.male;

  static HrvBasicResult parse(Uint8List data) {
    final ByteData bd = ByteData.sublistView(data);
    double f(int offset) {
      if (offset < 0 || offset + 4 > data.length) return 0.0;
      return bd.getFloat32(offset, Endian.little);
    }

    int u(int offset) {
      if (offset < 0 || offset >= data.length) return 0;
      return data[offset];
    }

    const int hrv = 5;
    const int apg = 52;
    return HrvBasicResult(
      resultType: u(0),
      gender: u(1),
      age: u(2),
      referenceType: u(3),
      calculationTime: u(4),
      averageHeartRate: u(hrv),
      abnormalBeatCount: u(hrv + 1),
      meanHrScore: f(hrv + 2),
      sdnnScore: f(hrv + 6),
      rmssdScore: f(hrv + 10),
      psiScore: f(hrv + 14),
      hrviScore: f(hrv + 18),
      tpScore: f(hrv + 22),
      lfScore: f(hrv + 26),
      hfScore: f(hrv + 30),
      ratioScore: f(hrv + 34),
      lfNormScore: f(hrv + 38),
      balanceStage: u(hrv + 42),
      totalScore: f(hrv + 43),
      arterialElasticityScore: f(apg),
      peripheralElasticityScore: f(apg + 4),
      vascularAge: u(apg + 8),
      vascularHealthScore: f(apg + 9),
      representativeVascularStage: u(apg + 13),
      vascularStagePercents: <double>[
        f(apg + 14),
        f(apg + 18),
        f(apg + 22),
        f(apg + 26),
        f(apg + 30),
        f(apg + 34),
        f(apg + 38),
      ],
      spo2: u(apg + 42),
    );
  }
}
