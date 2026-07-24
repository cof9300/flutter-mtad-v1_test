import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class PhoneCheckModal {
  static OverlayEntry? _overlayEntry;
  static Timer? _autoCloseTimer;

  static void show(
    BuildContext context, {
    required VoidCallback onClose,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _PhoneCheckModalWidget(
        onClose: onClose,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(Duration(seconds: 5), () {
      hide();
      onClose();
    });
  }

  static void hide() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _PhoneCheckModalWidget extends StatelessWidget {
  final VoidCallback onClose;

  const _PhoneCheckModalWidget({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;

    final modalWidth = isLandscape
        ? (shortestSide * 0.8).clamp(400.0, 650.0)
        : (shortestSide * 0.85).clamp(300.0, 500.0);

    final padding = (shortestSide * 0.045).clamp(20.0, 35.0);
    final iconSize = (shortestSide * 0.12).clamp(60.0, 90.0);
    final titleFontSize = (shortestSide * 0.04).clamp(20.0, 28.0);
    final spacing = (shortestSide * 0.04).clamp(20.0, 40.0);
    final borderRadius = (shortestSide * 0.05).clamp(20.0, 35.0);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(
            maxHeight: 500,
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
                SizedBox(height: 10),
                SvgPicture.asset(
                  'assets/icons/warning.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                SizedBox(height: 50),
                Text(
                  l10n.phoneCheckMessage,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
