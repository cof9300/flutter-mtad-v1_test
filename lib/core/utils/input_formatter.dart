class InputFormatter {
  static const String phonePrefix = '010';
  static const int maskingStartIndex = 7;
  static const int maskingEndIndex = 10;
  static const int maxLength = 11;

  static String formatInput(String input) {
    if (input.contains('.')) {
      return input;
    }

    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      return '';
    }

    final isPhoneNumber = digits.startsWith(phonePrefix);
    final length = digits.length;

    if (isPhoneNumber) {
      return _formatPhoneNumber(digits, length);
    } else {
      return _formatUserNumber(digits, length);
    }
  }

  static String formatDisplay(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      return '';
    }

    final isPhoneNumber = digits.startsWith(phonePrefix);
    
    if (isPhoneNumber && digits.length == maxLength) {
      return _formatPhoneNumberForDisplay(digits);
    }
    
    return digits;
  }

  static String _formatPhoneNumber(String digits, int length) {
    if (length <= 3) {
      return digits;
    } else if (length <= 7) {
      final masked = _applyMaskingRealtime(digits, length);
      return '${masked.substring(0, 3)}-${masked.substring(3)}';
    } else {
      final masked = _applyMaskingRealtime(digits, length);
      return '${masked.substring(0, 3)}-${masked.substring(3, 7)}-${masked.substring(7)}';
    }
  }

  static String _formatPhoneNumberForDisplay(String digits) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  static String _formatUserNumber(String digits, int length) {
    return _applyMaskingRealtime(digits, length);
  }

  static String _applyMaskingRealtime(String digits, int length) {
    if (length <= maskingStartIndex) {
      return digits;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      if (i >= maskingStartIndex && i < maskingEndIndex) {
        buffer.write('*');
      } else {
        buffer.write(digits[i]);
      }
    }
    return buffer.toString();
  }
}

