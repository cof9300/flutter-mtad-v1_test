class BloodPressureResult {
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;

  BloodPressureResult({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'measuredAt': measuredAt.toIso8601String(),
    };
  }

  factory BloodPressureResult.fromJson(Map<String, dynamic> json) {
    return BloodPressureResult(
      systolic: json['systolic'] as int,
      diastolic: json['diastolic'] as int,
      pulse: json['pulse'] as int,
      measuredAt: DateTime.parse(json['measuredAt'] as String),
    );
  }

  @override
  String toString() {
    return 'BloodPressureResult(systolic: $systolic, diastolic: $diastolic, pulse: $pulse, measuredAt: $measuredAt)';
  }
}















