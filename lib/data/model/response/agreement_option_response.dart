class AgreementOptionResponse {
  final String agreeimage1;
  final String agreeimage2;
  final String agreeimage3;
  final String agreeimage4;

  AgreementOptionResponse({
    required this.agreeimage1,
    required this.agreeimage2,
    required this.agreeimage3,
    required this.agreeimage4,
  });

  factory AgreementOptionResponse.fromJson(Map<String, dynamic> json) {
    final resultData = json['resultData'] as Map<String, dynamic>;

    return AgreementOptionResponse(
      agreeimage1: resultData['agreeimage1'] as String? ?? '',
      agreeimage2: resultData['agreeimage2'] as String? ?? '',
      agreeimage3: resultData['agreeimage3'] as String? ?? '',
      agreeimage4: resultData['agreeimage4'] as String? ?? '',
    );
  }
}
