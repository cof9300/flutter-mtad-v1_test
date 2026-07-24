class UsbDeviceInfo {
  final String portName;
  final int vid;
  final int pid;
  final String deviceName;
  final String? productName;
  final String? manufacturerName;

  const UsbDeviceInfo({
    required this.portName,
    required this.vid,
    required this.pid,
    required this.deviceName,
    this.productName,
    this.manufacturerName,
  });

  String get displayName {
    if (productName != null && productName!.isNotEmpty) return productName!;
    if (manufacturerName != null && manufacturerName!.isNotEmpty) {
      return manufacturerName!;
    }
    final known = _knownChipName(vid, pid);
    if (known != null) return known;
    return _formatPortPath(portName);
  }

  String get portLabel {
    final parts = portName.split('/');
    if (parts.length >= 2) {
      final bus = parts[parts.length - 2];
      final dev = parts[parts.length - 1];
      return '포트 $bus-$dev';
    }
    return portName;
  }

  String get vidPidString {
    return 'VID: 0x${vid.toRadixString(16).toUpperCase().padLeft(4, '0')}, '
        'PID: 0x${pid.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }

  static String? _knownChipName(int vid, int pid) {
    switch (vid) {
      case 0x067B:
        return 'PL2303 USB Serial';
      case 0x10C4:
        return 'CP210x USB Serial';
      case 0x0403:
        return 'FTDI USB Serial';
      case 0x1A86:
        return 'CH340 USB Serial';
      case 0x04E2:
        return 'Exar USB Serial';
      case 0x2C7C:
        return 'Quectel USB Serial';
      default:
        return null;
    }
  }

  static String _formatPortPath(String path) {
    final parts = path.split('/');
    if (parts.length >= 2) {
      return 'USB ${parts[parts.length - 2]}-${parts.last}';
    }
    return path;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsbDeviceInfo &&
        other.vid == vid &&
        other.pid == pid &&
        other.portName == portName;
  }

  @override
  int get hashCode => Object.hash(vid, pid, portName);
}
