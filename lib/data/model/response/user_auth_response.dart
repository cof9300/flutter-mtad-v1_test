class UserAuthResponse {
  final String? measureid;
  final String? username;
  final String nextstep;
  final String? status;
  final String? gender;
  final String? birthday;
  final String? phonenumber;

  const UserAuthResponse({
    this.measureid,
    this.username,
    required this.nextstep,
    this.status,
    this.gender,
    this.birthday,
    this.phonenumber,
  });

  factory UserAuthResponse.fromJson(Map<String, dynamic> json) =>
      UserAuthResponse(
        measureid: json['measureid'] as String?,
        username: json['username'] as String?,
        nextstep: json['nextstep'] as String? ?? '',
        status: json['status']?.toString(),
        gender: json['gender'] as String?,
        birthday: json['birthday'] as String?,
        phonenumber: json['phonenumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'measureid': measureid,
        'username': username,
        'nextstep': nextstep,
        'status': status,
        'gender': gender,
        'birthday': birthday,
        'phonenumber': phonenumber,
      };
}

