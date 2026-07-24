import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'dart:math' as math;

class LoadingModal {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingModalWidget(message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _LoadingModalWidget extends StatefulWidget {
  final String message;

  const _LoadingModalWidget({required this.message});

  @override
  State<_LoadingModalWidget> createState() => _LoadingModalWidgetState();
}

class _LoadingModalWidgetState extends State<_LoadingModalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
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
              SizedBox(height: 32),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: 24,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 600),
                  ],
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
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
    final radius = size.width / 2 - 10;
    const pillCount = 12;
    const pillWidth = 8.0;
    const pillHeight = 24.0;

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
