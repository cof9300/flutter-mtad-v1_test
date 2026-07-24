class AlcoUsbConstants {
  AlcoUsbConstants._();

  static const int baudRate = 115200;
  static const int dataBits = 8;
  static const int stopBits = 1;

  static const int stx = 0x02;
  static const int etx = 0x03;

  static const int keepAliveIntervalMs = 1500;
  static const int reconnectIntervalSeconds = 5;

  static const int rxStateIndex = 4;
  static const int rxBatteryIndex = 5;
  static const int rxBacLowIndex = 21;
  static const int rxBacHighIndex = 22;
  static const int rxErrorIndex = 23;

  static const int stateReady = 0x01;
  static const int stateWarmUp = 0x05;
  static const int stateWaitBlowing = 0x06;
  static const int stateBlowing = 0x07;
  static const int stateAnalyzing = 0x08;
  static const int stateResult = 0x09;
  static const int stateSleep = 0x0C;
  static const int stateError = 0x81;

  static const int cmdKeepAlive = 0x00;
  static const int cmdStart = 0x01;
  static const int cmdSleepWakeUp = 0x02;

  /// 감지(Quick)모드만 사용. 정밀모드(0x00)는 사용하지 않음.
  static const int modeDetect = 0x01;

  static const int unitBac = 0x04;

  /// 0.03 %BAC = 300 (1/10000 단위)
  static const int defaultAlarmLimit = 300;
  /// 0: Off / 1~3: On (볼륨 레벨)
  static const int defaultSound = 2;

  /// 감지모드 횟수 제한 기본값
  static const int defaultDetectCountLimit = 10000;

  /// 정밀모드 횟수 제한 기본값
  static const int defaultPrecisionCountLimit = 1000;

  /// 교정 주기 기본값 (월)
  static const int defaultCalibrationPeriodMonths = 12;

  static const int minPayloadLength = 24;

  /// TX payload: 인덱스 [0]~[21] = 22바이트
  static const int txPayloadLength = 22;
}
