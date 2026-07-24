import 'package:flutter_template/features/measurement/model/height_weight_result.dart';

class HcParser {
  static bool canParse(String data) {
    final cleaned = data.replaceAll(RegExp(r'[\x02\x03]'), '').trim();
    final parts = cleaned.split(',');
    if (parts.length < 5) return false;
    final h = double.tryParse(parts[0].trim());
    final w = double.tryParse(parts[1].trim());
    final b = double.tryParse(parts[4].trim());
    return h != null && w != null && b != null && h > 0 && w > 0;
  }

  static HeightWeightResult parse(String data) {
    final cleaned = data.replaceAll(RegExp(r'[\x02\x03]'), '').trim();
    final parts = cleaned.split(',');
    return HeightWeightResult(
      height: double.parse(parts[0].trim()),
      weight: double.parse(parts[1].trim()),
      bmi: double.parse(parts[4].trim()),
      measuredAt: DateTime.now(),
    );
  }
}
