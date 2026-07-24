import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class GenderSelectionWidget extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;
  final double? fontSize;
  final double? buttonHeight;
  final double? spacing;

  const GenderSelectionWidget({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
    this.fontSize,
    this.buttonHeight,
    this.spacing,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayFontSize = fontSize ?? _getResponsiveSize(context, 40);
    final displayButtonHeight =
        buttonHeight ?? _getResponsiveSize(context, 100);
    final displaySpacing = spacing ?? _getResponsiveSize(context, 20);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: _buildGenderButton(
            context,
            'M',
            l10n.male,
            selectedGender == 'M',
            displayFontSize,
            displayButtonHeight,
            () => onGenderSelected('M'),
          ),
        ),
        SizedBox(width: displaySpacing),
        Expanded(
          child: _buildGenderButton(
            context,
            'F',
            l10n.female,
            selectedGender == 'F',
            displayFontSize,
            displayButtonHeight,
            () => onGenderSelected('F'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderButton(
    BuildContext context,
    String value,
    String label,
    bool isSelected,
    double fontSize,
    double height,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF227EFE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF227EFE) : Color(0xFFCCCCCC),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: Offset(4, 4),
              blurRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.titleFontFamily,
              fontSize: fontSize,
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
              color: isSelected ? Colors.white : Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }
}
