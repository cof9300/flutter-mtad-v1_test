import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';

class AgreementOptionNotifier
    extends StateNotifier<AgreementOptionResponse?> {
  AgreementOptionNotifier() : super(null);

  void setAgreementOption(AgreementOptionResponse option) {
    state = option;
  }

  void clearAgreementOption() {
    state = null;
  }
}

final agreementOptionProvider = StateNotifierProvider<AgreementOptionNotifier,
    AgreementOptionResponse?>((ref) {
  return AgreementOptionNotifier();
});


