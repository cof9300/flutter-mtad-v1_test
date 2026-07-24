import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class BirthdayDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;

  const BirthdayDatePickerDialog({
    super.key,
    this.initialDate,
  });

  static Future<DateTime?> show(BuildContext context, {DateTime? initialDate}) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BirthdayDatePickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<BirthdayDatePickerDialog> createState() =>
      _BirthdayDatePickerDialogState();
}

class _BirthdayDatePickerDialogState extends State<BirthdayDatePickerDialog> {
  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = initial;
    _selectedYear = initial.year;
    _selectedMonth = initial.month;
    _selectedDay = initial.day;
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _updateDate() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
    }
    _selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      _updateDate();
    });
  }

  void _onMonthChanged(int month) {
    setState(() {
      _selectedMonth = month;
      _updateDate();
    });
  }

  void _onDayChanged(int day) {
    setState(() {
      _selectedDay = day;
      _updateDate();
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedDate);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getResponsiveSize(context, 100);
    final buttonFontSize = _getResponsiveSize(context, 40);
    final spacing = _getResponsiveSize(context, 20);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: _getResponsiveSize(context, 800),
        padding: EdgeInsets.all(_getResponsiveSize(context, 40)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '생년월일 선택',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 48),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDateSelector(
                  context,
                  '년',
                  _selectedYear,
                  1900,
                  2100,
                  _onYearChanged,
                ),
                _buildDateSelector(
                  context,
                  '월',
                  _selectedMonth,
                  1,
                  12,
                  _onMonthChanged,
                ),
                _buildDateSelector(
                  context,
                  '일',
                  _selectedDay,
                  1,
                  DateTime(_selectedYear, _selectedMonth + 1, 0).day,
                  _onDayChanged,
                ),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _onCancel,
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius:
                            BorderRadius.circular(_getResponsiveSize(context, 16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: buttonFontSize,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 600),
                          ],
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: GestureDetector(
                    onTap: _onConfirm,
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.headerBackground,
                        borderRadius:
                            BorderRadius.circular(_getResponsiveSize(context, 16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: buttonFontSize,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 600),
                          ],
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    final selectorWidth = label == '년'
        ? _getResponsiveSize(context, 200)
        : _getResponsiveSize(context, 140);
    final selectorHeight = _getResponsiveSize(context, 220);
    final fontSize = _getResponsiveSize(context, 48);
    final labelFontSize = _getResponsiveSize(context, 28);

    return Column(
      children: [
        Container(
          width: selectorWidth,
          height: selectorHeight,
          decoration: BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
            border: Border.all(color: Color(0xFFE0E0E0), width: 2),
          ),
          child: _buildScrollView(
            context,
            value,
            min,
            max,
            onChanged,
            fontSize,
            label,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 12)),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: labelFontSize,
            fontVariations: <FontVariation>[
              FontVariation('wght', 400),
            ],
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollView(
    BuildContext context,
    int selectedValue,
    int min,
    int max,
    Function(int) onChanged,
    double fontSize,
    String label,
  ) {
    final itemHeight = _getResponsiveSize(context, 60);
    final itemCount = max - min + 1;
    final initialIndex = selectedValue - min;

    return ListWheelScrollView.useDelegate(
      itemExtent: itemHeight,
      diameterRatio: 1.5,
      physics: FixedExtentScrollPhysics(),
      controller: FixedExtentScrollController(initialItem: initialIndex),
      onSelectedItemChanged: (index) {
        final value = min + index;
        if (value >= min && value <= max) {
          onChanged(value);
        }
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final value = min + index;
          final isSelected = value == selectedValue;
          final displayText = label == '월' || label == '일'
              ? '$value'
              : '$value';

          return Container(
            alignment: Alignment.center,
            child: Text(
              displayText,
              style: TextStyle(
                fontFamily: AppTextStyles.titleFontFamily,
                fontSize: isSelected ? fontSize : fontSize * 0.7,
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                color: isSelected ? Color(0xFF111111) : Color(0xFF999999),
              ),
            ),
          );
        },
      ),
    );
  }
}

