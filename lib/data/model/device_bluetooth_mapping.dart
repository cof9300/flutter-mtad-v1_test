class DeviceBluetoothMapping {
  final String deviceType;
  final String deviceName;
  final String macAddress;
  final String deviceId;
  final bool isEnabled;

  const DeviceBluetoothMapping({
    required this.deviceType,
    required this.deviceName,
    required this.macAddress,
    required this.deviceId,
    this.isEnabled = true,
  });

  DeviceBluetoothMapping copyWith({
    String? deviceType,
    String? deviceName,
    String? macAddress,
    String? deviceId,
    bool? isEnabled,
  }) {
    return DeviceBluetoothMapping(
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      macAddress: macAddress ?? this.macAddress,
      deviceId: deviceId ?? this.deviceId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'deviceName': deviceName,
      'macAddress': macAddress,
      'deviceId': deviceId,
      'isEnabled': isEnabled,
    };
  }

  factory DeviceBluetoothMapping.fromJson(Map<String, dynamic> json) {
    return DeviceBluetoothMapping(
      deviceType: json['deviceType'] as String,
      deviceName: json['deviceName'] as String,
      macAddress: json['macAddress'] as String,
      deviceId: json['deviceId'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceBluetoothMapping &&
        other.deviceType == deviceType &&
        other.deviceName == deviceName &&
        other.macAddress == macAddress &&
        other.deviceId == deviceId &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(deviceType, deviceName, macAddress, deviceId, isEnabled);
}
