import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

class LastBpResultNotifier extends StateNotifier<BloodPressureResult?> {
  LastBpResultNotifier() : super(null);

  void setResult(BloodPressureResult result) {
    state = result;
  }

  void clearResult() {
    state = null;
  }
}

final lastBpResultProvider =
    StateNotifierProvider<LastBpResultNotifier, BloodPressureResult?>((ref) {
  return LastBpResultNotifier();
});
