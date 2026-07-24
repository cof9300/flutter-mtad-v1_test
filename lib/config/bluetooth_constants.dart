class BluetoothConstants {
  BluetoothConstants._();

  static const String bloodPressureServiceUuid = '1810';

  static const String bloodPressureMeasurementCharUuid = '2A35';

  static const String bloodPressureFeatureCharUuid = '2A49';

  static const String currentTimeServiceUuid = '1805';

  static const String currentTimeCharUuid = '2A2B';

  static const List<String> omronDeviceKeywords = [
    'OMRON',
    'HEM-',
    'HEM',
    'BLESMART',
    'BP',
  ];

  static const int scanTimeoutSeconds = 15;

  static const int dataReceiveDelaySeconds = 1;

  static const int connectionWaitSeconds = 3;

  static const int dataWaitSeconds = 2;

  static const int autoSyncIntervalSeconds = 5;

  static const int duplicateDataThresholdSeconds = 1;

  static const int manualSyncTimeoutSeconds = 10;

  static const int flagUnitKpa = 0x01;
  static const int flagTimestampPresent = 0x02;
  static const int flagPulseRatePresent = 0x04;
  static const int flagUserIdPresent = 0x08;
  static const int flagStatusPresent = 0x10;

  static const String unitMmHg = 'mmHg';
  static const String unitKpa = 'kPa';

  static const int currentTimeDataSize = 10;
}
