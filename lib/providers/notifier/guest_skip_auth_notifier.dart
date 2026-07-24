import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestSkipAuthNotifier extends StateNotifier<bool> {
  GuestSkipAuthNotifier() : super(false);

  void setSkipAuth() {
    state = true;
  }

  void clearSkipAuth() {
    state = false;
  }
}

final guestSkipAuthProvider =
    StateNotifierProvider<GuestSkipAuthNotifier, bool>((ref) {
  return GuestSkipAuthNotifier();
});
