import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/features/admin/widget/rich_text_management_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GuestPhoneTextEditScreen extends ConsumerWidget {
  const GuestPhoneTextEditScreen({super.key});

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _getResponsiveSize(context, 20);
    final horizontalPadding = _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);

    return CommonLayout(
      disableClockAdminEntry: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: topPadding, top: topPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(_getResponsiveSize(context, 8)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/keypad-back.svg',
                        width: iconSize * 1.07,
                        height: iconSize * 1.07,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 60)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                '서비스형 텍스트 관리',
                style: TextStyle(
                  fontFamily: AppTextStyles.titleFontFamily,
                  fontSize: titleFontSize,
                  fontVariations: <FontVariation>[FontVariation('wght', 900)],
                  color: Color(0xFF111111),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 80)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_getResponsiveSize(context, 40)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSize(context, 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: RichTextManagementWidget(textKey: 'guest_phone_title'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
