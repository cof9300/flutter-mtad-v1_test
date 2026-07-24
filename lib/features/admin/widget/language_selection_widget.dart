import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';

class LanguageSelectionWidget extends ConsumerWidget {
  const LanguageSelectionWidget({super.key});

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final labelFontSize = _getResponsiveSize(context, 32);
    final dropdownFontSize = _getResponsiveSize(context, 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '언어 설정',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: labelFontSize,
            fontVariations: <FontVariation>[
              FontVariation('wght', 700),
            ],
            color: Color(0xFF111111),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 20)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(context, 24),
            vertical: _getResponsiveSize(context, 4),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(_getResponsiveSize(context, 12)),
            border: Border.all(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: currentLocale,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                size: _getResponsiveSize(context, 32),
                color: Color(0xFF111111),
              ),
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: dropdownFontSize,
                fontVariations: <FontVariation>[
                  FontVariation('wght', 500),
                ],
                color: Color(0xFF111111),
              ),
              items: _buildLanguageItems(context),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  ref
                      .read(localeProvider.notifier)
                      .changeDefaultLocale(newLocale);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<Locale>> _buildLanguageItems(BuildContext context) {
    return [
      DropdownMenuItem<Locale>(
        value: const Locale('ko'),
        child: Text('한국어'),
      ),
      DropdownMenuItem<Locale>(
        value: const Locale('en'),
        child: Text('English'),
      ),
      DropdownMenuItem<Locale>(
        value: const Locale('zh'),
        child: const Text('中文'),
      ),
      DropdownMenuItem<Locale>(
        value: const Locale('vi'),
        child: const Text('Tiếng Việt'),
      ),
    ];
  }
}
