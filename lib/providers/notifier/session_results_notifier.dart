import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionResultsNotifier extends StateNotifier<Map<String, String>> {
  static const _deviceOrder = ['BP', 'HS', 'AL'];

  SessionResultsNotifier() : super({});

  void addResult(String device, String text) {
    state = {...state, device: text};
  }

  void clearResults() {
    state = {};
  }

  String combinedText(String fallback) {
    if (state.length <= 1) return fallback;
    final ordered = _deviceOrder
        .where(state.containsKey)
        .map((d) => state[d]!)
        .toList();
    final others = state.entries
        .where((e) => !_deviceOrder.contains(e.key))
        .map((e) => e.value);
    return [...ordered, ...others].join('\n\n');
  }
}

final sessionResultsProvider =
    StateNotifierProvider<SessionResultsNotifier, Map<String, String>>(
  (ref) => SessionResultsNotifier(),
);
