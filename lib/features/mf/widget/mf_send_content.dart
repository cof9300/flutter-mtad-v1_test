import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class MfSendContent extends StatelessWidget {
  const MfSendContent({super.key});

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
    return SizedBox(
      height: _getResponsiveSize(context, 560),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildConfirmationText(context),
          ),
          Positioned(
            top: _getResponsiveSize(context, 80),
            right: _getResponsiveSize(context, 60),
            child: _buildPhoneImage(context),
          ),
          Positioned(
            top: _getResponsiveSize(context, 290),
            left: _getResponsiveSize(context, 160),
            child: _buildInstructionText(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationText(BuildContext context) {
    final fontSize = _getResponsiveSize(context, 46);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 28)),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: fontSize,
            fontVariations: const [FontVariation('wght', 600)],
            letterSpacing: -1.6,
          ),
          children: const [
            TextSpan(
              text: '설문조사 링크',
              style: TextStyle(color: Color(0xFF227EFF)),
            ),
            TextSpan(
              text: '가 전송되었습니다.',
              style: TextStyle(color: Color(0xFF595757)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneImage(BuildContext context) {
    return Image.asset(
      'assets/images/send_form.png',
      width: _getResponsiveSize(context, 400),
      height: _getResponsiveSize(context, 460),
      fit: BoxFit.contain,
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final fontSize = _getResponsiveSize(context, 46);
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontSize: fontSize,
          fontVariations: const [FontVariation('wght', 600)],
          letterSpacing: -1.2,
          height: 1.5,
        ),
        children: const [
          TextSpan(
            text: '휴대폰에서 ',
            style: TextStyle(color: Color(0xFF595757)),
          ),
          TextSpan(
            text: '링크 접속',
            style: TextStyle(
              color: Color(0xFF227EFF),
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
          TextSpan(
            text: ' 후\n설문조사를 진행 해주세요.',
            style: TextStyle(color: Color(0xFF595757)),
          ),
        ],
      ),
    );
  }
}
