class SetResultRequest {
  final String token;
  final String measureid;
  final String device;
  final Map<String, dynamic> result;
  final String serviceforce;

  SetResultRequest({
    required this.token,
    required this.measureid,
    required this.device,
    required this.result,
    this.serviceforce = 'false',
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'measureid': measureid,
      'device': device,
      'result': result,
      'serviceforce': serviceforce,
    };
  }
}














