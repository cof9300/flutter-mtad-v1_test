class SetResultResponse {
  final int resultCode;
  final String? measureid;

  SetResultResponse({
    required this.resultCode,
    this.measureid,
  });

  factory SetResultResponse.fromJson(Map<String, dynamic> json) {
    final resultData = json['resultData'] as Map<String, dynamic>?;
    
    return SetResultResponse(
      resultCode: json['resultCode'] as int,
      measureid: resultData?['measureid'] as String?,
    );
  }
}














