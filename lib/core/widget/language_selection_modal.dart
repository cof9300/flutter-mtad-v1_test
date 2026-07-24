import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class LanguageSelectionModal extends ConsumerStatefulWidget {
  const LanguageSelectionModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const LanguageSelectionModal(),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  ConsumerState<LanguageSelectionModal> createState() =>
      _LanguageSelectionModalState();
}

class _LanguageSelectionModalState
    extends ConsumerState<LanguageSelectionModal> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = ref.read(localeProvider);
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _handleLanguageSelect(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
  }

  void _handleConfirm() {
    if (_selectedLocale != null) {
      ref.read(localeProvider.notifier).changeTemporaryLocale(_selectedLocale!);
    }
    LanguageSelectionModal.hide(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: _getResponsiveSize(context, 950),
        height: _getResponsiveSize(context, 1360),
        decoration: BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 72)),
        ),
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Expanded(
              child: _buildLanguageList(context),
            ),
            _buildFooter(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: _getResponsiveSize(context, 150),
      decoration: BoxDecoration(
        color: Color(0xFF227EFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_getResponsiveSize(context, 72)),
          topRight: Radius.circular(_getResponsiveSize(context, 72)),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: _getResponsiveSize(context, 65),
            top: _getResponsiveSize(context, 47),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/language.svg',
                  width: _getResponsiveSize(context, 56),
                  height: _getResponsiveSize(context, 56),
                ),
                SizedBox(width: _getResponsiveSize(context, 24)),
                Text(
                  l10n.languageSelection,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 55),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: Colors.white,
                    height: 56 / 55,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: _getResponsiveSize(context, 65),
            top: _getResponsiveSize(context, 51),
            child: GestureDetector(
              onTap: () => LanguageSelectionModal.hide(context),
              child: Icon(
                Icons.close,
                size: _getResponsiveSize(context, 48),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 25),
        vertical: _getResponsiveSize(context, 35),
      ),
      child: Column(
        children: [
          _buildLanguageItem(
            context,
            locale: const Locale('ko'),
            nativeName: '한국어',
            englishName: 'korean',
            flagAsset: 'assets/icons/korean.svg',
          ),
          SizedBox(height: _getResponsiveSize(context, 25)),
          _buildLanguageItem(
            context,
            locale: const Locale('en'),
            nativeName: 'English',
            englishName: 'English',
            flagAsset: 'assets/icons/english.svg',
          ),
          SizedBox(height: _getResponsiveSize(context, 25)),
          _buildLanguageItem(
            context,
            locale: const Locale('zh'),
            nativeName: '中文',
            englishName: 'Chinese',
            flagAsset: 'assets/icons/china.webp',
          ),
          SizedBox(height: _getResponsiveSize(context, 25)),
          _buildLanguageItem(
            context,
            locale: const Locale('vi'),
            nativeName: 'Tiếng Việt',
            englishName: 'Vietnamese',
            flagAsset: 'assets/icons/vietnam.webp',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required Locale locale,
    required String nativeName,
    required String englishName,
    required String flagAsset,
  }) {
    final isSelected = _selectedLocale?.languageCode == locale.languageCode;

    return GestureDetector(
      onTap: () => _handleLanguageSelect(locale),
      child: Container(
        height: _getResponsiveSize(context, 168),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 32)),
          border: Border.all(
            color: isSelected ? Color(0xFF227EFF) : Color(0xFFE3E5EA),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: _getResponsiveSize(context, 36)),
            Container(
              width: _getResponsiveSize(context, 102),
              height: _getResponsiveSize(context, 102),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFE3E5EA),
                  width: 2,
                ),
              ),
              child: Center(
                child: flagAsset.endsWith('.webp')
                    ? Image.asset(
                        flagAsset,
                        width: _getResponsiveSize(context, 72),
                        height: _getResponsiveSize(context, 72),
                        fit: BoxFit.contain,
                      )
                    : SvgPicture.asset(
                        flagAsset,
                        width: _getResponsiveSize(context, 72),
                        height: _getResponsiveSize(context, 72),
                      ),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 48)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nativeName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 40),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: Color(0xFF111111),
                    letterSpacing: -1.0,
                    height: 56 / 40,
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 10)),
                Text(
                  englishName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 32),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 500),
                    ],
                    color: Color(0xFF595757),
                    letterSpacing: -0.8,
                    height: 56 / 32,
                  ),
                ),
              ],
            ),
            Spacer(),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(
                  right: _getResponsiveSize(context, 40),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: _getResponsiveSize(context, 60),
                  color: Color(0xFF227EFF),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: _getResponsiveSize(context, 200),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_getResponsiveSize(context, 72)),
          bottomRight: Radius.circular(_getResponsiveSize(context, 72)),
        ),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE3E5EA),
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: _handleConfirm,
          child: Container(
            width: _getResponsiveSize(context, 660),
            height: _getResponsiveSize(context, 120),
            decoration: BoxDecoration(
              color: Color(0xFF227EFF),
              borderRadius:
                  BorderRadius.circular(_getResponsiveSize(context, 16)),
            ),
            child: Center(
              child: Text(
                l10n.confirm,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 55),
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Colors.white,
                  height: 56 / 55,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

