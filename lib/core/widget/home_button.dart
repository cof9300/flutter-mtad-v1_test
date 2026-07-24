import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  final double topPadding;
  final double leftPadding;

  const HomeButton({
    super.key,
    required this.onTap,
    required this.topPadding,
    required this.leftPadding,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final iconSize = isMobile ? 36.0 : _getResponsiveSize(context, 100);
    final touchAreaSize = isMobile ? 42.0 : _getResponsiveSize(context, 120);
    final buttonSize = isMobile ? 38.0 : _getResponsiveSize(context, 100);
    final borderRadius = isMobile ? 19.0 : _getResponsiveSize(context, 8);

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: topPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: touchAreaSize,
            height: touchAreaSize,
            alignment: Alignment.center,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/home.svg',
                  width: iconSize * 1.07,
                  height: iconSize * 1.07,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

