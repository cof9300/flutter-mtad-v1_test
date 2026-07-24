class SendSmsRequest {
  final String token;
  final String type;
  final String? measureid;
  final String? phonenumber;
  final String? certnumber;
  final String? result;
  final String? date;
  final String? place;

  const SendSmsRequest({
    required this.token,
    required this.type,
    this.measureid,
    this.phonenumber,
    this.certnumber,
    this.result,
    this.date,
    this.place,
  });

  factory SendSmsRequest.fromJson(Map<String, dynamic> json) => SendSmsRequest(
        token: json['token'] as String,
        type: json['type'] as String,
        measureid: json['measureid'] as String?,
        phonenumber: json['phonenumber'] as String?,
        certnumber: json['certnumber'] as String?,
        result: json['result'] as String?,
        date: json['date'] as String?,
        place: json['place'] as String?,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'token': token,
      'type': type,
    };
    if (measureid != null) {
      map['measureid'] = measureid;
    }
    if (phonenumber != null) {
      map['phonenumber'] = phonenumber;
    }
    if (certnumber != null) {
      map['certnumber'] = certnumber;
    }
    if (result != null) {
      map['result'] = result;
    }
    if (date != null) {
      map['date'] = date;
    }
    final place_ = place;
    if (place_ != null && place_.isNotEmpty) {
      map['place'] = place_;
    }
    return map;
  }
}
