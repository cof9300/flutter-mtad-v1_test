import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_template/features/measurement/parser/amp_bp868_parser.dart';

void main() {
  group('AMP868Parser Test', () {
    test('Should correctly parse valid AMP BP 868F packet bytes', () {
      // 0x5E + '120' + '095' + '080' + '075' + 0x5E
      final packetStr = '^120095080075^';
      final bytes = ascii.encode(packetStr);

      expect(AMP868Parser.canParseBytes(bytes), isTrue);

      final result = AMP868Parser.parseBytes(bytes);
      expect(result, isNotNull);
      expect(result!.systolic, equals(120));
      expect(result.diastolic, equals(80));
      expect(result.pulse, equals(75));
      expect(result.deviceModel, equals('에이엠피올 (BP868F)'));
    });

    test('Should handle stream prefix bytes before 0x5E header', () {
      final bytes = [0x00, 0x0E, 0x5E, 0x31, 0x33, 0x30, 0x31, 0x30, 0x30, 0x30, 0x38, 0x35, 0x30, 0x37, 0x30, 0x5E];
      expect(AMP868Parser.canParseBytes(bytes), isTrue);

      final result = AMP868Parser.parseBytes(bytes);
      expect(result, isNotNull);
      expect(result!.systolic, equals(130));
      expect(result.diastolic, equals(85));
      expect(result.pulse, equals(70));
    });

    test('Should return false for non-AMP data', () {
      final invalidBytes = ascii.encode('NORMAL_SERIAL_DATA');
      expect(AMP868Parser.canParseBytes(invalidBytes), isFalse);
    });
  });
}
