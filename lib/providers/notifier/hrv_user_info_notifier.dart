import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 자율신경계(HRV) 측정 전 입력받은 사용자 정보 (성별, 생년월일).
/// 측정 시작 커맨드(MP-SDK)에 성별/나이가 필요하므로 측정화면에서 참조한다.
class HrvUserInfo {
  final String gender; // 'M' or 'F'
  final String birthday; // yyyyMMdd (8 digits)

  const HrvUserInfo({required this.gender, required this.birthday});

  int get age {
    final year = int.tryParse(birthday.substring(0, 4)) ?? 0;
    if (year == 0) return 0;
    final now = DateTime.now();
    var age = now.year - year;
    final month = int.tryParse(birthday.substring(4, 6)) ?? 1;
    final day = int.tryParse(birthday.substring(6, 8)) ?? 1;
    if (now.month < month || (now.month == month && now.day < day)) {
      age -= 1;
    }
    return age;
  }
}

class HrvUserInfoNotifier extends StateNotifier<HrvUserInfo?> {
  HrvUserInfoNotifier() : super(null);

  void setUserInfo({required String gender, required String birthday}) {
    state = HrvUserInfo(gender: gender, birthday: birthday);
  }

  void clear() {
    state = null;
  }
}

final hrvUserInfoProvider =
    StateNotifierProvider<HrvUserInfoNotifier, HrvUserInfo?>((ref) {
  return HrvUserInfoNotifier();
});
