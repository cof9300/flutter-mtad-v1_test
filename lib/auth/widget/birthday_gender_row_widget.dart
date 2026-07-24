import 'package:flutter/material.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/gender_selection_widget.dart';
import 'package:flutter_template/core/utils/birthday_validator.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class BirthdayGenderRowWidget extends StatelessWidget {
  final String birthdayInputValue;
  final String? selectedGender;
  final Function(InputMode) onInputFieldTapped;
  final Function(String) onGenderSelected;
  final double? inputHeight;
  final double? inputFontSize;
  final double? spacing;
  final InputMode currentInputMode;

  const BirthdayGenderRowWidget({
    super.key,
    required this.birthdayInputValue,
    required this.selectedGender,
    required this.onInputFieldTapped,
    required this.onGenderSelected,
    this.inputHeight,
    this.inputFontSize,
    this.spacing,
    required this.currentInputMode,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  String _formatBirthday(String value) {
    if (value.isEmpty) return '';
    return BirthdayValidator.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayInputHeight = inputHeight ?? _getResponsiveSize(context, 125);
    final displayInputFontSize = inputFontSize ?? 46.0;
    final displaySpacing = spacing ?? _getResponsiveSize(context, 60);
    final titleFontSize = _getResponsiveSize(context, 34);
    final titleBottomSpacing = _getResponsiveSize(context, 6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.birthday,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: titleFontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: titleBottomSpacing),
              AuthInputField(
                hint: '1998.12.06',
                value: _formatBirthday(birthdayInputValue),
                onTap: () => onInputFieldTapped(InputMode.birthday),
                fontSize: displayInputFontSize,
                height: displayInputHeight,
                isFocused: currentInputMode == InputMode.birthday,
                shadowStyle: ShadowStyle.bottomRight,
              ),
            ],
          ),
        ),
        SizedBox(width: displaySpacing),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.gender,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: titleFontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: titleBottomSpacing),
              GenderSelectionWidget(
                selectedGender: selectedGender,
                onGenderSelected: onGenderSelected,
                fontSize: displayInputFontSize * 0.7,
                buttonHeight: displayInputHeight,
                spacing: displaySpacing * 0.5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
