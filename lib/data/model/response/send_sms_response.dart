class SendSmsResponse {
  final int resultCode;
  final String? resultData;

  const SendSmsResponse({
    required this.resultCode,
    this.resultData,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) =>
      SendSmsResponse(
        resultCode: json['resultCode'] as int,
        resultData: json['resultData'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'resultCode': resultCode,
        if (resultData != null) 'resultData': resultData,
      };
}

