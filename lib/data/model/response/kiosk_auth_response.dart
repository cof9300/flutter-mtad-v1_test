class KioskAuthResponse {
  final String token;

  const KioskAuthResponse({
    required this.token,
  });

  factory KioskAuthResponse.fromJson(Map<String, dynamic> json) =>
      KioskAuthResponse(
        token: json['token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
      };
}

