class UserAuthRequest {
  final String userid;
  final String type;
  final String token;
  final String? serviceforce;
  final String? birthday;
  final String? gender;

  const UserAuthRequest({
    required this.userid,
    required this.type,
    required this.token,
    this.serviceforce,
    this.birthday,
    this.gender,
  });

  factory UserAuthRequest.fromJson(Map<String, dynamic> json) =>
      UserAuthRequest(
        userid: json['userid'] as String,
        type: json['type'] as String,
        token: json['token'] as String,
        serviceforce: json['serviceforce'] as String?,
        birthday: json['birthday'] as String?,
        gender: json['gender'] as String?,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userid': userid,
      'type': type,
      'token': token,
    };
    if (serviceforce != null) {
      map['serviceforce'] = serviceforce;
    }
    if (birthday != null) {
      map['birthday'] = birthday;
    }
    if (gender != null) {
      map['gender'] = gender;
    }
    return map;
  }
}
