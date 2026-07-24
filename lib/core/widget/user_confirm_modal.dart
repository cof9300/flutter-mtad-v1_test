import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class UserConfirmModal {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required String username,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    bool returnToPreviousScreen = false,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _UserConfirmModalWidget(
        username: username,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _UserConfirmModalWidget extends StatelessWidget {
  final String username;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _UserConfirmModalWidget({
    required this.username,
    required this.onConfirm,
    required this.onCancel,
  });

  String _maskUsername(String name) {
    if (name.isEmpty) return name;

    final runes = name.runes.toList();
    if (runes.length == 1) return name;
    if (runes.length == 2) {
      return String.fromCharCode(runes[0]) + 'O';
    }

    final middleIndex = runes.length ~/ 2;
    final maskedName = StringBuffer();
    for (int i = 0; i < runes.length; i++) {
      if (i == middleIndex) {
        maskedName.write('O');
      } else {
        maskedName.writeCharCode(runes[i]);
      }
    }
    return maskedName.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;
    final longestSide = screenSize.longestSide;
    
    final modalWidth = isLandscape
        ? (longestSide * 0.5).clamp(400.0, 700.0)
        : (shortestSide * 0.86).clamp(300.0, 600.0);
    
    final modalMaxHeight = isLandscape
        ? shortestSide * 0.85
        : longestSide * 0.7;
    
    final padding = (shortestSide * 0.05).clamp(30.0, 60.0);
    final nameFontSize = (shortestSide * 0.08).clamp(40.0, 70.0);
    final questionFontSize = (shortestSide * 0.05).clamp(28.0, 48.0);
    final buttonFontSize = (shortestSide * 0.05).clamp(28.0, 48.0);
    final buttonHeight = (shortestSide * 0.15).clamp(70.0, 120.0);
    final spacing = (shortestSide * 0.04).clamp(20.0, 40.0);
    final borderRadius = (shortestSide * 0.05).clamp(25.0, 40.0);

    final maskedName = _maskUsername(username);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(maxHeight: modalMaxHeight),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.09),
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '$maskedName 님',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: nameFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: AppColors.primary,
                      height: 1.4,
                      letterSpacing: -nameFontSize * 0.025,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    l10n.userConfirmQuestion,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: questionFontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                      color: Color(0xFF4B4948),
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: spacing * 2),
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    width: double.infinity,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.09),
                          offset: Offset(0, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.userConfirmYes,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: buttonFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: Colors.white,
                        height: 1.4,
                        letterSpacing: -buttonFontSize * 0.025,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: double.infinity,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: Color(0xFFE7EAF3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.09),
                          offset: Offset(0, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.userConfirmNo,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: buttonFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: Color(0xFF595757),
                        height: 1.4,
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

