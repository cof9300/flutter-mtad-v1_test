class BirthdayValidator {
  static const int maxDigits = 8;

  static String extractDigits(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool canAddDigit(String currentValue, String newDigit) {
    final digits = extractDigits(currentValue);
    if (digits.length >= maxDigits) return false;

    final newDigits = digits + newDigit;

    if (newDigits.length == 5) {
      final monthFirstDigit = int.tryParse(newDigits.substring(4, 5));
      if (monthFirstDigit != null && monthFirstDigit > 1) return false;
    }

    if (newDigits.length == 6) {
      final month = int.tryParse(newDigits.substring(4, 6));
      if (month != null && (month < 1 || month > 12)) return false;
    }

    if (newDigits.length == 7) {
      final year = int.tryParse(newDigits.substring(0, 4));
      final month = int.tryParse(newDigits.substring(4, 6));
      final dayFirstDigit = int.tryParse(newDigits.substring(6, 7));
      if (year != null && month != null && dayFirstDigit != null) {
        if (month < 1 || month > 12) return false;
        final daysInMonth = _getDaysInMonth(year, month);
        final maxDayFirstDigit = daysInMonth ~/ 10;
        if (dayFirstDigit > maxDayFirstDigit) return false;
      }
    }

    if (newDigits.length == 8) {
      final year = int.tryParse(newDigits.substring(0, 4));
      final month = int.tryParse(newDigits.substring(4, 6));
      final day = int.tryParse(newDigits.substring(6, 8));
      if (year != null && month != null && day != null) {
        if (month < 1 || month > 12) return false;
        final daysInMonth = _getDaysInMonth(year, month);
        if (day < 1 || day > daysInMonth) return false;
      } else {
        return false;
      }
    }

    return true;
  }

  static bool isValid(String birthday) {
    final digits = extractDigits(birthday);
    if (digits.length != 8) return false;

    final year = int.tryParse(digits.substring(0, 4));
    final month = int.tryParse(digits.substring(4, 6));
    final day = int.tryParse(digits.substring(6, 8));

    if (year == null || month == null || day == null) return false;
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;

    final daysInMonth = _getDaysInMonth(year, month);
    if (day < 1 || day > daysInMonth) return false;

    return true;
  }

  static int _getDaysInMonth(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        if (_isLeapYear(year)) {
          return 29;
        } else {
          return 28;
        }
      default:
        return 0;
    }
  }

  static bool _isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    return year % 400 == 0;
  }

  static String format(String birthday) {
    final digits = extractDigits(birthday);
    if (digits.length <= 4) {
      return digits;
    } else if (digits.length <= 6) {
      return '${digits.substring(0, 4)}.${digits.substring(4)}';
    } else {
      return '${digits.substring(0, 4)}.${digits.substring(4, 6)}.${digits.substring(6)}';
    }
  }
}

