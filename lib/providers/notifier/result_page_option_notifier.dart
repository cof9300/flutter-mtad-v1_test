import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/response/result_page_option_response.dart';

class ResultPageOptionNotifier
    extends StateNotifier<ResultPageOptionResponse?> {
  ResultPageOptionNotifier() : super(null);

  void setResultPageOption(ResultPageOptionResponse option) {
    state = option;
  }

  void clearResultPageOption() {
    state = null;
  }
}

final resultPageOptionProvider =
    StateNotifierProvider<ResultPageOptionNotifier, ResultPageOptionResponse?>(
        (ref) {
  return ResultPageOptionNotifier();
});













