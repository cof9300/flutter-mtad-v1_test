class AlcoBluetoothConstants {
  AlcoBluetoothConstants._();

  static const String serviceUuid = 'FFE0';
  static const String notifyCharUuid = 'DA01';
  static const String writeCharUuid = 'DA20';

  static const String scanNamePrefix = 'ALCOFIND';

  static const int cmdStandby = 0x01;
  static const int cmdWarmUp = 0x05;

  static const int stateStandby = 0x01;
  static const int stateWarmUp = 0x05;
  static const int stateWaitBlowing = 0x06;
  static const int stateBlowing = 0x07;
  static const int stateAnalyzing = 0x08;
  static const int stateResult = 0x09;
  static const int stateError = 0x81;

  static const int errorNone = 0x00;
  static const int errorLowBattery = 0x01;
  static const int errorBlowTimeout = 0x06;
  static const int errorWeakBlow = 0x07;
  static const int errorEarlyStop = 0x1E;
  static const int errorStrongBlow = 0x1F;
  static const int errorInhale = 0x20;

  static const int unitBac = 0x00;
  static const int unitPermille = 0x01;
  static const int unitUgL = 0x02;
  static const int unitMgL = 0x03;
  static const int unitMg100mL = 0x04;
  static const int unitG210L = 0x05;

  static const int defaultAlarmLimit = 0;
  static const int defaultUnit = unitBac;

  static const int scanTimeoutSeconds = 15;
  static const int periodicReconnectSeconds = 5;
  static const int connectionStabilizeMs = 1000;
}
