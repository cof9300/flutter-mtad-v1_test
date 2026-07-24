import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/data/local/shutdown_schedule_service.dart';

class ShutdownScheduleScreen extends StatefulWidget {
  const ShutdownScheduleScreen({super.key});

  @override
  State<ShutdownScheduleScreen> createState() => _ShutdownScheduleScreenState();
}

class _ShutdownScheduleScreenState extends State<ShutdownScheduleScreen> {
  static const _shutdownChannel = MethodChannel('shutdown_channel');

  late ShutdownSchedule _schedule;
  bool _saving = false;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _schedule = ServiceLocator().shutdownScheduleService.getSchedule();
  }

  double _rs(double v) {
    final w = WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;
    return (w / 1080 * v).clamp(v * 0.5, v * 1.5);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _schedule.hour, minute: _schedule.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _schedule = _schedule.copyWith(hour: picked.hour, minute: picked.minute);
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _schedule.specificDate != null
        ? DateTime.tryParse(_schedule.specificDate!) ?? now
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _schedule = _schedule.copyWith(specificDate: dateStr);
      });
    }
  }

  Future<void> _save() async {
    if (_schedule.type == ShutdownScheduleType.weekly && _schedule.weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요일을 하나 이상 선택해주세요.')),
      );
      return;
    }
    if (_schedule.type == ShutdownScheduleType.specificDate &&
        (_schedule.specificDate == null || _schedule.specificDate!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 선택해주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    await ServiceLocator().shutdownScheduleService.saveSchedule(_schedule);

    try {
      if (_schedule.enabled) {
        final payload = jsonEncode(_schedule.toJson());
        await _shutdownChannel.invokeMethod('scheduleShutdown', payload);
        FlutterErrorLogger.system(
          '[시스템] 자동 종료 스케줄 설정: ${_scheduleDescription()}',
          errorCode: 'SYS-017',
          severity: 'INFO',
        );
      } else {
        await _shutdownChannel.invokeMethod('cancelShutdown');
        FlutterErrorLogger.system(
          '[시스템] 자동 종료 스케줄 취소',
          errorCode: 'SYS-018',
          severity: 'INFO',
        );
      }
    } catch (_) {}

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장됐습니다.')),
      );
    }
  }

  String _scheduleDescription() {
    final time =
        '${_schedule.hour.toString().padLeft(2, '0')}:${_schedule.minute.toString().padLeft(2, '0')}';
    switch (_schedule.type) {
      case ShutdownScheduleType.daily:
        return '매일 $time';
      case ShutdownScheduleType.weekly:
        final days = _schedule.weekdays.map((d) => _weekdayLabels[d - 1]).join(', ');
        return '요일별($days) $time';
      case ShutdownScheduleType.specificDate:
        return '${_schedule.specificDate ?? ''} $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardRadius = _rs(16);
    final hPad = _rs(80);
    final cardFont = _rs(32);
    final labelFont = _rs(28);

    return CommonLayout(
      disableClockAdminEntry: true,
      child: Container(
        decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: _rs(20), top: _rs(20)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: _rs(60),
                    height: _rs(60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_rs(8)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/keypad-back.svg',
                        width: _rs(64),
                        height: _rs(64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _rs(40)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '종료 관리',
                  style: TextStyle(
                    fontFamily: AppTextStyles.titleFontFamily,
                    fontSize: _rs(48),
                    fontVariations: const [FontVariation('wght', 900)],
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
            ),
            SizedBox(height: _rs(48)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _card(
                      cardRadius,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('자동 종료 사용', style: _boldStyle(cardFont)),
                          Transform.scale(
                            scale: _rs(1.6) / 1.6,
                            child: Switch(
                              value: _schedule.enabled,
                              onChanged: (v) =>
                                  setState(() => _schedule = _schedule.copyWith(enabled: v)),
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF227EFF),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFCCCCCC),
                              trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_schedule.enabled) ...[
                      SizedBox(height: _rs(24)),

                      _card(
                        cardRadius,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('반복 유형', style: _boldStyle(cardFont)),
                            SizedBox(height: _rs(16)),
                            _typeOption(ShutdownScheduleType.daily, '매일', labelFont),
                            _typeOption(ShutdownScheduleType.weekly, '요일별', labelFont),
                            _typeOption(ShutdownScheduleType.specificDate, '특정 날짜', labelFont),
                          ],
                        ),
                      ),
                      SizedBox(height: _rs(24)),

                      if (_schedule.type == ShutdownScheduleType.weekly)
                        _card(
                          cardRadius,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('요일 선택', style: _boldStyle(cardFont)),
                              SizedBox(height: _rs(20)),
                              Wrap(
                                spacing: _rs(12),
                                children: List.generate(7, (i) {
                                  final day = i + 1;
                                  final selected = _schedule.weekdays.contains(day);
                                  return GestureDetector(
                                    onTap: () {
                                      final days = List<int>.from(_schedule.weekdays);
                                      if (selected) {
                                        days.remove(day);
                                      } else {
                                        days.add(day);
                                        days.sort();
                                      }
                                      setState(() => _schedule = _schedule.copyWith(weekdays: days));
                                    },
                                    child: Container(
                                      width: _rs(80),
                                      height: _rs(80),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFF227EFF)
                                            : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(_rs(12)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _weekdayLabels[i],
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.bodyFontFamily,
                                            fontSize: _rs(28),
                                            fontVariations: const [FontVariation('wght', 700)],
                                            color: selected ? Colors.white : const Color(0xFF555555),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                      if (_schedule.type == ShutdownScheduleType.specificDate)
                        _card(
                          cardRadius,
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('날짜 선택', style: _boldStyle(cardFont)),
                                Text(
                                  _schedule.specificDate ?? '날짜를 선택하세요',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: _rs(30),
                                    fontVariations: const [FontVariation('wght', 500)],
                                    color: _schedule.specificDate != null
                                        ? const Color(0xFF227EFF)
                                        : const Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_schedule.type == ShutdownScheduleType.specificDate)
                        SizedBox(height: _rs(24)),

                      _card(
                        cardRadius,
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('종료 시간', style: _boldStyle(cardFont)),
                              Text(
                                '${_schedule.hour.toString().padLeft(2, '0')}:${_schedule.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: _rs(36),
                                  fontVariations: const [FontVariation('wght', 700)],
                                  color: const Color(0xFF227EFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: _rs(40)),

                    SizedBox(
                      width: double.infinity,
                      height: _rs(100),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF227EFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_rs(16)),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                '저장',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: _rs(36),
                                  fontVariations: const [FontVariation('wght', 700)],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: _rs(20)),
                    Text(
                      '※ 자동종료 기능은 운영체제 보안 정책에 따라 메디터치 태블릿에서는 사용할 수 없으며, 메디터치 키오스크에서만 지원됩니다.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: _rs(22),
                        color: const Color(0xFF999999),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: _rs(40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(double radius, {required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(_rs(32)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: child,
      );

  Widget _typeOption(ShutdownScheduleType type, String label, double fontSize) =>
      GestureDetector(
        onTap: () => setState(() => _schedule = _schedule.copyWith(type: type)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _rs(8)),
          child: Row(
            children: [
              Container(
                width: _rs(32),
                height: _rs(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _schedule.type == type
                        ? const Color(0xFF227EFF)
                        : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                ),
                child: _schedule.type == type
                    ? Center(
                        child: Container(
                          width: _rs(16),
                          height: _rs(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF227EFF),
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: _rs(16)),
              Text(label, style: _normalStyle(fontSize)),
            ],
          ),
        ),
      );

  TextStyle _boldStyle(double size) => TextStyle(
        fontFamily: AppTextStyles.bodyFontFamily,
        fontSize: size,
        fontVariations: const [FontVariation('wght', 600)],
        color: const Color(0xFF111111),
      );

  TextStyle _normalStyle(double size) => TextStyle(
        fontFamily: AppTextStyles.bodyFontFamily,
        fontSize: size,
        fontVariations: const [FontVariation('wght', 400)],
        color: const Color(0xFF333333),
      );
}
