class PhoneFormatter {
  static String format(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      return '';
    }

    final length = digits.length;

    if (length <= 3) {
      return digits;
    } else if (length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
  }
}




