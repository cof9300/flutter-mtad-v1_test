import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class HeightWeightCalculator {
  static String getBmiStatus(double bmi, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (bmi < 20.9) return l10n.bmiStatusUnderweight;
    if (bmi < 23.0) return l10n.bmiStatusNormal;
    if (bmi < 25.7) return l10n.bmiStatusPreObese;
    if (bmi < 30.0) return l10n.bmiStatusObese1;
    if (bmi < 35.0) return l10n.bmiStatusObese2;
    return l10n.bmiStatusObese3;
  }

  static Color getStatusColor(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == l10n.bmiStatusUnderweight) return const Color(0xFFDECD5A);
    if (status == l10n.bmiStatusNormal) return const Color(0xFF7EBA68);
    if (status == l10n.bmiStatusPreObese) return const Color(0xFF7FB5D5);
    if (status == l10n.bmiStatusObese1) return const Color(0xFFECB150);
    if (status == l10n.bmiStatusObese2) return const Color(0xFFC2503D);
    return const Color(0xFFA52648);
  }

  static Map<String, dynamic> createResultData({
    required double height,
    required double weight,
    required double bmi,
    required BuildContext context,
  }) {
    final status = getBmiStatus(bmi, context);
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return {
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'status': status,
      'datatime': dateStr,
    };
  }
}
