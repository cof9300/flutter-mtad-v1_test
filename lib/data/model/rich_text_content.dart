class RichTextContent {
  final int? id;
  final String key;
  final String koText;
  final String enText;
  final String zhText;
  final String viText;
  final DateTime updatedAt;

  RichTextContent({
    this.id,
    required this.key,
    required this.koText,
    required this.enText,
    required this.zhText,
    required this.viText,
    required this.updatedAt,
  });

  factory RichTextContent.fromMap(Map<String, dynamic> map) {
    return RichTextContent(
      id: map['id'] as int?,
      key: map['key'] as String,
      koText: map['ko_text'] as String? ?? '',
      enText: map['en_text'] as String? ?? '',
      zhText: map['zh_text'] as String? ?? '',
      viText: map['vi_text'] as String? ?? '',
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'ko_text': koText,
      'en_text': enText,
      'zh_text': zhText,
      'vi_text': viText,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RichTextContent copyWith({
    int? id,
    String? key,
    String? koText,
    String? enText,
    String? zhText,
    String? viText,
    DateTime? updatedAt,
  }) {
    return RichTextContent(
      id: id ?? this.id,
      key: key ?? this.key,
      koText: koText ?? this.koText,
      enText: enText ?? this.enText,
      zhText: zhText ?? this.zhText,
      viText: viText ?? this.viText,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}















