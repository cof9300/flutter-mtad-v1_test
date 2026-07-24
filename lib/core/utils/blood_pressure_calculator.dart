import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BloodPressureCalculator {
  static String getStatus(int systolic, int diastolic, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (systolic >= 160 || diastolic >= 100) {
      return l10n.bpStatusHypertension2;
    } else if (systolic >= 140 || diastolic >= 90) {
      return l10n.bpStatusHypertension1;
    } else if (systolic >= 130 || diastolic >= 85) {
      return l10n.bpStatusPreHypertension;
    } else if (systolic >= 120 || diastolic >= 80) {
      return l10n.bpStatusCaution;
    } else {
      return l10n.bpStatusNormal;
    }
  }

  static Map<String, dynamic> createResultData({
    required int systolic,
    required int diastolic,
    required int pulse,
    required BuildContext context,
  }) {
    return {
      'high': systolic,
      'low': diastolic,
      'pulse': pulse,
      'status': getStatus(systolic, diastolic, context),
    };
  }
}
