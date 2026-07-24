class UpdateResultUserRequest {
  final String token;
  final String measureid;
  final String userid;
  final String type;
  final String? birth;
  final String? gender;

  const UpdateResultUserRequest({
    required this.token,
    required this.measureid,
    required this.userid,
    required this.type,
    this.birth,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'token': token,
      'measureid': measureid,
      'userid': userid,
      'type': type,
    };
    if (birth != null) {
      map['birth'] = birth;
    }
    if (gender != null) {
      map['gender'] = gender;
    }
    return map;
  }
}




