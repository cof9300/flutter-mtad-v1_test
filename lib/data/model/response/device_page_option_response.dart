class MediaItem {
  final String path;
  final int playtime;
  final int sound;

  MediaItem({
    required this.path,
    required this.playtime,
    required this.sound,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      path: json['path'] as String,
      playtime: int.tryParse(json['playtime'].toString()) ?? 0,
      sound: int.tryParse(json['sound'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'playtime': playtime,
      'sound': sound,
    };
  }
}

class DevicePageOptionResponse {
  final List<MediaItem> menual;
  final List<MediaItem> cm;
  final int waittime;

  DevicePageOptionResponse({
    required this.menual,
    required this.cm,
    required this.waittime,
  });

  factory DevicePageOptionResponse.fromJson(Map<String, dynamic> json) {
    final resultData = json['resultData'] as Map<String, dynamic>;

    return DevicePageOptionResponse(
      menual: (resultData['menual'] as List<dynamic>)
          .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      cm: (resultData['cm'] as List<dynamic>)
          .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      waittime: resultData['waittime'] as int,
    );
  }
}
