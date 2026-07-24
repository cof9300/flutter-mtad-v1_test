import 'dart:math';

class SFloatParser {
  SFloatParser._();

  static const int _valueNaN = 0x07FF;
  static const int _valueNRes = 0x0800;
  static const int _valuePositiveInfinity = 0x07FE;
  static const int _valueNegativeInfinity = 0x0802;
  static const int _valueReserved = 0x0801;

  static const int _mantissaMask = 0x0FFF;
  static const int _mantissaSignBit = 0x0800;
  static const int _mantissaComplement = 0x1000;

  static const int _exponentMask = 0x0F;
  static const int _exponentSignBit = 0x08;
  static const int _exponentComplement = 0x10;

  static double parseSFloat(int value) {
    if (value == _valueNaN || value == _valueNRes || value == _valueReserved) {
      return double.nan;
    } else if (value == _valuePositiveInfinity) {
      return double.infinity;
    } else if (value == _valueNegativeInfinity) {
      return double.negativeInfinity;
    }

    int mantissa = value & _mantissaMask;

    if ((mantissa & _mantissaSignBit) != 0) {
      mantissa = -((_mantissaComplement - mantissa) & _mantissaMask);
    }

    int exponent = (value >> 12) & _exponentMask;

    if ((exponent & _exponentSignBit) != 0) {
      exponent = -((_exponentComplement - exponent) & _exponentMask);
    }

    return (mantissa * pow(10, exponent)).toDouble();
  }

  static double parseSFloatFromBytes(List<int> bytes) {
    if (bytes.length != 2) {
      throw ArgumentError('SFLOAT requires exactly 2 bytes');
    }

    final value = bytes[0] | (bytes[1] << 8);
    return parseSFloat(value);
  }
}
