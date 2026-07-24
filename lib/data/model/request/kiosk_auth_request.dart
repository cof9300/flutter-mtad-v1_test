class KioskAuthRequest {
  final String kioskid;

  const KioskAuthRequest({
    required this.kioskid,
  });

  factory KioskAuthRequest.fromJson(Map<String, dynamic> json) =>
      KioskAuthRequest(
        kioskid: json['kioskid'] as String,
      );

  Map<String, dynamic> toJson() => {
        'kioskid': kioskid,
      };
}
