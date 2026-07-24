import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeaderTitleNotifier extends StateNotifier<String?> {
  HeaderTitleNotifier() : super(null);

  void setTitle(String? title) {
    state = title;
  }

  void clearTitle() {
    state = null;
  }
}

final headerTitleProvider = StateNotifierProvider<HeaderTitleNotifier, String?>((ref) {
  return HeaderTitleNotifier();
});

