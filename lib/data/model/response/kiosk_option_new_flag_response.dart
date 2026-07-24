class KioskOptionNewFlagResponse {
  final int resultCode;
  final KioskOptionNewFlagData resultData;

  KioskOptionNewFlagResponse({
    required this.resultCode,
    required this.resultData,
  });

  factory KioskOptionNewFlagResponse.fromJson(Map<String, dynamic> json) {
    final resultData = json['resultData'] as Map<String, dynamic>;
    return KioskOptionNewFlagResponse(
      resultCode: json['resultCode'] as int,
      resultData: KioskOptionNewFlagData.fromJson(resultData),
    );
  }
}

class KioskOptionNewFlagData {
  final bool kioskupdate;
  final bool siteupdate;

  KioskOptionNewFlagData({
    required this.kioskupdate,
    required this.siteupdate,
  });

  factory KioskOptionNewFlagData.fromJson(Map<String, dynamic> json) {
    return KioskOptionNewFlagData(
      kioskupdate: json['kioskupdate'] as bool? ?? false,
      siteupdate: json['siteupdate'] as bool? ?? false,
    );
  }
}
