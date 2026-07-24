class SendMediformRequest {
  final String token;
  final String measureid;

  const SendMediformRequest({
    required this.token,
    required this.measureid,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'measureid': measureid,
      };
}
