class Device {
  final String type;
  final String name;
  final bool isConnected;

  const Device({
    required this.type,
    required this.name,
    this.isConnected = false,
  });

  String get imagePath {
    final imageType = _resolveImageType(type);
    if (!isConnected) {
      return 'assets/images/devices/${imageType}_off.png';
    }
    return 'assets/images/devices/$imageType.png';
  }

  static String _resolveImageType(String type) {
    switch (type.toUpperCase()) {
      case 'MF':
        return 'form';
      case 'ST':
        // 자율신경계(접촉) 전용 아이콘 자산이 없어 기존 HRV 아이콘을 공용으로 사용한다.
        return 'hrv';
      default:
        return type.toLowerCase();
    }
  }

  factory Device.fromResponse(String type, String name) {
    return Device(
      type: type,
      name: name,
    );
  }

  Device copyWith({
    String? type,
    String? name,
    bool? isConnected,
  }) {
    return Device(
      type: type ?? this.type,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

