class PhoneValidator {
  static const int maxDigits = 11;

  static String extractDigits(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool canAddDigit(String currentValue) {
    return extractDigits(currentValue).length < maxDigits;
  }
}

