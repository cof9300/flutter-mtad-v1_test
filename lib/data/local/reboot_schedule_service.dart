import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum RebootScheduleType { daily, weekly, specificDate }

class RebootSchedule {
  final bool enabled;
  final RebootScheduleType type;
  final int hour;
  final int minute;
  final List<int> weekdays; // 1=월 ~ 7=일
  final String? specificDate; // 'yyyy-MM-dd'

  const RebootSchedule({
    required this.enabled,
    required this.type,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.specificDate,
  });

  factory RebootSchedule.defaultValue() => const RebootSchedule(
        enabled: false,
        type: RebootScheduleType.daily,
        hour: 3,
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

  factory RebootSchedule.fromJson(Map<String, dynamic> json) => RebootSchedule(
        enabled: json['enabled'] as bool? ?? false,
        type: RebootScheduleType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RebootScheduleType.daily,
        ),
        hour: json['hour'] as int? ?? 3,
        minute: json['minute'] as int? ?? 0,
        weekdays: (json['weekdays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        specificDate: json['specificDate'] as String?,
      );

  RebootSchedule copyWith({
    bool? enabled,
    RebootScheduleType? type,
    int? hour,
    int? minute,
    List<int>? weekdays,
    String? specificDate,
  }) =>
      RebootSchedule(
        enabled: enabled ?? this.enabled,
        type: type ?? this.type,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekdays: weekdays ?? this.weekdays,
        specificDate: specificDate ?? this.specificDate,
      );
}

class RebootScheduleService {
  static const String _key = 'reboot_schedule';

  final SharedPreferences _prefs;

  RebootScheduleService(this._prefs);

  RebootSchedule getSchedule() {
    final raw = _prefs.getString(_key);
    if (raw == null) return RebootSchedule.defaultValue();
    try {
      return RebootSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return RebootSchedule.defaultValue();
    }
  }

  Future<void> saveSchedule(RebootSchedule schedule) async {
    await _prefs.setString(_key, jsonEncode(schedule.toJson()));
  }
}
