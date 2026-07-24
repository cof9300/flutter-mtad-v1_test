class SetKioskOptionUseFlagRequest {
  final String token;
  final String type;

  SetKioskOptionUseFlagRequest({
    required this.token,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
    };
  }
}
