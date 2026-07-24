import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/error_modal.dart';
import 'package:flutter_template/core/widget/info_modal.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/utils/content_update_service.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

class ContentUpdateScreen extends ConsumerStatefulWidget {
  const ContentUpdateScreen({super.key});

  @override
  ConsumerState<ContentUpdateScreen> createState() => _ContentUpdateScreenState();
}

class _ContentUpdateScreenState extends ConsumerState<ContentUpdateScreen> {
  final _serviceLocator = ServiceLocator();
  bool? _kioskUpdate;
  bool? _siteUpdate;
  bool _isUpdating = false;
  double _updateProgress = 0.0;
  String _updateMessage = '';

  Future<void> _checkUpdate() async {
    try {
      if (_isUpdating) return;

      setState(() {
        _updateProgress = 0.0;
        _updateMessage = '업데이트 확인 중...';
      });

      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ErrorModal.show(context);
        }
        return;
      }

      await ContentUpdateService().resetThrottle();

      final response = await _serviceLocator.authRepository.getKioskOptionNewFlag(token);

      if (mounted) {
        setState(() {
          _kioskUpdate = response.resultData.kioskupdate;
          _siteUpdate = response.resultData.siteupdate;
          _updateMessage = '';
        });

        if (response.resultData.kioskupdate || response.resultData.siteupdate) {
          await _performUpdate(token);
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _updateMessage = '';
        });
        FlutterErrorLogger.logError('[관리자] 업데이트 확인 오류', e, stackTrace);
        ErrorModal.show(context);
      }
    }
  }

  Future<void> _performUpdate(String token) async {
    try {
      setState(() {
        _isUpdating = true;
        _updateProgress = 0.0;
        _updateMessage = '키오스크를 업데이트 중입니다';
      });

      await ContentUpdateService().performUpdate(
        token,
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _updateProgress = progress;
              _updateMessage = message;
            });
          }
        },
      );

      setState(() {
        _isUpdating = false;
        _updateProgress = 1.0;
        _updateMessage = '업데이트 완료';
        _kioskUpdate = false;
        _siteUpdate = false;
      });

      if (mounted) {
        InfoModal.show(
          context,
          title: '업데이트 완료',
          message: '컨텐츠 업데이트가 완료되었습니다.',
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        _isUpdating = false;
        _updateMessage = '';
      });
      FlutterErrorLogger.logError('[관리자] 콘텐츠 업데이트 오류', e, stackTrace);
      if (mounted) {
        ErrorModal.show(context);
      }
    }
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _getResponsiveSize(context, 20);
    final horizontalPadding = _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);
    final cardFontSize = _getResponsiveSize(context, 36);
    final buttonHeight = _getResponsiveSize(context, 100);
    final buttonFontSize = _getResponsiveSize(context, 40);

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
                      child: Icon(
                        Icons.chevron_left,
                        size: iconSize * 0.8,
                        color: Color(0xFF111111),
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
                '컨텐츠 업데이트',
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
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUpdating ? null : _checkUpdate,
                      child: Container(
                        width: double.infinity,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          color: _isUpdating ? Color(0xFF999999) : Color(0xFF227EFF),
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSize(context, 16),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '컨텐츠 업데이트',
                          style: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontSize: buttonFontSize,
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 600),
                            ],
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (_isUpdating) ...[
                      SizedBox(height: _getResponsiveSize(context, 60)),
                      Container(
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
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: _updateProgress,
                              backgroundColor: Color(0xFFE0E0E0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF227EFF)),
                              minHeight: _getResponsiveSize(context, 12),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 20)),
                            Text(
                              _updateMessage,
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: cardFontSize * 0.9,
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 500),
                                ],
                                color: Color(0xFF111111),
                              ),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 10)),
                            Text(
                              '${(_updateProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: cardFontSize * 1.2,
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                                color: Color(0xFF227EFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!_isUpdating && (_kioskUpdate != null || _siteUpdate != null)) ...[
                      SizedBox(height: _getResponsiveSize(context, 60)),
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_kioskUpdate != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '키오스크 업데이트',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.bodyFontFamily,
                                      fontSize: cardFontSize,
                                      fontVariations: <FontVariation>[
                                        FontVariation('wght', 600),
                                      ],
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  Text(
                                    _kioskUpdate! ? '업데이트 있음' : '업데이트 없음',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.bodyFontFamily,
                                      fontSize: cardFontSize * 0.9,
                                      fontVariations: <FontVariation>[
                                        FontVariation('wght', 400),
                                      ],
                                      color: _kioskUpdate!
                                          ? Color(0xFF227EFF)
                                          : Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                              if (_siteUpdate != null)
                                SizedBox(height: _getResponsiveSize(context, 20)),
                            ],
                            if (_siteUpdate != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '사이트 업데이트',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.bodyFontFamily,
                                      fontSize: cardFontSize,
                                      fontVariations: <FontVariation>[
                                        FontVariation('wght', 600),
                                      ],
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  Text(
                                    _siteUpdate! ? '업데이트 있음' : '업데이트 없음',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.bodyFontFamily,
                                      fontSize: cardFontSize * 0.9,
                                      fontVariations: <FontVariation>[
                                        FontVariation('wght', 400),
                                      ],
                                      color: _siteUpdate!
                                          ? Color(0xFF227EFF)
                                          : Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
