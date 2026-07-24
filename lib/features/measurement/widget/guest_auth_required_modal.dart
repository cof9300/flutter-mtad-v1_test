import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class GuestAuthRequiredModal {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required VoidCallback onConfirm,
    required VoidCallback onDecline,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _GuestAuthRequiredModalWidget(
        onConfirm: onConfirm,
        onDecline: onDecline,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _GuestAuthRequiredModalWidget extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _GuestAuthRequiredModalWidget({
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final shortestSide = screenSize.shortestSide;

    final modalWidth = isLandscape
        ? (shortestSide * 0.9).clamp(600.0, 932.0)
        : (shortestSide * 0.9).clamp(500.0, 932.0);

    final padding = (shortestSide * 0.045).clamp(20.0, 35.0);
    final iconSize = (shortestSide * 0.12).clamp(60.0, 130.0);
    final titleFontSize = (shortestSide * 0.067).clamp(28.0, 72.0);
    final messageFontSize = (shortestSide * 0.043).clamp(18.0, 46.0);
    final buttonFontSize = (shortestSide * 0.051).clamp(20.0, 55.0);
    final buttonHeight = (shortestSide * 0.111).clamp(60.0, 120.0);
    final spacing = (shortestSide * 0.025).clamp(12.0, 20.0);
    final borderRadius = (shortestSide * 0.046).clamp(20.0, 50.0);

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
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
                color: AppColors.primary.withValues(alpha: 0.09),
                offset: const Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: spacing),
                _buildIcon(iconSize),
                SizedBox(height: spacing * 1.5),
                _buildTitle(l10n, titleFontSize),
                SizedBox(height: spacing * 1.2),
                _buildMessage(l10n, messageFontSize),
                SizedBox(height: spacing * 2),
                _buildButtons(
                  context,
                  l10n,
                  buttonFontSize,
                  buttonHeight,
                  spacing,
                ),
                SizedBox(height: spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: iconSize * 0.6,
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n, double fontSize) {
    return Text(
      l10n.guestAuthRequiredTitle,
      style: TextStyle(
        fontFamily: AppTextStyles.bodyFontFamily,
        fontSize: fontSize,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 700),
        ],
        color: AppColors.primary,
        letterSpacing: -fontSize * 0.025,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(AppLocalizations l10n, double fontSize) {
    final highlight = l10n.guestAuthRequiredHighlight;
    final message = l10n.guestAuthRequiredMessage(highlight);
    final parts = message.split(highlight);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontSize: fontSize,
          fontVariations: const <FontVariation>[
            FontVariation('wght', 500),
          ],
          color: const Color(0xFF595757),
          letterSpacing: -fontSize * 0.025,
          height: 1.4,
        ),
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts[0]),
          TextSpan(
            text: highlight,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: fontSize,
              fontVariations: const <FontVariation>[
                FontVariation('wght', 700),
              ],
              color: const Color(0xFF595757),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildButtons(
    BuildContext context,
    AppLocalizations l10n,
    double fontSize,
    double height,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              GuestAuthRequiredModal.hide(context);
              onDecline();
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.no,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: fontSize,
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: AppColors.primary,
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
            onTap: () {
              GuestAuthRequiredModal.hide(context);
              onConfirm();
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(
                  color: const Color(0xFF2970FF),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.yes,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: fontSize,
                  fontVariations: const <FontVariation>[
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
    );
  }
}
