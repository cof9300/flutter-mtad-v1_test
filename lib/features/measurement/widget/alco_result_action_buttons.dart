import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class AlcoResultActionButtons extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onSendMessage;

  const AlcoResultActionButtons({
    super.key,
    required this.onRetry,
    this.onSendMessage,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize).clamp(
      baseSize * 0.5,
      baseSize * 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          context,
          icon: 'assets/icons/refresh.svg',
          label: '재측정',
          onTap: onRetry,
        ),
        if (onSendMessage != null) ...[
          SizedBox(width: isMobile ? 12.0 : _getResponsiveSize(context, 28)),
          _buildButton(
            context,
            icon: 'assets/icons/message.svg',
            label: '문자전송',
            onTap: onSendMessage!,
          ),
        ],
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double width = isMobile
        ? (screenWidth - 48) / (onSendMessage != null ? 2 : 1)
        : _getResponsiveSize(context, 498);
    final double height = isMobile
        ? 100.0
        : _getResponsiveSize(context, 255);
    final double borderRadius = isMobile
        ? 12.0
        : _getResponsiveSize(context, 32);
    final double iconSize = isMobile
        ? 24.0
        : _getResponsiveSize(context, 80);
    final double gap = isMobile
        ? 4.0
        : _getResponsiveSize(context, 24);
    final double fontSize = isMobile
        ? 12.0
        : _getResponsiveSize(context, 32);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              offset: const Offset(2, 2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              offset: const Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 0,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: gap),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
