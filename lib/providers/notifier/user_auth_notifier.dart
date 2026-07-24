import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/response/user_auth_response.dart';

class UserAuthNotifier extends StateNotifier<UserAuthResponse?> {
  UserAuthNotifier() : super(null);

  void setUserAuth(UserAuthResponse response) {
    state = response;
  }

  void clearUserAuth() {
    state = null;
  }
}

final userAuthProvider =
    StateNotifierProvider<UserAuthNotifier, UserAuthResponse?>((ref) {
  return UserAuthNotifier();
});




