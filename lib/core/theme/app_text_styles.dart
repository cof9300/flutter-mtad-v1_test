import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String titleFontFamily = 'Pretendard';
  static const String bodyFontFamily = 'Pretendard';

  static const TextStyle headerTitle = TextStyle(
    fontFamily: titleFontFamily,
    color: AppColors.textWhite,
    fontSize: 40,
    fontVariations: <FontVariation>[
      FontVariation('wght', 900),
    ],
    letterSpacing: -1.0,
    height: 1.0,
  );

  static const TextStyle headerTime = TextStyle(
    fontFamily: bodyFontFamily,
    color: AppColors.textWhite,
    fontSize: 24,
    fontVariations: <FontVariation>[
      FontVariation('wght', 400),
    ],
    letterSpacing: -0.6,
    height: 1.3,
  );

  static const TextStyle headerLogoText = TextStyle(
    fontFamily: bodyFontFamily,
    color: AppColors.textWhite,
    fontSize: 16,
    fontVariations: <FontVariation>[
      FontVariation('wght', 600),
    ],
    letterSpacing: 1.2,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16,
    fontVariations: <FontVariation>[
      FontVariation('wght', 400),
    ],
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: titleFontFamily,
    fontSize: 24,
    fontVariations: <FontVariation>[
      FontVariation('wght', 700),
    ],
  );

  static const TextStyle primaryButton = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 32,
    fontVariations: <FontVariation>[
      FontVariation('wght', 600),
    ],
    color: AppColors.textWhite,
  );
}
