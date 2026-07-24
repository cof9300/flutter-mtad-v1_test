class WaitPageOptionResponse {
  final String title;
  final String logo;
  final String printerlogo;
  final List<WaitPageContent> cm;

  const WaitPageOptionResponse({
    required this.title,
    required this.logo,
    required this.printerlogo,
    required this.cm,
  });

  factory WaitPageOptionResponse.fromJson(Map<String, dynamic> json) {
    final cmList = json['cm'] as List<dynamic>? ?? [];
    return WaitPageOptionResponse(
      title: json['title'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      printerlogo: json['printerlogo'] as String? ?? '',
      cm: cmList.map((item) => WaitPageContent.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'logo': logo,
        'printerlogo': printerlogo,
        'cm': cm.map((item) => item.toJson()).toList(),
      };
}

class WaitPageContent {
  final String path;
  final int playtime;
  final int sound;

  const WaitPageContent({
    required this.path,
    required this.playtime,
    required this.sound,
  });

  factory WaitPageContent.fromJson(Map<String, dynamic> json) {
    int parsePlaytime(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    int parseSound(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return WaitPageContent(
      path: json['path'] as String? ?? '',
      playtime: parsePlaytime(json['playtime']),
      sound: parseSound(json['sound']),
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'playtime': playtime,
        'sound': sound,
      };
}

