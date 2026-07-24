import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class DeviceConnectionModal extends StatelessWidget {
  final double footerHeight;

  const DeviceConnectionModal({
    super.key,
    required this.footerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final shortestSide = screenSize.shortestSide;

    // 모달 높이를 충분히 크게 설정 (푸터의 약 45% 정도)
    final modalHeight = (footerHeight * 0.45).clamp(160.0, 240.0);
    final padding = (shortestSide * 0.018).clamp(10.0, 16.0);
    final borderRadius = (shortestSide * 0.02).clamp(10.0, 16.0);
    final topBorderWidth = (shortestSide * 0.005).clamp(2.0, 4.0);

    // 폰트 크기
    final primaryFontSize = (shortestSide * 0.028).clamp(16.0, 22.0);
    final secondaryFontSize = (shortestSide * 0.024).clamp(14.0, 20.0);

    // 아이콘 크기
    final iconSize = (shortestSide * 0.06).clamp(35.0, 60.0);

    // 색상 (피그마 디자인 기준)
    final backgroundColor = Color(0xFFF2F2F2); // 밝은 회색 배경
    final redColor = Color(0xFFE50000); // 빨간색 테두리
    final primaryTextColor = Color(0xFF333333); // 어두운 회색 메인 텍스트
    final secondaryTextColor = Color(0xFF666666); // 밝은 회색 보조 텍스트

    // 양쪽 여백 설정
    final horizontalMargin = (shortestSide * 0.05).clamp(20.0, 40.0);

    return Material(
      elevation: 8,
      color: Colors.transparent,
      child: Container(
        height: modalHeight,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border(
            top: BorderSide(
              color: redColor,
              width: topBorderWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding * 1.2,
            vertical: padding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아이콘
              SvgPicture.asset(
                'assets/icons/unlink.svg',
                width: iconSize,
                height: iconSize,
              ),
              SizedBox(height: padding * 0.7),
              // 메인 메시지
              Flexible(
                child: Text(
                  l10n.deviceConnectionNotConfirmed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: primaryFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: primaryTextColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: padding * 0.5),
              // 보조 메시지
              Flexible(
                child: Text(
                  l10n.deviceConnectionCheckMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: secondaryFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 400),
                    ],
                    color: secondaryTextColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
