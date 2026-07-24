import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/auth/screen/standby_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KioskIdSettingScreen extends ConsumerStatefulWidget {
  const KioskIdSettingScreen({super.key});

  @override
  ConsumerState<KioskIdSettingScreen> createState() =>
      _KioskIdSettingScreenState();
}

class _KioskIdSettingScreenState extends ConsumerState<KioskIdSettingScreen> {
  final TextEditingController _kioskIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKioskId();
  }

  Future<void> _loadKioskId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final kioskId = await ServiceLocator().kioskIdStorage.getKioskId();
      setState(() {
        _kioskIdController.text = kioskId ?? '';
      });
    } catch (e) {
      print('Error loading kiosk ID: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveKioskId() async {
    final kioskId = _kioskIdController.text.trim();

    if (kioskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '키오스크 ID를 입력해주세요',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceLocator().kioskIdStorage.setKioskId(kioskId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '키오스크 ID가 저장되었습니다',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 24),
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const StandbyScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 중 오류가 발생했습니다',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 24),
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  void dispose() {
    _kioskIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _getResponsiveSize(context, 20);
    final horizontalPadding = _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);
    final inputFontSize = _getResponsiveSize(context, 32);
    final labelFontSize = _getResponsiveSize(context, 28);

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '키오스크 ID 설정',
                  style: TextStyle(
                    fontFamily: AppTextStyles.titleFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: <FontVariation>[FontVariation('wght', 900)],
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 60)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '키오스크 ID',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: labelFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 600),
                        ],
                        color: Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 20)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(_getResponsiveSize(context, 12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _kioskIdController,
                        enabled: !_isLoading,
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: inputFontSize,
                          color: Color(0xFF111111),
                        ),
                        decoration: InputDecoration(
                          hintText: '키오스크 ID를 입력하세요',
                          hintStyle: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontSize: inputFontSize,
                            color: Color(0xFF999999),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(context, 24),
                            vertical: _getResponsiveSize(context, 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(_getResponsiveSize(context, 12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 60)),
                    GestureDetector(
                      onTap: _isLoading ? null : _saveKioskId,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: _getResponsiveSize(context, 24),
                        ),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? Colors.grey
                              : AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(_getResponsiveSize(context, 12)),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: _getResponsiveSize(context, 24),
                                  height: _getResponsiveSize(context, 24),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  '저장',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: inputFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 40)),
          ],
        ),
      ),
    );
  }
}
