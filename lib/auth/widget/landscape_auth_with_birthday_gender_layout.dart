import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/auth_right_panel.dart';
import 'package:flutter_template/auth/widget/birthday_gender_row_widget.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/core/utils/phone_formatter.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';
import 'package:flutter_template/providers/notifier/agreement_option_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/widget/agreement_image_modal.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class LandscapeAuthWithBirthdayGenderLayout extends ConsumerWidget {
  final String phoneInputValue;
  final String birthdayInputValue;
  final String? selectedGender;
  final String verificationCode;
  final bool isAuthRequested;
  final String phoneInputHint;
  final InputMode currentInputMode;
  final VoidCallback onConfirm;
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;
  final Function(String) onGenderSelected;
  final Function(InputMode) onInputFieldTapped;
  final VoidCallback onRequestAuth;

  const LandscapeAuthWithBirthdayGenderLayout({
    super.key,
    required this.phoneInputValue,
    required this.birthdayInputValue,
    required this.selectedGender,
    required this.verificationCode,
    required this.isAuthRequested,
    required this.phoneInputHint,
    required this.currentInputMode,
    required this.onConfirm,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
    required this.onGenderSelected,
    required this.onInputFieldTapped,
    required this.onRequestAuth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height;

    final inputHeight = (availableHeight * 0.1).clamp(70.0, 90.0);
    final inputFontSize = 36.0;
    final verificationHeight = (availableHeight * 0.09).clamp(65.0, 85.0);
    final verificationFontSize = 32.0;
    final buttonHeight = (availableHeight * 0.09).clamp(55.0, 80.0);
    final buttonFontSize = (availableHeight * 0.035).clamp(20.0, 32.0);
    final horizontalPadding = (screenSize.width * 0.03).clamp(20.0, 50.0);
    final verticalSpacing = (availableHeight * 0.025).clamp(15.0, 25.0);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalSpacing,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BirthdayGenderRowWidget(
                                birthdayInputValue: birthdayInputValue,
                                selectedGender: selectedGender,
                                onInputFieldTapped: onInputFieldTapped,
                                onGenderSelected: onGenderSelected,
                                inputHeight: inputHeight,
                                inputFontSize: inputFontSize,
                                spacing: horizontalPadding * 0.5,
                                currentInputMode: currentInputMode,
                              ),
                              SizedBox(height: verticalSpacing),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AuthInputField(
                                          hint: phoneInputHint,
                                          value: _formatPhone(phoneInputValue),
                                          onTap: () => onInputFieldTapped(
                                              InputMode.phone),
                                          fontSize: inputFontSize,
                                          height: inputHeight,
                                          isFocused: currentInputMode ==
                                              InputMode.phone,
                                          rightRadiusOnly: true,
                                          shadowStyle: ShadowStyle.bottomRight,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: onRequestAuth,
                                        child: Container(
                                          width: (screenSize.width * 0.18)
                                              .clamp(160.0, 200.0),
                                          height: inputHeight,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF227EFF),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.15),
                                                offset: Offset(4, 4),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .requestAuth,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.bodyFontFamily,
                                              fontSize: buttonFontSize * 0.75,
                                              fontVariations: <FontVariation>[
                                                FontVariation('wght', 600),
                                              ],
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isAuthRequested) ...[
                                    SizedBox(height: verticalSpacing * 0.5),
                                    AuthInputField(
                                      hint: AppLocalizations.of(context)!
                                          .enterVerificationCode,
                                      value: verificationCode,
                                      onTap: () => onInputFieldTapped(
                                          InputMode.verificationCode),
                                      fontSize: verificationFontSize,
                                      height: verificationHeight,
                                      isFocused: currentInputMode ==
                                          InputMode.verificationCode,
                                      shadowStyle: ShadowStyle.bottomRight,
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(
                                  height: isAuthRequested
                                      ? verticalSpacing * 0.3
                                      : verticalSpacing * 0.8),
                              GestureDetector(
                                onTap: isAuthRequested ? onConfirm : null,
                                child: Container(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  decoration: BoxDecoration(
                                    color: isAuthRequested
                                        ? Color(0xFF227EFF)
                                        : Color(0xFFBDBDBD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l10n.agreeAllAndSend,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.bodyFontFamily,
                                      fontSize: buttonFontSize * 1.5,
                                      fontVariations: <FontVariation>[
                                        FontVariation('wght', 700),
                                      ],
                                      color: Colors.white,
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
                    ),
                    _buildTermsSection(context, ref, l10n, screenSize),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: AuthRightPanel(
                  onNumberPressed: onNumberPressed,
                  onClearAll: onClearAll,
                  onDelete: onDelete,
                  scale: 0.75,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPhone(String value) {
    if (value.isEmpty) return '';
    return PhoneFormatter.format(value);
  }

  Widget _buildTermsSection(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, Size screenSize) {
    final termsHeight = (screenSize.height * 0.25).clamp(200.0, 300.0);
    final termsFontSize = (screenSize.height * 0.025).clamp(20.0, 30.0);
    final horizontalPadding = (screenSize.width * 0.03).clamp(20.0, 50.0);
    final verticalSpacing = (screenSize.height * 0.035).clamp(20.0, 35.0);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: termsHeight),
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding * 5,
        vertical: verticalSpacing * 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.termsAgreement,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: termsFontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: Color(0xFF595757),
            ),
          ),
          SizedBox(height: verticalSpacing * 0.22),
          _buildTermsItem(context, ref, l10n, l10n.privacyPolicy,
              l10n.viewDetails, 2, termsFontSize, horizontalPadding),
          SizedBox(height: verticalSpacing * 0.22),
          _buildTermsItem(context, ref, l10n, l10n.termsOfService,
              l10n.viewDetails, 1, termsFontSize, horizontalPadding),
          SizedBox(height: verticalSpacing * 0.22),
          _buildTermsItem(context, ref, l10n, l10n.thirdPartyInfo,
              l10n.viewDetails, 3, termsFontSize, horizontalPadding),
          SizedBox(height: verticalSpacing * 0.22),
          _buildTermsItem(context, ref, l10n, l10n.sensitiveInfo,
              l10n.viewDetails, 4, termsFontSize, horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildTermsItem(
      BuildContext context,
      WidgetRef ref,
      AppLocalizations l10n,
      String title,
      String linkText,
      int type,
      double fontSize,
      double padding) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: fontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Color(0xFF595757),
            ),
          ),
        ),
        Container(
          width: padding * 7,
          height: 1,
          color: Color(0xFFD9D9D9),
        ),
        SizedBox(width: padding * 0.6),
        GestureDetector(
          onTap: () => _handleViewAgreement(context, ref, type),
          child: Text(
            linkText,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: fontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 500),
              ],
              color: Color(0xFF227EFF),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF227EFF),
            ),
          ),
        ),
      ],
    );
  }

  bool _isLocalFile(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  Future<void> _handleViewAgreement(
      BuildContext context, WidgetRef ref, int type) async {
    var agreementOption = ref.read(agreementOptionProvider);
    String imagePath = _agreementPathFor(agreementOption, type);

    if (imagePath.isEmpty) {
      final refreshed = await _ensureAgreementOptionFresh(ref);
      if (refreshed != null) {
        agreementOption = refreshed;
        imagePath = _agreementPathFor(agreementOption, type);
      }
    }

    if (imagePath.isEmpty || !context.mounted) return;

    final imageUrl =
        _isLocalFile(imagePath) ? imagePath : '${Config.baseUrl}$imagePath';
    AgreementImageModal.show(context, imageUrl: imageUrl);
  }

  String _agreementPathFor(AgreementOptionResponse? option, int type) {
    if (option == null) return '';
    switch (type) {
      case 1:
        return option.agreeimage1;
      case 2:
        return option.agreeimage2;
      case 3:
        return option.agreeimage3;
      case 4:
        return option.agreeimage4;
      default:
        return '';
    }
  }

  Future<AgreementOptionResponse?> _ensureAgreementOptionFresh(
      WidgetRef ref) async {
    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null || token.isEmpty) return null;
      final fresh =
          await ServiceLocator().authRepository.getAgreementOption(token);
      await ServiceLocator()
          .contentStorageService
          .saveAgreementOption(fresh);
      final reloaded = ServiceLocator()
          .contentStorageService
          .getStoredAgreementOption();
      if (reloaded != null) {
        ref
            .read(agreementOptionProvider.notifier)
            .setAgreementOption(reloaded);
      }
      return reloaded;
    } catch (_) {
      return null;
    }
  }
}
