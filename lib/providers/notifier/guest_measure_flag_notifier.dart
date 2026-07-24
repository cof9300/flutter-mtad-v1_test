import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestMeasureFlagNotifier extends StateNotifier<bool> {
  GuestMeasureFlagNotifier() : super(false);

  void setGuestMeasureFlag(bool flag) {
    state = flag;
  }

  void clearGuestMeasureFlag() {
    state = false;
  }
}

final guestMeasureFlagProvider =
    StateNotifierProvider<GuestMeasureFlagNotifier, bool>((ref) {
  return GuestMeasureFlagNotifier();
});
