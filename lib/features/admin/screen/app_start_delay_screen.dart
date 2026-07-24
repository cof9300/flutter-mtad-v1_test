import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppStartDelayScreen extends ConsumerStatefulWidget {
  const AppStartDelayScreen({super.key});

  @override
  ConsumerState<AppStartDelayScreen> createState() =>
      _AppStartDelayScreenState();
}

class _AppStartDelayScreenState extends ConsumerState<AppStartDelayScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDelay();
  }

  Future<void> _loadDelay() async {
    setState(() => _isLoading = true);
    try {
      final seconds =
          await ServiceLocator().appStartDelayService.getDelaySeconds();
      if (mounted) _controller.text = seconds.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final seconds = int.tryParse(text);
    if (seconds == null || seconds < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '0 이상의 숫자를 입력해주세요',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _rs(context, 24),
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ServiceLocator().appStartDelayService.setDelaySeconds(seconds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장되었습니다',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _rs(context, 24),
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 중 오류가 발생했습니다',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _rs(context, 24),
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _rs(BuildContext context, double base) {
    final w = MediaQuery.of(context).size.width;
    return (w / 1080.0 * base).clamp(base * 0.5, base * 1.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _rs(context, 20);
    final horizontalPadding = _rs(context, 80);
    final titleFontSize = _rs(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);
    final inputFontSize = _rs(context, 32);
    final labelFontSize = _rs(context, 28);
    final descFontSize = _rs(context, 24);

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
                          BorderRadius.circular(_rs(context, 8)),
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
            SizedBox(height: _rs(context, 60)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '앱 시작 동기화 시간',
                  style: TextStyle(
                    fontFamily: AppTextStyles.titleFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 900),
                    ],
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
            ),
            SizedBox(height: _rs(context, 60)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대기 시간 (초)',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: labelFontSize,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 600),
                        ],
                        color: const Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: _rs(context, 8)),
                    Text(
                      '앱이 처음 실행될 때 이 시간만큼 "앱 시작 중입니다." 화면이 표시됩니다.\n0초로 설정하면 이 기능이 비활성화됩니다. (기본값: 30초)',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: descFontSize,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: _rs(context, 20)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(_rs(context, 12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: inputFontSize,
                          color: const Color(0xFF111111),
                        ),
                        decoration: InputDecoration(
                          hintText: '초를 입력하세요 (예: 30)',
                          hintStyle: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontSize: inputFontSize,
                            color: const Color(0xFF999999),
                          ),
                          suffixText: '초',
                          suffixStyle: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontSize: inputFontSize,
                            color: const Color(0xFF444444),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _rs(context, 24),
                            vertical: _rs(context, 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(_rs(context, 12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _rs(context, 60)),
                    GestureDetector(
                      onTap: _isLoading ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: _rs(context, 24),
                        ),
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey : AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(_rs(context, 12)),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: _rs(context, 24),
                                  height: _rs(context, 24),
                                  child: const CircularProgressIndicator(
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
                                    fontVariations: const <FontVariation>[
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
            SizedBox(height: _rs(context, 40)),
          ],
        ),
      ),
    );
  }
}
