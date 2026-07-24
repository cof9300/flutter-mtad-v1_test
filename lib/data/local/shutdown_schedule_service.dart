import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ShutdownScheduleType { daily, weekly, specificDate }

class ShutdownSchedule {
  final bool enabled;
  final ShutdownScheduleType type;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final String? specificDate;

  const ShutdownSchedule({
    required this.enabled,
    required this.type,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.specificDate,
  });

  factory ShutdownSchedule.defaultValue() => const ShutdownSchedule(
        enabled: false,
        type: ShutdownScheduleType.daily,
        hour: 23,
        minute: 0,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'type': type.name,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays,
        'specificDate': specificDate,
      };

  factory ShutdownSchedule.fromJson(Map<String, dynamic> json) => ShutdownSchedule(
        enabled: json['enabled'] as bool? ?? false,
        type: ShutdownScheduleType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ShutdownScheduleType.daily,
        ),
        hour: json['hour'] as int? ?? 23,
        minute: json['minute'] as int? ?? 0,
        weekdays: (json['weekdays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        specificDate: json['specificDate'] as String?,
      );

  ShutdownSchedule copyWith({
    bool? enabled,
    ShutdownScheduleType? type,
    int? hour,
    int? minute,
    List<int>? weekdays,
    String? specificDate,
  }) =>
      ShutdownSchedule(
        enabled: enabled ?? this.enabled,
        type: type ?? this.type,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekdays: weekdays ?? this.weekdays,
        specificDate: specificDate ?? this.specificDate,
      );
}

class ShutdownScheduleService {
  static const String _key = 'shutdown_schedule';

  final SharedPreferences _prefs;

  ShutdownScheduleService(this._prefs);

  ShutdownSchedule getSchedule() {
    final raw = _prefs.getString(_key);
    if (raw == null) return ShutdownSchedule.defaultValue();
    try {
      return ShutdownSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return ShutdownSchedule.defaultValue();
    }
  }

  Future<void> saveSchedule(ShutdownSchedule schedule) async {
    await _prefs.setString(_key, jsonEncode(schedule.toJson()));
  }
}
