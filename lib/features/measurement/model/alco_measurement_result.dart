class AlcoNotification {
  final int stateCode;
  final int battery;
  final int rawBacValue;
  final int errorCode;
  final int calibDays;
  /// 워밍업 예상 시간 (1/100초 단위, 0~300). 0이면 미제공.
  final int warmUpEstimatedCentiseconds;
  /// 기기가 보고하는 현재 측정 모드 (0x00=정밀, 0x01=감지, 0xFF=미제공)
  final int deviceModeCode;

  const AlcoNotification({
    required this.stateCode,
    required this.battery,
    required this.rawBacValue,
    required this.errorCode,
    required this.calibDays,
    this.warmUpEstimatedCentiseconds = 0,
    this.deviceModeCode = 0xFF,
  });

  /// 워밍업 예상 시간 (밀리초)
  int get warmUpEstimatedMs => warmUpEstimatedCentiseconds * 10;

  /// 기기가 정밀모드로 동작 중인지 여부
  bool get isDeviceInPrecisionMode => deviceModeCode == 0x00;

  static AlcoNotification fromUsbPayload(List<int> payload) {
    final stateCode = payload.length > 4 ? (payload[4] & 0xFF) : 0;
    final battery = payload.length > 5 ? (payload[5] & 0xFF) : 0;
    final rawBacValue = payload.length >= 23
        ? (((payload[22] & 0xFF) << 8) | (payload[21] & 0xFF))
        : 0;
    final errorCode = payload.length > 23 ? (payload[23] & 0xFF) : 0;
    // PAYLOAD[18-19]: Warming Up 예상 시간 (1/100초 단위)
    int warmUpCs = 0;
    if (payload.length >= 20) {
      warmUpCs = ((payload[19] & 0xFF) << 8) | (payload[18] & 0xFF);
    }
    // PAYLOAD[20]: 기기 현재 측정 모드 (0x00=정밀, 0x01=감지)
    final deviceModeCode = payload.length > 20 ? (payload[20] & 0xFF) : 0xFF;
    return AlcoNotification(
      stateCode: stateCode,
      battery: battery,
      rawBacValue: rawBacValue,
      errorCode: errorCode,
      calibDays: 0,
      warmUpEstimatedCentiseconds: warmUpCs,
      deviceModeCode: deviceModeCode,
    );
  }

  static AlcoNotification fromBytes(List<int> data) {
    final stateCode = data.isNotEmpty ? (data[0] & 0xFF) : 0;
    final battery = data.length > 1 ? (data[1] & 0xFF) : 0;
    final rawBacValue =
        data.length >= 15 ? (((data[13] & 0xFF) << 8) | (data[14] & 0xFF)) : 0;
    final errorCode = data.length >= 16 ? (data[15] & 0xFF) : 0;
    int calibDays = 0;
    if (data.length >= 20) {
      final msb = data[18] & 0xFF;
      final lsb = data[19] & 0xFF;
      final raw = ((msb & 0x7F) << 8) | lsb;
      final isNegative = (msb & 0x80) != 0;
      calibDays = isNegative ? -raw : raw;
    }
    return AlcoNotification(
      stateCode: stateCode,
      battery: battery,
      rawBacValue: rawBacValue,
      errorCode: errorCode,
      calibDays: calibDays,
    );
  }
}

class AlcoMeasurementResult {
  final bool isSuccess;
  final double bacValue;
  final bool isPass;
  final int errorCode;
  final DateTime measuredAt;

  const AlcoMeasurementResult({
    required this.isSuccess,
    required this.bacValue,
    required this.isPass,
    required this.errorCode,
    required this.measuredAt,
  });

  static const double passThreshold = 0.03;

  static AlcoMeasurementResult fromNotification(
      AlcoNotification notification) {
    final isSuccess =
        notification.stateCode == 0x09 && notification.errorCode == 0x00;
    final bacValue = notification.rawBacValue / 10000.0;
    final isPass = isSuccess && bacValue <= passThreshold;
    return AlcoMeasurementResult(
      isSuccess: isSuccess,
      bacValue: bacValue,
      isPass: isPass,
      errorCode: notification.errorCode,
      measuredAt: DateTime.now(),
    );
  }

  String get bacValueText {
    if (bacValue >= 0.1) return '${bacValue.toStringAsFixed(2)}%';
    return '${bacValue.toStringAsFixed(3)}%';
  }

  String get bacValueRaw {
    if (bacValue >= 0.1) return bacValue.toStringAsFixed(2);
    return bacValue.toStringAsFixed(3);
  }

  String get errorMessage {
    switch (errorCode) {
      case 0x01:
        return '배터리가 부족합니다.';
      case 0x06:
        return '불기 시간이 초과되었습니다.';
      case 0x07:
        return '입김이 너무 약합니다.';
      case 0x1E:
        return '너무 일찍 불기를 멈췄습니다.';
      case 0x1F:
        return '입김이 너무 강합니다.';
      case 0x20:
        return '숨을 들이마셨습니다.';
      default:
        return '측정이 실패했습니다.';
    }
  }
}
