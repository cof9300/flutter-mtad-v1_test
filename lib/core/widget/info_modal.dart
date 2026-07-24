import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class InfoModal {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context,
      {required String title, required String message}) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _InfoModalWidget(title: title, message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _InfoModalWidget extends StatelessWidget {
  final String title;
  final String message;

  const _InfoModalWidget({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;
    
    final modalWidth = isLandscape
        ? (shortestSide * 0.7).clamp(350.0, 550.0)
        : (shortestSide * 0.85).clamp(300.0, 500.0);
    
    final padding = (shortestSide * 0.05).clamp(25.0, 40.0);
    final titleFontSize = (shortestSide * 0.045).clamp(22.0, 32.0);
    final messageFontSize = (shortestSide * 0.035).clamp(18.0, 26.0);
    final buttonFontSize = (shortestSide * 0.04).clamp(20.0, 28.0);
    final buttonPadding = (shortestSide * 0.03).clamp(14.0, 22.0);
    final spacing = (shortestSide * 0.03).clamp(16.0, 28.0);
    final borderRadius = (shortestSide * 0.05).clamp(20.0, 35.0);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.6,
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
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: messageFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 400),
                    ],
                    color: Color(0xFF595757),
                    height: 1.5,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing * 1.5),
                GestureDetector(
                  onTap: () => InfoModal.hide(),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.confirm,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: buttonFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 600),
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
    );
  }
}
