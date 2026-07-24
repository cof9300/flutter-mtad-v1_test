import 'package:flutter_template/core/utils/sfloat_parser.dart';
import 'package:flutter_template/config/bluetooth_constants.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

class OmronBpParser {
  OmronBpParser._();

  static const int _timestampSize = 7;
  static const int _sfloatSize = 2;

  static BloodPressureResult parse(List<int> data) {
    if (data.length < 7) {
      throw ArgumentError(
        'Blood Pressure Measurement data too short: ${data.length} bytes',
      );
    }

    int offset = 0;

    final flags = _parseFlags(data[offset++]);

    final systolic = SFloatParser.parseSFloat(
      data[offset] | (data[offset + 1] << 8),
    );
    offset += _sfloatSize;

    final high = systolic.round();

    final diastolic = SFloatParser.parseSFloat(
      data[offset] | (data[offset + 1] << 8),
    );
    offset += _sfloatSize;

    final low = diastolic.round();

    final _ = SFloatParser.parseSFloat(data[offset] | (data[offset + 1] << 8));
    offset += _sfloatSize;

    DateTime timestamp = DateTime.now();
    if (flags.hasTimestamp && data.length >= offset + _timestampSize) {
      timestamp = _parseTimestamp(data, offset);
      offset += _timestampSize;
    }

    double? pulseRate;
    if (flags.hasPulseRate && data.length >= offset + _sfloatSize) {
      pulseRate = SFloatParser.parseSFloat(
        data[offset] | (data[offset + 1] << 8),
      );
      offset += _sfloatSize;
    }

    final pulse = pulseRate != null ? pulseRate.round() : 0;

    if (flags.hasUserId && data.length >= offset + 1) {
      offset += 1;
    }

    if (flags.hasStatus && data.length >= offset + 2) {
      offset += 2;
    }

    return BloodPressureResult(
      systolic: high,
      diastolic: low,
      pulse: pulse,
      measuredAt: timestamp,
    );
  }

  static _BloodPressureFlags _parseFlags(int flagsByte) {
    return _BloodPressureFlags(
      isKpa: (flagsByte & BluetoothConstants.flagUnitKpa) != 0,
      hasTimestamp: (flagsByte & BluetoothConstants.flagTimestampPresent) != 0,
      hasPulseRate: (flagsByte & BluetoothConstants.flagPulseRatePresent) != 0,
      hasUserId: (flagsByte & BluetoothConstants.flagUserIdPresent) != 0,
      hasStatus: (flagsByte & BluetoothConstants.flagStatusPresent) != 0,
    );
  }

  static DateTime _parseTimestamp(List<int> data, int offset) {
    final year = data[offset] | (data[offset + 1] << 8);
    final month = data[offset + 2];
    final day = data[offset + 3];
    final hour = data[offset + 4];
    final minute = data[offset + 5];
    final second = data[offset + 6];

    try {
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      return DateTime.now();
    }
  }
}

class _BloodPressureFlags {
  final bool isKpa;
  final bool hasTimestamp;
  final bool hasPulseRate;
  final bool hasUserId;
  final bool hasStatus;

  _BloodPressureFlags({
    required this.isKpa,
    required this.hasTimestamp,
    required this.hasPulseRate,
    required this.hasUserId,
    required this.hasStatus,
  });
}
