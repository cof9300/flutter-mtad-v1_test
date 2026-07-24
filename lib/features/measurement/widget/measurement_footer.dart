import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class MeasurementFooter extends StatefulWidget {
  final double height;
  final VoidCallback onHomePressed;
  final int waitTimeSeconds;

  const MeasurementFooter({
    super.key,
    required this.height,
    required this.onHomePressed,
    required this.waitTimeSeconds,
  });

  @override
  State<MeasurementFooter> createState() => _MeasurementFooterState();
}

class _MeasurementFooterState extends State<MeasurementFooter> {
  Timer? _uiUpdateTimer;
  DateTime? _startTime;
  double _actualProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    if (widget.waitTimeSeconds <= 0) return;

    _startTime = DateTime.now();
    _actualProgress = 0.0;

    _startUIUpdateTimer();
  }

  void _startUIUpdateTimer() {
    _uiUpdateTimer?.cancel();

    // UI를 60fps로 업데이트 (16ms마다)
    _uiUpdateTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_startTime != null && widget.waitTimeSeconds > 0) {
        final actualElapsed =
            DateTime.now().difference(_startTime!).inMilliseconds;
        final totalMilliseconds = widget.waitTimeSeconds * 1000;
        final newProgress = (actualElapsed / totalMilliseconds).clamp(0.0, 1.0);

        if ((newProgress - _actualProgress).abs() > 0.001) {
          setState(() {
            _actualProgress = newProgress;
          });
        }

        if (newProgress >= 1.0) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void didUpdateWidget(MeasurementFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waitTimeSeconds != widget.waitTimeSeconds &&
        widget.waitTimeSeconds > 0) {
      _startTimers();
    }
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isKiosk = DeviceConfig().isLargeKiosk(context);
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile
        ? 15.0 // 기존 여백(약 19.0)의 절반 수준으로 줄여서 가로를 더 늘립니다.
        : _getResponsiveSize(context, isKiosk ? 56.0 : 38.0);
    final verticalPadding =
        isMobile ? 10.0 : _getResponsiveSize(context, isKiosk ? 80.0 : 38.0);
    final contentScale = isMobile ? 1.0 : (isKiosk ? 1.0 : 0.7);
    final fontSize = _getResponsiveSize(context, 42 * contentScale);
    final iconSize = _getResponsiveSize(context, 60 * contentScale);
    final gap = _getResponsiveSize(context, 10 * contentScale);
    final borderRadius = isMobile ? 12.0 : _getResponsiveSize(context, 40);
    final buttonWidth = screenWidth - (horizontalPadding * 2);
    final gaugeHeight = widget.height == double.infinity
        ? double.infinity
        : (widget.height - (verticalPadding * 2)).clamp(0.0, double.infinity);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: GestureDetector(
        onTap: widget.onHomePressed,
        child: Container(
          width: buttonWidth,
          height: gaugeHeight,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: buttonWidth * _actualProgress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [
                          0.0,
                          0.2,
                          0.4,
                          0.5,
                          0.6,
                          0.7,
                          0.8,
                          0.85,
                          0.9,
                          0.95,
                          1.0,
                        ],
                        colors: const [
                          Color(0xFF585BA6),
                          Color(0xFF3389CA),
                          Color(0xFF228DCE),
                          Color(0xFF268FCF),
                          Color(0xFF3596D2),
                          Color(0xFF3596D2),
                          Color(0xFF4CA2D7),
                          Color(0xFF6DB3DE),
                          Color(0xFF97C9E8),
                          Color(0xFFCAE4F3),
                          Color(0xFFCAE4F3),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: isMobile
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                _actualProgress >= 0.5
                                    ? Colors.white
                                    : Colors.black,
                                BlendMode.srcIn,
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/home_btn.svg',
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Text(
                              AppLocalizations.of(context)!.homeScreen,
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: fontSize,
                                fontVariations: const <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                                color: _actualProgress >= 0.5
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                _actualProgress >= 0.5
                                    ? Colors.white
                                    : Colors.black,
                                BlendMode.srcIn,
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/home_btn.svg',
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(height: gap),
                            Text(
                              AppLocalizations.of(context)!.homeScreen,
                              style: TextStyle(
                                fontFamily: AppTextStyles.bodyFontFamily,
                                fontSize: fontSize,
                                fontVariations: const <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                                color: _actualProgress >= 0.5
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
