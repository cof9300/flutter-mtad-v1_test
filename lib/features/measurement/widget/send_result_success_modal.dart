import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class SendResultSuccessModal extends StatefulWidget {
  final VoidCallback onConfirm;

  const SendResultSuccessModal({
    super.key,
    required this.onConfirm,
  });

  @override
  State<SendResultSuccessModal> createState() => _SendResultSuccessModalState();

  static void show(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => SendResultSuccessModal(onConfirm: onConfirm),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class _SendResultSuccessModalState extends State<SendResultSuccessModal> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // 5초 후 자동으로 닫기
    _autoCloseTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _handleConfirm() {
    _autoCloseTimer?.cancel();
    widget.onConfirm();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    final isMobile = screenWidth < 600;
    final minScale = isMobile ? 0.3 : 0.5;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * minScale, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: _getResponsiveSize(context, 932),
        height: _getResponsiveSize(context, 675),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 50)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF004F99).withValues(alpha: 0.09),
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: _getResponsiveSize(context, 60)),
            SvgPicture.asset(
              'assets/icons/check.svg',
              width: _getResponsiveSize(context, 130),
              height: _getResponsiveSize(context, 130),
            ),
            SizedBox(height: _getResponsiveSize(context, 70)),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 68),
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 500),
                  ],
                  color: Color(0xFF4B4948),
                  letterSpacing: -1.7,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: l10n.sendMessageSuccessHighlight,
                    style: TextStyle(
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: Color(0xFF227EFF),
                    ),
                  ),
                  TextSpan(
                    text: l10n.sendMessageSuccessSuffix,
                  ),
                ],
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: _handleConfirm,
              child: Container(
                width: _getResponsiveSize(context, 660),
                height: _getResponsiveSize(context, 120),
                decoration: BoxDecoration(
                  color: Color(0xFF227EFF),
                  borderRadius:
                      BorderRadius.circular(_getResponsiveSize(context, 16)),
                ),
                child: Center(
                  child: Text(
                    l10n.confirm,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 55),
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: Colors.white,
                      height: 56 / 55,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 54)),
          ],
        ),
      ),
    );
  }
}




