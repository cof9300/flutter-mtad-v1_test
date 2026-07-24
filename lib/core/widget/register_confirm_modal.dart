import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/input_formatter.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class RegisterConfirmModal {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required String phoneNumber,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String? nextstep,
    bool returnToPreviousScreen = false,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _RegisterConfirmModalWidget(
        phoneNumber: phoneNumber,
        onConfirm: onConfirm,
        onCancel: onCancel,
        nextstep: nextstep,
        returnToPreviousScreen: returnToPreviousScreen,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _RegisterConfirmModalWidget extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? nextstep;
  final bool returnToPreviousScreen;

  const _RegisterConfirmModalWidget({
    required this.phoneNumber,
    required this.onConfirm,
    required this.onCancel,
    this.nextstep,
    this.returnToPreviousScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedPhone = InputFormatter.formatDisplay(phoneNumber);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;
    
    final modalWidth = isLandscape
        ? (shortestSide * 0.8).clamp(400.0, 650.0)
        : (shortestSide * 0.85).clamp(300.0, 500.0);
    
    final padding = (shortestSide * 0.045).clamp(20.0, 35.0);
    final iconSize = (shortestSide * 0.12).clamp(60.0, 90.0);
    final titleFontSize = (shortestSide * 0.04).clamp(20.0, 28.0);
    final phoneFontSize = (shortestSide * 0.065).clamp(32.0, 48.0);
    final messageFontSize = (shortestSide * 0.035).clamp(18.0, 26.0);
    final buttonFontSize = (shortestSide * 0.04).clamp(20.0, 28.0);
    final buttonHeight = (shortestSide * 0.12).clamp(60.0, 80.0);
    final spacing = (shortestSide * 0.025).clamp(12.0, 20.0);
    final borderRadius = (shortestSide * 0.05).clamp(20.0, 35.0);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.85,
          ),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.09),
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/warning.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                SizedBox(height: spacing),
                Text(
                  l10n.noMemberFound,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: Color(0xFF595757),
                    letterSpacing: -titleFontSize * 0.025,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing),
                Text(
                  formattedPhone,
                  style: TextStyle(
                    fontFamily: AppTextStyles.titleFontFamily,
                    fontSize: phoneFontSize,
                    fontVariations: <FontVariation>[FontVariation('wght', 400)],
                    color: AppColors.primary,
                    letterSpacing: -phoneFontSize * 0.025,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing * 1.2),
                // returnToPreviousScreen이 true이고 nextstep이 NOTI인 경우: "관리자에게 문의해주세요." 표시
                if (returnToPreviousScreen && nextstep == 'NOTI')
                  Text(
                    l10n.contactAdministrator,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: messageFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                      color: Color(0xFF595757),
                      letterSpacing: -messageFontSize * 0.025,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  )
                // nextstep이 NOTI인 경우: "측정 하시겠습니까?" 표시
                else if (nextstep == 'NOTI')
                  Text(
                    l10n.measurementQuestion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: messageFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                      color: Color(0xFF595757),
                      letterSpacing: -messageFontSize * 0.025,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  )
                // 그 외: "이 번호로 회원가입 하시겠습니까?" 표시
                else
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: messageFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 500),
                        ],
                        color: Color(0xFF595757),
                        letterSpacing: -messageFontSize * 0.025,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: l10n.registerPrefix),
                        TextSpan(
                          text: ' ${l10n.registerHighlight} ',
                          style: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 700),
                            ],
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(text: l10n.registerSuffix),
                      ],
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: spacing * 1.5),
                // returnToPreviousScreen이 true이고 nextstep이 NOTI인 경우: 확인 버튼만 표시
                if (returnToPreviousScreen && nextstep == 'NOTI')
                  GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      width: double.infinity,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(
                          color: Color(0xFF2970FF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.confirm,
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: buttonFontSize,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                          color: Colors.white,
                          height: 1.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                // 그 외: 예/아니오 버튼 표시
                else
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: Color(0xFFE7EAF3),
                              border: Border.all(
                                color: Color(0xFFEAECF0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.no,
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: buttonFontSize,
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                                color: Color(0xFF595757),
                                height: 1.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              border: Border.all(
                                color: Color(0xFF2970FF),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.yes,
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: buttonFontSize,
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                                color: Colors.white,
                                height: 1.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
