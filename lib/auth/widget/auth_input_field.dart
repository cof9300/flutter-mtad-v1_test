import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

enum ShadowStyle {
  none,
  bottomRight,
  bottom,
}

class AuthInputField extends StatelessWidget {
  final String hint;
  final String value;
  final VoidCallback onTap;
  final double? fontSize;
  final double? height;
  final bool isFocused;
  final bool rightRadiusOnly;
  final ShadowStyle shadowStyle;

  const AuthInputField({
    super.key,
    required this.hint,
    required this.value,
    required this.onTap,
    this.fontSize,
    this.height,
    this.isFocused = false,
    this.rightRadiusOnly = false,
    this.shadowStyle = ShadowStyle.none,
  });

  List<BoxShadow>? _getBoxShadow() {
    switch (shadowStyle) {
      case ShadowStyle.bottomRight:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: Offset(4, 4),
            blurRadius: 2,
          ),
        ];
      case ShadowStyle.bottom:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 2),
            blurRadius: 1,
          ),
        ];
      case ShadowStyle.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayFontSize = fontSize ?? 36.0;
    final displayHeight = height ?? 80;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: displayHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: () {
            final isMobile = MediaQuery.of(context).size.width < 600;
            final radius = isMobile ? 6.0 : 12.0;
            return rightRadiusOnly
                ? BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                    topRight: Radius.zero,
                    bottomRight: Radius.zero,
                  )
                : BorderRadius.circular(radius);
          }(),
          border: Border.all(
            color: isFocused ? Color(0xFF227EFF) : Colors.transparent,
            width: 3,
          ),
          boxShadow: _getBoxShadow(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.isEmpty ? hint : value,
            style: TextStyle(
              fontFamily: AppTextStyles.titleFontFamily,
              fontSize: value.isEmpty ? displayFontSize * 0.7 : displayFontSize,
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
              color: value.isEmpty ? Colors.grey : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
