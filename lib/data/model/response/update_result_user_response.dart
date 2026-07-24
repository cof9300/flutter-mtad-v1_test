class UpdateResultUserResponse {
  final int resultCode;
  final String resultData;

  UpdateResultUserResponse({
    required this.resultCode,
    required this.resultData,
  });

  factory UpdateResultUserResponse.fromJson(Map<String, dynamic> json) {
    return UpdateResultUserResponse(
      resultCode: json['resultCode'] as int,
      resultData: json['resultData'] as String,
    );
  }
}




