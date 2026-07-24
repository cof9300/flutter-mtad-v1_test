import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class AlcoResultPassContent extends StatelessWidget {
  final AlcoMeasurementResult result;

  const AlcoResultPassContent({super.key, required this.result});

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
    const passColor = Color(0xFF1B933B);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: _getResponsiveSize(context, 120),
          color: passColor,
        ),
        SizedBox(height: _getResponsiveSize(context, 24)),
        Text(
          'PASS',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 90),
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: passColor,
            letterSpacing: -2.25,
            height: 1.0,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Text(
          result.bacValueText,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 100),
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: passColor,
            letterSpacing: -2.5,
            height: 1.0,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 32)),
        Text(
          l10n.alcoResultPass,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 72),
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: const Color(0xFF111111),
            letterSpacing: -1.8,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Text(
          l10n.alcoResultPassSub,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 32),
            fontVariations: const <FontVariation>[FontVariation('wght', 500)],
            color: const Color(0xFF595757),
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}
