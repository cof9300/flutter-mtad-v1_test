import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeaderLogoNotifier extends StateNotifier<String?> {
  HeaderLogoNotifier() : super(null);

  void setLogo(String? logo) {
    state = logo;
  }

  void clearLogo() {
    state = null;
  }
}

final headerLogoProvider =
    StateNotifierProvider<HeaderLogoNotifier, String?>((ref) {
  return HeaderLogoNotifier();
});
