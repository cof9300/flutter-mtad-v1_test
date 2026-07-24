import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'dart:math' as math;

class ProgressModal {
  static OverlayEntry? _overlayEntry;
  static final ValueNotifier<String?> _messageNotifier = ValueNotifier(null);
  static final ValueNotifier<String?> _titleNotifier = ValueNotifier(null);

  static void show(BuildContext context, {String? title, String? message}) {
    if (_overlayEntry != null) return;

    _titleNotifier.value = title;
    _messageNotifier.value = message;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ProgressModalWidget(
        titleNotifier: _titleNotifier,
        messageNotifier: _messageNotifier,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void updateMessage(String? message, {String? title}) {
    _titleNotifier.value = title;
    _messageNotifier.value = message;
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _titleNotifier.value = null;
    _messageNotifier.value = null;
  }
}

class _ProgressModalWidget extends StatefulWidget {
  final ValueNotifier<String?> titleNotifier;
  final ValueNotifier<String?> messageNotifier;

  const _ProgressModalWidget({
    required this.titleNotifier,
    required this.messageNotifier,
  });

  @override
  State<_ProgressModalWidget> createState() => _ProgressModalWidgetState();
}

class _ProgressModalWidgetState extends State<_ProgressModalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize).clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = (screenWidth * 0.9).clamp(300.0, 600.0);
    final padding = _getResponsiveSize(context, 60);
    final verticalPadding = _getResponsiveSize(context, 80);
    final loadingSize = _getResponsiveSize(context, 140);
    final titleFontSize = _getResponsiveSize(context, 40);
    final messageFontSize = _getResponsiveSize(context, 32);
    final borderRadius = _getResponsiveSize(context, 50);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Container(
            width: modalWidth,
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: padding),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: loadingSize,
                  height: loadingSize,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _PillLoadingPainter(
                          animationValue: _controller.value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 48)),
                ValueListenableBuilder<String?>(
                  valueListenable: widget.titleNotifier,
                  builder: (context, customTitle, _) {
                    return Text(
                      customTitle ?? l10n.progressTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: titleFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                SizedBox(height: _getResponsiveSize(context, 32)),
                ValueListenableBuilder<String?>(
                  valueListenable: widget.messageNotifier,
                  builder: (context, customMessage, _) {
                    return Text(
                      customMessage ?? l10n.progressMessage,
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillLoadingPainter extends CustomPainter {
  final double animationValue;

  _PillLoadingPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (size.width * 0.13);
    const pillCount = 12;
    final pillWidth = size.width * 0.1;
    final pillHeight = size.width * 0.3;

    for (int i = 0; i < pillCount; i++) {
      final angle =
          (i * 2 * math.pi / pillCount) + (animationValue * 2 * math.pi);
      final normalizedPosition = (i / pillCount);
      final opacity = 0.2 + (normalizedPosition * 0.8);

      final paint = Paint()
        ..color = Color(0xFF4A7FBF).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -radius);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: pillWidth,
          height: pillHeight,
        ),
        Radius.circular(pillWidth / 2),
      );

      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PillLoadingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

