import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/auth_birthday_gender_keypad.dart';
import 'package:flutter_template/auth/widget/birthday_gender_row_widget.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/core/utils/phone_formatter.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';
import 'package:flutter_template/providers/notifier/agreement_option_notifier.dart';
import 'package:flutter_template/core/widget/agreement_image_modal.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class PortraitAuthWithBirthdayGenderLayout extends ConsumerWidget {
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

  const PortraitAuthWithBirthdayGenderLayout({
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

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final inputHorizontalPadding = _getResponsiveSize(context, 80);
    final spacing = _getResponsiveSize(context, 25);
    final buttonWidth = (screenWidth * 0.72).clamp(500.0, 780.0);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: inputHorizontalPadding),
                  child: BirthdayGenderRowWidget(
                    birthdayInputValue: birthdayInputValue,
                    selectedGender: selectedGender,
                    onInputFieldTapped: onInputFieldTapped,
                    onGenderSelected: onGenderSelected,
                    inputHeight: _getResponsiveSize(context, 100),
                    inputFontSize: _getResponsiveSize(context, 46),
                    spacing: _getResponsiveSize(context, 60),
                    currentInputMode: currentInputMode,
                  ),
                ),
                SizedBox(height: spacing),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: inputHorizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AuthInputField(
                              hint: phoneInputHint,
                              value: _formatPhone(phoneInputValue),
                              onTap: () => onInputFieldTapped(InputMode.phone),
                              fontSize: _getResponsiveSize(context, 46),
                              height: _getResponsiveSize(context, 100),
                              isFocused: currentInputMode == InputMode.phone,
                              rightRadiusOnly: true,
                              shadowStyle: ShadowStyle.bottomRight,
                            ),
                          ),
                          GestureDetector(
                            onTap: onRequestAuth,
                            child: Container(
                              width: _getResponsiveSize(context, 240),
                              height: _getResponsiveSize(context, 100),
                              decoration: BoxDecoration(
                                color: Color(0xFF227EFF),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(
                                      _getResponsiveSize(context, 16)),
                                  bottomRight: Radius.circular(
                                      _getResponsiveSize(context, 16)),
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
                              child: Text(
                                AppLocalizations.of(context)!.requestAuth,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: _getResponsiveSize(context, 42),
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
                        SizedBox(height: 10),
                        AuthInputField(
                          hint: AppLocalizations.of(context)!
                              .enterVerificationCode,
                          value: verificationCode,
                          onTap: () =>
                              onInputFieldTapped(InputMode.verificationCode),
                          fontSize: _getResponsiveSize(context, 46),
                          height: _getResponsiveSize(context, 100),
                          isFocused:
                              currentInputMode == InputMode.verificationCode,
                          shadowStyle: ShadowStyle.bottomRight,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: isAuthRequested
                      ? (70 - (10 + _getResponsiveSize(context, 100)))
                          .clamp(0.0, 70.0)
                      : 70,
                ),
                AuthBirthdayGenderKeypad(
                  onNumberPressed: onNumberPressed,
                  onClearAll: onClearAll,
                  onDelete: onDelete,
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: isAuthRequested ? onConfirm : null,
            child: Container(
              width: buttonWidth,
              height: _getResponsiveSize(context, 120),
              decoration: BoxDecoration(
                color: isAuthRequested ? Color(0xFF227EFF) : Color(0xFFBDBDBD),
                borderRadius:
                    BorderRadius.circular(_getResponsiveSize(context, 16)),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.agreeAllAndSend,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 48),
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isAuthRequested ? spacing : spacing * 2),
        _buildTermsSection(context, ref, l10n),
      ],
    );
  }

  String _formatPhone(String value) {
    if (value.isEmpty) return '';
    return PhoneFormatter.format(value);
  }

  Widget _buildTermsSection(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      // 고정 height 제거: 태블릿 등 소형 논리 해상도에서 약관 행이
      // Container 높이를 초과해 GestureDetector 터치 영역이 클립되는 문제 방지.
      // 내용 크기에 따라 자동으로 높이가 결정된다.
      constraints: BoxConstraints(
        minHeight: _getResponsiveSize(context, 200),
      ),
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 150),
        vertical: _getResponsiveSize(context, 35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.termsAgreement,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 30),
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: Color(0xFF595757),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 11)),
          _buildTermsItem(
              context, ref, l10n, l10n.privacyPolicy, l10n.viewDetails, 2),
          SizedBox(height: _getResponsiveSize(context, 11)),
          _buildTermsItem(
              context, ref, l10n, l10n.termsOfService, l10n.viewDetails, 1),
          SizedBox(height: _getResponsiveSize(context, 11)),
          _buildTermsItem(
              context, ref, l10n, l10n.thirdPartyInfo, l10n.viewDetails, 3),
          SizedBox(height: _getResponsiveSize(context, 11)),
          _buildTermsItem(
              context, ref, l10n, l10n.sensitiveInfo, l10n.viewDetails, 4),
        ],
      ),
    );
  }

  Widget _buildTermsItem(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, String title, String linkText, int type) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 30),
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Color(0xFF595757),
            ),
          ),
        ),
        Container(
          width: _getResponsiveSize(context, 360),
          height: 1,
          color: Color(0xFFD9D9D9),
        ),
        SizedBox(width: _getResponsiveSize(context, 30)),
        GestureDetector(
          onTap: () => _handleViewAgreement(context, ref, type),
          child: Text(
            linkText,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 30),
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
