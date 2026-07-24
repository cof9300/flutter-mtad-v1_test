class SetKioskOptionUseFlagResponse {
  final int resultCode;
  final String resultData;

  SetKioskOptionUseFlagResponse({
    required this.resultCode,
    required this.resultData,
  });

  factory SetKioskOptionUseFlagResponse.fromJson(Map<String, dynamic> json) {
    return SetKioskOptionUseFlagResponse(
      resultCode: json['resultCode'] as int,
      resultData: json['resultData'] as String? ?? '',
    );
  }
}
