import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/rich_text_renderer.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/number_keypad.dart';
import 'package:flutter_template/providers/notifier/rich_text_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/core/utils/phone_formatter.dart';
import 'package:flutter_template/core/utils/phone_validator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class PortraitAuthLayout extends ConsumerWidget {
  final String inputValue;
  final String inputHint;
  final VoidCallback onConfirm;
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;

  const PortraitAuthLayout({
    super.key,
    required this.inputValue,
    required this.inputHint,
    required this.onConfirm,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    final isMobile = screenWidth < 600;
    final minScale = isMobile ? 0.3 : 0.5;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * minScale, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final titleHorizontalPadding = _getResponsiveSize(context, 40);
    final inputHorizontalPadding = _getResponsiveSize(context, 80);
    final spacing = _getResponsiveSize(context, 40);
    final largeSpacing = _getResponsiveSize(context, 60);
    final isMobile = screenWidth < 600;
    final buttonWidth = isMobile
        ? (screenWidth * 0.65).clamp(240.0, 320.0)
        : (screenWidth * 0.85).clamp(300.0, 550.0);
    final fontSize = isMobile
        ? _getResponsiveSize(context, 40)
        : _getResponsiveSize(context, 40);

    final locale = ref.watch(localeProvider);
    final richTextNotifier = ref.watch(richTextNotifierProvider.notifier);
    final authTitleText = richTextNotifier.getText(
      'auth_title',
      locale.languageCode,
      l10n.authTitle,
    );

    // 3줄 기준 고정 높이 계산 (fontSize * lineHeight * 3줄)
    final fixedTitleHeight = fontSize * 1.5 * 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: spacing),
                  // 상단 텍스트 영역을 고정 높이로 제한 (3줄 기준)
                  SizedBox(
                    height: fixedTitleHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: titleHorizontalPadding),
                      child: RichTextRenderer(
                        text: authTitleText,
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: fontSize,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 400),
                          ],
                          color: Color(0xFF595757),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  // 하단 영역을 Expanded로 감싸서 남은 공간 차지 (위치 고정)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: inputHorizontalPadding),
                          child: AuthInputField(
                            hint: inputHint,
                            value: _formatInputValue(inputValue),
                            onTap: () {},
                            fontSize: isMobile
                                ? _getResponsiveSize(context, 62)
                                : _getResponsiveSize(context, 36),
                            height: isMobile
                                ? _getResponsiveSize(context, 144)
                                : _getResponsiveSize(context, 80),
                            shadowStyle: ShadowStyle.bottom,
                          ),
                        ),
                        SizedBox(height: largeSpacing),
                        NumberKeypad(
                          onNumberPressed: onNumberPressed,
                          onClearAll: onClearAll,
                          onDelete: onDelete,
                        ),
                        SizedBox(height: spacing),
                        Center(
                          child: GestureDetector(
                            onTap: onConfirm,
                            child: Container(
                              width: buttonWidth,
                              height: _getResponsiveSize(context, 100),
                              decoration: BoxDecoration(
                                color: Color(0xFF227EFF),
                                borderRadius: BorderRadius.circular(
                                    isMobile ? 8.0 : _getResponsiveSize(context, 16)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.authConfirm,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: fontSize,
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatInputValue(String value) {
    if (value.isEmpty) return '';
    final digits = PhoneValidator.extractDigits(value);
    if (digits.startsWith('010') && digits.length >= 3) {
      return PhoneFormatter.format(value);
    }
    return value;
  }
}
