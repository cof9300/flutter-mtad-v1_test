import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeasureIdNotifier extends StateNotifier<String?> {
  MeasureIdNotifier() : super(null);

  void setMeasureId(String measureId) {
    state = measureId;
  }

  void clearMeasureId() {
    state = null;
  }
}

final measureIdProvider = StateNotifierProvider<MeasureIdNotifier, String?>((ref) {
  return MeasureIdNotifier();
});














