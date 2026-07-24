class DevicePageOptionRequest {
  final String token;
  final String device;

  DevicePageOptionRequest({
    required this.token,
    required this.device,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'device': device,
    };
  }
}















