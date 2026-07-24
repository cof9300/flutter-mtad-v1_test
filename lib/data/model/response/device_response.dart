class DeviceResponse {
  final String type;
  final String name;
  final int? port;

  DeviceResponse({
    required this.type,
    required this.name,
    this.port,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    final portValue = json['port'];
    int? parsedPort;
    if (portValue != null) {
      if (portValue is int) {
        parsedPort = portValue;
      } else if (portValue is String) {
        parsedPort = int.tryParse(portValue);
      }
    }

    return DeviceResponse(
      type: json['type'] as String,
      name: (json['product'] ?? json['name'] ?? '') as String,
      port: parsedPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'port': port,
    };
  }
}

class DeviceListResponse {
  final List<DeviceResponse> devices;

  DeviceListResponse({
    required this.devices,
  });

  factory DeviceListResponse.fromJson(List<dynamic> json) {
    return DeviceListResponse(
      devices: json.map((item) => DeviceResponse.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

