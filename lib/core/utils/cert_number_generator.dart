import 'dart:math';

class CertNumberGenerator {
  static String generate() {
    final random = Random();
    final number = random.nextInt(9000) + 1000;
    return number.toString();
  }
}
