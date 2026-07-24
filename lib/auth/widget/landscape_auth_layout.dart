import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/rich_text_renderer.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/auth_right_panel.dart';
import 'package:flutter_template/providers/notifier/rich_text_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/core/utils/phone_formatter.dart';
import 'package:flutter_template/core/utils/phone_validator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class LandscapeAuthLayout extends ConsumerWidget {
  final String inputValue;
  final String inputHint;
  final VoidCallback onConfirm;
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;

  const LandscapeAuthLayout({
    super.key,
    required this.inputValue,
    required this.inputHint,
    required this.onConfirm,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height;

    final titleFontSize = (availableHeight * 0.04).clamp(22.0, 40.0);
    final titleHeight = (availableHeight * 0.15).clamp(60.0, 120.0);
    final inputHeight = (availableHeight * 0.11).clamp(60.0, 90.0);
    final inputFontSize = 44.0; //;
    final buttonHeight = (availableHeight * 0.11).clamp(60.0, 90.0);
    final buttonFontSize = (availableHeight * 0.04).clamp(22.0, 36.0);
    final horizontalPadding = (screenSize.width * 0.03).clamp(20.0, 50.0);
    final verticalSpacing = (availableHeight * 0.035).clamp(20.0, 35.0);

    final locale = ref.watch(localeProvider);
    final richTextNotifier = ref.watch(richTextNotifierProvider.notifier);
    final authTitleText = richTextNotifier.getText(
      'auth_title',
      locale.languageCode,
      l10n.authTitle,
    );

    return Column(
      children: [
        Container(
          height: titleHeight,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalSpacing * 0.5,
          ),
          child: RichTextRenderer(
            text: authTitleText,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: titleFontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Color(0xFF595757),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalSpacing,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AuthInputField(
                        hint: inputHint,
                        value: _formatInputValue(inputValue),
                        onTap: () {},
                        fontSize: inputFontSize,
                        height: inputHeight,
                        shadowStyle: ShadowStyle.bottom,
                      ),
                      SizedBox(height: verticalSpacing * 1.5),
                      GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          width: double.infinity,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: Color(0xFF227EFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.authConfirm,
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: buttonFontSize,
                              fontVariations: <FontVariation>[
                                FontVariation('wght', 600),
                              ],
                              color: AppColors.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: AuthRightPanel(
                  onNumberPressed: onNumberPressed,
                  onClearAll: onClearAll,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      ],
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
