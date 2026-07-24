import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/text_parser.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class RegistrationCompleteModal {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _RegistrationCompleteModalWidget(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _RegistrationCompleteModalWidget extends StatelessWidget {
  const _RegistrationCompleteModalWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;
    final longestSide = screenSize.longestSide;
    
    final modalWidth = isLandscape
        ? (longestSide * 0.55).clamp(500.0, 800.0)
        : (shortestSide * 0.85).clamp(300.0, 600.0);
    
    final padding = (shortestSide * 0.045).clamp(25.0, 40.0);
    final titleFontSize = (shortestSide * 0.045).clamp(22.0, 32.0);
    final messageFontSize = (shortestSide * 0.035).clamp(18.0, 26.0);
    final buttonFontSize = (shortestSide * 0.045).clamp(22.0, 32.0);
    final buttonHeight = (shortestSide * 0.12).clamp(60.0, 85.0);
    final imageSize = isLandscape
        ? (shortestSide * 0.35).clamp(150.0, 250.0)
        : (shortestSide * 0.5).clamp(200.0, 350.0);
    final spacing = (shortestSide * 0.03).clamp(15.0, 25.0);
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
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.registrationCompleteTitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    color: Color(0xFF111111),
                    letterSpacing: -titleFontSize * 0.025,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing),
                Image.asset(
                  'assets/images/registration.png',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: spacing),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextParser.parseStyledText(
                    l10n.registrationCompleteMessage,
                    defaultStyle: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: messageFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                      color: Color(0xFF595757),
                      height: 1.4,
                      letterSpacing: -messageFontSize * 0.033,
                    ),
                    boldStyle: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: messageFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                      color: Color(0xFF595757),
                      height: 1.4,
                      letterSpacing: -messageFontSize * 0.033,
                    ),
                    coloredBoldStyle: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: messageFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: AppColors.headerBackground,
                      height: 1.4,
                      letterSpacing: -messageFontSize * 0.033,
                    ),
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing * 1.5),
                GestureDetector(
                  onTap: () {
                    RegistrationCompleteModal.hide();
                    // 결과 화면에서 왔는지 확인 (Route 이름으로 판단)
                    final canPop = Navigator.of(context).canPop();
                    if (canPop) {
                      // 이전 화면이 있으면 돌아가기
                      Navigator.of(context).pop();
                    } else {
                      // 첫 화면으로 이동
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.headerBackground,
                      borderRadius: BorderRadius.circular(12),
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
                        letterSpacing: -buttonFontSize * 0.025,
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
    );
  }
}
