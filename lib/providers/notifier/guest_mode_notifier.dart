import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false);

  void setGuestMode(bool isGuestMode) {
    state = isGuestMode;
  }

  void clearGuestMode() {
    state = false;
  }
}

final guestModeProvider =
    StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  return GuestModeNotifier();
});
