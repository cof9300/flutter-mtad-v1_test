import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

/// 자율신경계(HRV) 정보입력 화면의 성별 선택 카드.
/// Figma: 사용자정보 - 자율신경계 (node 851:92 / 851:117)
class HrvGenderCard extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;

  const HrvGenderCard({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
    required this.height,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? const Color(0xFF111111) : const Color(0xFFB5B5B6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: Offset(
                _getResponsiveSize(context, 6),
                _getResponsiveSize(context, 6),
              ),
              blurRadius: _getResponsiveSize(context, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: _getResponsiveSize(context, 36),
              left: _getResponsiveSize(context, 36),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 46),
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: labelColor,
                  height: 56 / 46,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: _getResponsiveSize(context, 26),
                right: _getResponsiveSize(context, 36),
                child: SvgPicture.asset(
                  'assets/icons/device_check.svg',
                  width: _getResponsiveSize(context, 60),
                  height: _getResponsiveSize(context, 60),
                ),
              ),
            Positioned(
              top: _getResponsiveSize(context, 109),
              left: _getResponsiveSize(context, 229),
              width: _getResponsiveSize(context, 135),
              height: _getResponsiveSize(context, 205),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
