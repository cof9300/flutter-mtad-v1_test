import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

class InBodyParser {
  static bool canParse(String rawData) {
    if (rawData.isEmpty) return false;
    
    final separator = String.fromCharCode(0x1E);
    if (!rawData.contains(separator)) return false;
    
    final parts = rawData.split(separator);
    bool hasS = false;
    bool hasD = false;
    bool hasP = false;
    
    for (final part in parts) {
      final trimmed = part.replaceAll(RegExp(r'[\x00\s]'), '');
      if (trimmed.isEmpty) continue;
      
      final firstChar = trimmed[0].toUpperCase();
      if (firstChar == 'S') hasS = true;
      if (firstChar == 'D') hasD = true;
      if (firstChar == 'P') hasP = true;
    }
    
    return hasS && hasD && hasP;
  }

  static BloodPressureResult parse(String rawData) {
    if (rawData.isEmpty) {
      throw FormatException('Empty packet data', rawData);
    }

    final separator = String.fromCharCode(0x1E);
    final parts = rawData.split(separator);

    int? systolic;
    int? diastolic;
    int? pulse;
    DateTime measuredAt = DateTime.now();

    for (final part in parts) {
      final trimmed = part.replaceAll(RegExp(r'[\x00\s]'), '');
      if (trimmed.isEmpty) continue;

      final firstChar = trimmed[0].toUpperCase();
      final valueStr = trimmed.length > 1 ? trimmed.substring(1) : '';

      switch (firstChar) {
        case 'S':
          if (valueStr.toUpperCase() == 'STA' ||
              valueStr.toUpperCase() == 'STP' ||
              valueStr.toUpperCase() == 'CON' ||
              valueStr.toUpperCase().startsWith('ERR')) {
            continue;
          }
          final numericStr = valueStr.replaceAll(RegExp(r'[^0-9]'), '');
          if (numericStr.isNotEmpty) {
            final value = int.tryParse(numericStr);
            if (value != null && value > 0 && value < 300) {
              systolic = value;
            }
          }
          break;

        case 'D':
          if (valueStr.toUpperCase() == 'STA' ||
              valueStr.toUpperCase() == 'STP' ||
              valueStr.toUpperCase() == 'CON') {
            continue;
          }
          final numericStr = valueStr.replaceAll(RegExp(r'[^0-9]'), '');
          if (numericStr.isNotEmpty) {
            final value = int.tryParse(numericStr);
            if (value != null && value > 0 && value < 300) {
              diastolic = value;
            }
          }
          break;

        case 'P':
          if (valueStr.toUpperCase() == 'STA' ||
              valueStr.toUpperCase() == 'STP' ||
              valueStr.toUpperCase() == 'CON' ||
              valueStr.toUpperCase().startsWith('ERR')) {
            continue;
          }
          final numericStr = valueStr.replaceAll(RegExp(r'[^0-9]'), '');
          if (numericStr.isNotEmpty) {
            final value = int.tryParse(numericStr);
            if (value != null && value > 0 && value < 300) {
              pulse = value;
            }
          }
          break;

        case 'M':
        case 'R':
          break;
      }
    }

    if (systolic == null || diastolic == null || pulse == null) {
      throw FormatException(
        'Insufficient blood pressure fields',
        rawData,
      );
    }

    if (systolic < diastolic) {
      final temp = systolic;
      systolic = diastolic;
      diastolic = temp;
    }

    if (systolic > 300 || diastolic > 300 || pulse > 300) {
      throw FormatException('Invalid blood pressure values', rawData);
    }

    return BloodPressureResult(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      measuredAt: measuredAt,
    );
  }
}


