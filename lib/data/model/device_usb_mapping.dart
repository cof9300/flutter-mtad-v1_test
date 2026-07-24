class DeviceUsbMapping {
  final String deviceType;
  final String portName;
  final int vid;
  final int pid;
  final int baudRate;

  const DeviceUsbMapping({
    required this.deviceType,
    required this.portName,
    required this.vid,
    required this.pid,
    this.baudRate = 38400,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'portName': portName,
      'vid': vid,
      'pid': pid,
      'baudRate': baudRate,
    };
  }

  factory DeviceUsbMapping.fromJson(Map<String, dynamic> json) {
    return DeviceUsbMapping(
      deviceType: json['deviceType'] as String,
      portName: json['portName'] as String,
      vid: json['vid'] as int,
      pid: json['pid'] as int,
      baudRate: json['baudRate'] as int? ?? 38400,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceUsbMapping &&
        other.deviceType == deviceType &&
        other.portName == portName &&
        other.vid == vid &&
        other.pid == pid &&
        other.baudRate == baudRate;
  }

  @override
  int get hashCode => Object.hash(deviceType, portName, vid, pid, baudRate);
}














