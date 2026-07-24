class KioskOptionResponse {
  final String kioskid;
  final bool masking;
  final String nextstep;
  final int waittime;
  final String step;
  final String place;
  final String company;
  final int mode;
  final int usecert;
  final int resulttime;
  final int screentime;
  final int certtime;
  final int sms;
  final int demo;
  final int facedetect;
  final int voiceinfo;
  final int resultprint;

  const KioskOptionResponse({
    required this.kioskid,
    required this.masking,
    required this.nextstep,
    required this.waittime,
    required this.step,
    required this.place,
    required this.company,
    required this.mode,
    required this.usecert,
    required this.resulttime,
    required this.screentime,
    required this.certtime,
    required this.sms,
    required this.demo,
    required this.facedetect,
    required this.voiceinfo,
    required this.resultprint,
  });

  factory KioskOptionResponse.fromJson(Map<String, dynamic> json) =>
      KioskOptionResponse(
        kioskid: json['kioskid'] as String,
        masking: json['masking'] as bool,
        nextstep: json['nextstep'] as String,
        waittime: json['waittime'] as int,
        step: json['step'] as String,
        place: json['place'] as String,
        company: json['company'] as String,
        mode: json['mode'] as int,
        usecert: json['usecert'] as int,
        resulttime: json['resulttime'] as int,
        screentime: json['screentime'] as int,
        certtime: json['certtime'] as int,
        sms: json['sms'] as int,
        demo: json['demo'] as int,
        facedetect: json['facedetect'] as int,
        voiceinfo: json['voiceinfo'] as int,
        resultprint: json['resultprint'] as int,
      );

  Map<String, dynamic> toJson() => {
        'kioskid': kioskid,
        'masking': masking,
        'nextstep': nextstep,
        'waittime': waittime,
        'step': step,
        'place': place,
        'company': company,
        'mode': mode,
        'usecert': usecert,
        'resulttime': resulttime,
        'screentime': screentime,
        'certtime': certtime,
        'sms': sms,
        'demo': demo,
        'facedetect': facedetect,
        'voiceinfo': voiceinfo,
        'resultprint': resultprint,
      };
}

