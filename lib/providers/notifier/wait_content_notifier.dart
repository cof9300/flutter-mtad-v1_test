import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/response/wait_page_option_response.dart';

class WaitContentNotifier extends StateNotifier<List<WaitPageContent>> {
  WaitContentNotifier() : super([]);

  void setContents(List<WaitPageContent> contents) {
    state = contents;
  }

  void clearContents() {
    state = [];
  }
}

final waitContentProvider =
    StateNotifierProvider<WaitContentNotifier, List<WaitPageContent>>((ref) {
  return WaitContentNotifier();
});
