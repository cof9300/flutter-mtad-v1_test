import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/measurement_footer.dart';
import 'package:flutter_template/features/measurement/screen/blood_pressure_result_screen_new.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/screen/alco_result_screen.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';

class MeasurementScreen extends ConsumerStatefulWidget {
  final String deviceType;

  const MeasurementScreen({
    super.key,
    required this.deviceType,
  });

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen>
    with AutoReturnMixin, RouteAware {
  static int _instanceCounter = 0;
  late final int _instanceId;
  DevicePageOptionResponse? _pageOption;
  bool _isLoading = true;
  int _mediaKey = 0;
  bool _isDemoMode = false;
  bool _isVideoActive = true;

  String get _topPlayerId => 'measurement_top_i$_instanceId';
  String get _bottomPlayerId => 'measurement_bottom_i$_instanceId';

  @override
  void initState() {
    super.initState();
    _instanceId = _instanceCounter++;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
    FlutterErrorLogger.logInfo(
        '[혈압측정] 측정 화면 진입 - DeviceType: ${widget.deviceType}, InstanceId: $_instanceId');
    MeasurementListener().startListening();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPageOption();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    cancelAutoReturnTimer();
    if (mounted) setState(() => _isVideoActive = false);
  }

  @override
  void didPopNext() {
    if (mounted) {
      if (_pageOption != null) {
        if (_pageOption!.waittime > 0) {
          startAutoReturnTimer(_pageOption!.waittime);
        }
        setState(() {
          _isVideoActive = true;
          _mediaKey++;
        });
      } else {
        setState(() => _isVideoActive = true);
      }
    }
  }

  Future<void> _loadPageOption() async {
    try {
      if (mounted) {
        ProgressModal.show(context);
      }

      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final effectiveType = (widget.deviceType.toUpperCase() == 'AMP' || widget.deviceType.toUpperCase() == 'BP_AMP')
          ? 'BP'
          : widget.deviceType;

      final option = ServiceLocator()
          .contentStorageService
          .getStoredDevicePageOption(effectiveType);

      if (option == null) {
        throw Exception('Device page option not found in storage');
      }

      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final isDemoMode = kioskOption?.demo == 1;

      if (mounted) {
        ProgressModal.hide();
        final l10n = AppLocalizations.of(context)!;
        final title = (effectiveType.toUpperCase() == 'BP')
            ? l10n.bloodPressureMeasurementGuide
            : effectiveType.toUpperCase() == 'HS'
                ? '신장체중 ${l10n.measurementGuide}'
                : effectiveType.toUpperCase() == 'ST'
                    ? '자율신경측정 안내'
                    : '${effectiveType.toUpperCase()} ${l10n.measurementGuide}';
        ref.read(headerTitleProvider.notifier).setTitle(title);

        setState(() {
          _pageOption = option;
          _isDemoMode = isDemoMode;
          _isLoading = false;
        });

        if (option.waittime > 0) {
          startAutoReturnTimer(option.waittime);
        }
      }
    } catch (e) {
      if (mounted) {
        ProgressModal.hide();

        final l10n = AppLocalizations.of(context)!;
        final title = widget.deviceType.toUpperCase() == 'BP'
            ? l10n.bloodPressureMeasurementGuide
            : widget.deviceType.toUpperCase() == 'HS'
                ? '신장체중 ${l10n.measurementGuide}'
                : widget.deviceType.toUpperCase() == 'ST'
                    ? '자율신경측정 안내'
                    : '${widget.deviceType.toUpperCase()} ${l10n.measurementGuide}';
        ref.read(headerTitleProvider.notifier).setTitle(title);

        setState(() {
          _pageOption = DevicePageOptionResponse(
            cm: [],
            menual: [],
            waittime: 120,
          );
          _isLoading = false;
        });

        startAutoReturnTimer(120);
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancelAutoReturnTimer();

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    super.dispose();
  }

  void _handleHomeButton(BuildContext context) {
    FlutterErrorLogger.logInfo('[화면이동] 측정 화면에서 홈 버튼 클릭');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _navigateToDemoResult() {
    final deviceUpper = widget.deviceType.toUpperCase();
    if (deviceUpper == 'BP' || deviceUpper == 'AMP' || deviceUpper == 'BP_AMP') {
      final demoResult = BloodPressureResult(
        systolic: 120,
        diastolic: 80,
        pulse: 75,
        measuredAt: DateTime.now(),
        deviceModel: '에이엠피올 (BP868F)',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BloodPressureResultScreenNew(result: demoResult),
        ),
      );
    } else if (deviceUpper == 'AL' || deviceUpper == 'ALCO') {
      final demoResult = AlcoMeasurementResult(
        isSuccess: true,
        bacValue: 0.000,
        isPass: true,
        errorCode: 0,
        measuredAt: DateTime.now(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlcoResultScreen(result: demoResult),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isLoading || _pageOption == null) {
      return CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final isMobile = screenWidth < 600;
                  final bottomVideoWidth = screenWidth;

                  final rawTopVideoHeight = screenWidth * 3 / 4;
                  final rawBottomVideoHeight = bottomVideoWidth * 9 / 16;
                  final rawTotalVideo =
                      rawTopVideoHeight + rawBottomVideoHeight;

                  final minFooterHeight =
                      (availableHeight * 0.12).clamp(80.0, 200.0);
                  final maxTotalVideo = availableHeight - minFooterHeight;

                  final double topVideoHeight;
                  final double bottomVideoMaxHeight;

                  if (isMobile) {
                    topVideoHeight = screenWidth * 3 / 4;
                    bottomVideoMaxHeight = screenWidth * 9 / 16;
                  } else {
                    if (rawTotalVideo <= maxTotalVideo) {
                      topVideoHeight = rawTopVideoHeight;
                      bottomVideoMaxHeight = rawBottomVideoHeight;
                    } else {
                      final scale = maxTotalVideo / rawTotalVideo;
                      topVideoHeight = rawTopVideoHeight * scale;
                      bottomVideoMaxHeight = rawBottomVideoHeight * scale;
                    }
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: topVideoHeight,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth,
                              maxHeight: topVideoHeight,
                            ),
                            child: _pageOption!.menual.isNotEmpty
                                ? MeasurementMediaPlayer(
                                    key: ValueKey(
                                        'top_${_instanceId}_$_mediaKey'),
                                    mediaItems: _pageOption!.menual,
                                    baseUrl: Config.baseUrl,
                                    playerId: _topPlayerId,
                                    isActive: _isVideoActive,
                                  )
                                : Container(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: bottomVideoMaxHeight,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: bottomVideoWidth,
                              maxHeight: bottomVideoMaxHeight,
                            ),
                            child: _pageOption!.cm.isNotEmpty
                                ? MeasurementMediaPlayer(
                                    key: ValueKey(
                                        'bottom_${_instanceId}_$_mediaKey'),
                                    mediaItems: _pageOption!.cm,
                                    baseUrl: Config.baseUrl,
                                    playerId: _bottomPlayerId,
                                    isActive: _isVideoActive,
                                  )
                                : Container(color: Colors.black),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, footerConstraints) {
                            final isMobile = screenWidth < 600;
                            double getResponsiveSize(double baseSize) {
                              final baseWidth = 1080.0;
                              return (screenWidth / baseWidth * baseSize)
                                  .clamp(baseSize * 0.5, baseSize * 1.5);
                            }

                            final double footerHeight = isMobile
                                ? getResponsiveSize(250.0)
                                : double.infinity;

                            return Align(
                              alignment: isMobile
                                  ? Alignment.center
                                  : Alignment.bottomCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: isMobile ? 0.0 : 0.0),
                                child: SizedBox(
                                  height: footerHeight,
                                  child: MeasurementFooter(
                                    key: ValueKey(
                                        'footer_${_instanceId}_$_mediaKey'),
                                    height: footerHeight,
                                    onHomePressed: () =>
                                        _handleHomeButton(context),
                                    waitTimeSeconds: _pageOption!.waittime,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_isDemoMode || widget.deviceType.toUpperCase() == 'AMP' || widget.deviceType.toUpperCase() == 'BP_AMP')
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _navigateToDemoResult,
                    child: Container(
                      padding: screenWidth < 600
                          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                          : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: (widget.deviceType.toUpperCase() == 'AMP' || widget.deviceType.toUpperCase() == 'BP_AMP')
                            ? const Color(0xFF0066FF).withOpacity(0.9)
                            : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth < 600 ? 6 : 10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: screenWidth < 600 ? 14 : 22,
                          ),
                          SizedBox(width: screenWidth < 600 ? 4 : 8),
                          Text(
                            (widget.deviceType.toUpperCase() == 'AMP' || widget.deviceType.toUpperCase() == 'BP_AMP')
                                ? 'AMP 데모 측정 테스트'
                                : 'DEMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 600 ? 11 : 15,
                              fontVariations: const <FontVariation>[
                                FontVariation('wght', 700)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
