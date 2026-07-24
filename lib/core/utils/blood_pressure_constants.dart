import 'package:flutter/material.dart';

class BloodPressureConstants {
  BloodPressureConstants._();

  static const int normalSystolicMax = 119;
  static const int normalDiastolicMax = 79;

  static const int cautionSystolicMax = 129;
  static const int cautionDiastolicMax = 84;

  static const int preHypertensionSystolicMax = 139;
  static const int preHypertensionDiastolicMax = 89;

  static const int hypertensionStage1SystolicMax = 159;
  static const int hypertensionStage1DiastolicMax = 99;

  static const int hypertensionStage2SystolicMax = 179;
  static const int hypertensionStage2DiastolicMax = 119;

  static const Color normalColor = Color(0xFF6FB95A);
  static const Color cautionColor = Color(0xFFF5D547);
  static const Color preHypertensionColor = Color(0xFFE7A340);
  static const Color hypertensionStage1Color = Color(0xFFD66C5C);
  static const Color hypertensionStage2Color = Color(0xFFB74644);
  static const Color hypertensionStage3Color = Color(0xFF8B2A3A);

  static Color getStatusColor(String status) {
    switch (status) {
      case '정상':
        return normalColor;
      case '주의혈압':
        return cautionColor;
      case '전고혈압':
        return preHypertensionColor;
      case '고혈압1기':
        return hypertensionStage1Color;
      case '고혈압2기':
        return hypertensionStage2Color;
      default:
        return normalColor;
    }
  }

  static List<BloodPressureRange> getChartRanges() {
    return [
      BloodPressureRange(
        label: '정상',
        min: 0,
        max: normalSystolicMax,
        color: normalColor,
      ),
      BloodPressureRange(
        label: '주의혈압',
        min: normalSystolicMax + 1,
        max: cautionSystolicMax,
        color: cautionColor,
      ),
      BloodPressureRange(
        label: '전고혈압',
        min: cautionSystolicMax + 1,
        max: preHypertensionSystolicMax,
        color: preHypertensionColor,
      ),
      BloodPressureRange(
        label: '고혈압1기',
        min: preHypertensionSystolicMax + 1,
        max: hypertensionStage1SystolicMax,
        color: hypertensionStage1Color,
      ),
      BloodPressureRange(
        label: '고혈압2기',
        min: hypertensionStage1SystolicMax + 1,
        max: 999,
        color: hypertensionStage2Color,
      ),
    ];
  }
}

class BloodPressureRange {
  final String label;
  final int min;
  final int max;
  final Color color;

  BloodPressureRange({
    required this.label,
    required this.min,
    required this.max,
    required this.color,
  });
}




