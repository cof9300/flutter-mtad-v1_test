import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class AlcoResultFailContent extends StatelessWidget {
  final AlcoMeasurementResult result;

  const AlcoResultFailContent({super.key, required this.result});

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize).clamp(
      baseSize * 0.5,
      baseSize * 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    const failColor = Color(0xFFD81F1E);
    final l10n = AppLocalizations.of(context)!;

    final descriptionText = result.isSuccess
        ? l10n.alcoResultFailGuide
        : result.errorMessage;

    final subText = result.isSuccess ? l10n.alcoResultFailSub : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_rounded,
          size: _getResponsiveSize(context, 120),
          color: failColor,
        ),
        SizedBox(height: _getResponsiveSize(context, 24)),
        Text(
          'FAIL',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 90),
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: failColor,
            letterSpacing: -2.25,
            height: 1.0,
          ),
        ),
        if (result.isSuccess) ...[
          SizedBox(height: _getResponsiveSize(context, 16)),
          Text(
            result.bacValueText,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 100),
              fontVariations: const <FontVariation>[FontVariation('wght', 700)],
              color: failColor,
              letterSpacing: -2.5,
              height: 1.0,
            ),
          ),
        ],
        SizedBox(height: _getResponsiveSize(context, 32)),
        Text(
          descriptionText,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 72),
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: const Color(0xFF111111),
            letterSpacing: -1.8,
          ),
        ),
        if (subText.isNotEmpty) ...[
          SizedBox(height: _getResponsiveSize(context, 16)),
          Text(
            subText,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 32),
              fontVariations: const <FontVariation>[FontVariation('wght', 500)],
              color: const Color(0xFF595757),
              letterSpacing: -0.8,
            ),
          ),
        ],
      ],
    );
  }
}
