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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double iconSize = isMobile ? 50.0 : _getResponsiveSize(context, 120);
    final double titleFontSize = isMobile ? 30.0 : _getResponsiveSize(context, 90);
    final double valueFontSize = isMobile ? 33.0 : _getResponsiveSize(context, 100);
    final double descFontSize = isMobile ? 22.0 : _getResponsiveSize(context, 72);
    final double subFontSize = isMobile ? 11.0 : _getResponsiveSize(context, 32);

    final double gap1 = isMobile ? 12.0 : _getResponsiveSize(context, 24);
    final double gap2 = isMobile ? 8.0 : _getResponsiveSize(context, 16);
    final double gap3 = isMobile ? 16.0 : _getResponsiveSize(context, 32);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMobile) const SizedBox(height: 40.0),
        Icon(
          Icons.check_circle,
          size: iconSize,
          color: passColor,
        ),
        SizedBox(height: gap1),
        Text(
          'PASS',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: titleFontSize,
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: passColor,
            letterSpacing: isMobile ? -0.75 : -2.25,
            height: 1.0,
          ),
        ),
        SizedBox(height: gap2),
        Text(
          result.bacValueText,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: valueFontSize,
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: passColor,
            letterSpacing: isMobile ? -0.8 : -2.5,
            height: 1.0,
          ),
        ),
        SizedBox(height: gap3),
        Text(
          l10n.alcoResultPass,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: descFontSize,
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: const Color(0xFF111111),
            letterSpacing: isMobile ? -0.5 : -1.8,
          ),
        ),
        SizedBox(height: gap2),
        Text(
          l10n.alcoResultPassSub,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: subFontSize,
            fontVariations: const <FontVariation>[FontVariation('wght', 500)],
            color: const Color(0xFF595757),
            letterSpacing: isMobile ? -0.3 : -0.8,
          ),
        ),
      ],
    );
  }
}
