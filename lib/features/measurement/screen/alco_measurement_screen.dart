import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/alco_bluetooth_constants.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/features/measurement/screen/alco_result_screen.dart';
import 'package:flutter_template/features/measurement/widget/measurement_footer.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';

class AlcoMeasurementScreen extends ConsumerStatefulWidget {
  const AlcoMeasurementScreen({super.key});

  @override
  ConsumerState<AlcoMeasurementScreen> createState() =>
      _AlcoMeasurementScreenState();
}

class _AlcoMeasurementScreenState extends ConsumerState<AlcoMeasurementScreen>
    with AutoReturnMixin, RouteAware {
  static int _instanceCounter = 0;
  late final int _instanceId;

  DevicePageOptionResponse? _pageOption;
  bool _isLoading = true;
  bool _isVideoActive = true;
  int _mediaKey = 0;
  bool _isDemoMode = false;

  StreamSubscription<AlcoNotification>? _notificationSubscription;
  bool _isNavigating = false;
  bool _measurementCycleStarted = false;
  int _lastNonZeroBacRaw = 0;
  // AF-50U 기기는 WAIT_BLOWING 구간에 이전 측정의 BAC값을 stale하게 유지한다.
  // WAIT_BLOWING rawBac와 이후 0x17/0x07 rawBac를 비교해 실제 새 측정값인지 판별한다.
  int _waitBlowingBacRaw = 0;
  int _currentStateCode = 0;
  @override
  void initState() {
    super.initState();
    _instanceId = _instanceCounter++;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
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
      if (_pageOption != null && _pageOption!.waittime > 0) {
        startAutoReturnTimer(_pageOption!.waittime);
      }
      setState(() {
        _isVideoActive = true;
        _mediaKey++;
      });
    }
  }

  Future<void> _loadPageOption() async {
    try {
      if (mounted) ProgressModal.show(context);

      DevicePageOptionResponse? option = ServiceLocator()
          .contentStorageService
          .getStoredDevicePageOption('AL');

      if (option == null) {
        final token = await ServiceLocator().tokenStorage.getToken();
        if (token != null) {
          option = await ServiceLocator().authRepository.getDevicePageOption(
            token: token,
            device: 'AL',
          );
          await ServiceLocator()
              .contentStorageService
              .saveDevicePageOption('AL', option);
        }
      }

      if (mounted) {
        ProgressModal.hide();
        ref.read(headerTitleProvider.notifier).setTitle('음주측정 안내');

        final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
        final isDemoMode = kioskOption?.demo == 1;

        setState(() {
          _pageOption = option ??
              DevicePageOptionResponse(cm: [], menual: [], waittime: 120);
          _isDemoMode = isDemoMode;
          _isLoading = false;
        });
        if (_pageOption!.waittime > 0) {
          startAutoReturnTimer(_pageOption!.waittime);
        }
      }
    } catch (e) {
      FlutterErrorLogger.logError('[AlcoMeasurement] 페이지 옵션 로드 실패', e);
      if (mounted) {
        ProgressModal.hide();
        ref.read(headerTitleProvider.notifier).setTitle('음주측정 안내');
        setState(() {
          _pageOption =
              DevicePageOptionResponse(cm: [], menual: [], waittime: 120);
          _isLoading = false;
        });
        startAutoReturnTimer(120);
      }
    }

    _startMeasurement();
  }

  Future<void> _startMeasurement() async {
    final usbService = ServiceLocator().alcoUsbService;
    final bleService = ServiceLocator().alcoBleService;

    _measurementCycleStarted = false;
    _isNavigating = false;
    _lastNonZeroBacRaw = 0;
    _waitBlowingBacRaw = 0;

    FlutterErrorLogger.logInfo('${LogCategory.alco} ━━ 음주측정 시작 (instanceId:$_instanceId)');

    if (usbService.isConnected) {
      FlutterErrorLogger.logInfo('${LogCategory.alco} USB 기기 이미 연결됨 — 재연결 생략');
    } else {
      FlutterErrorLogger.logInfo('${LogCategory.alco} USB 기기 미연결 — 연결 시도');
      await usbService.tryConnectSavedDevice();
    }

    if (usbService.isConnected) {
      FlutterErrorLogger.logInfo('${LogCategory.alco} USB 기기 연결 확인 → USB 측정 경로 진입');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _notificationSubscription?.cancel();
      _notificationSubscription =
          usbService.alcoNotificationStream.listen(_handleNotification);
      await _trySendWarmUpCommand(usbService);
    } else if (bleService.isConnected) {
      FlutterErrorLogger.logInfo('${LogCategory.alco} USB 미연결 → BLE 기기 연결 확인 → BLE 측정 경로 진입');
      _notificationSubscription =
          bleService.alcoNotificationStream.listen(_handleNotification);
      await _trySendWarmUpCommand(bleService);
    } else {
      FlutterErrorLogger.logWarning('${LogCategory.alco} USB/BLE 기기 모두 미연결 — 측정 불가');
    }
  }

  Future<void> _trySendWarmUpCommand(dynamic service,
      {int retries = 3}) async {
    FlutterErrorLogger.logInfo('${LogCategory.alco} WarmUp 명령 전송 시도 (최대 ${retries}회)');
    for (int i = 0; i < retries; i++) {
      try {
        await service.sendWarmUpCommand();
        FlutterErrorLogger.logInfo('${LogCategory.alco} WarmUp 전송 성공 (${i + 1}/${retries}회)');
        return;
      } catch (e) {
        FlutterErrorLogger.logWarning(
            '${LogCategory.alco} WarmUp 전송 실패 (${i + 1}/$retries): $e');
        if (i < retries - 1) {
          FlutterErrorLogger.logInfo('${LogCategory.alco} ${800}ms 후 재시도...');
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    }
    FlutterErrorLogger.logWarning('${LogCategory.alco} WarmUp 전송 ${retries}회 모두 실패');
  }

  void _handleNotification(AlcoNotification notification) {
    if (!mounted || _isNavigating) return;

    final state = notification.stateCode;
    final stateHex = '0x${state.toRadixString(16)}';

    if (notification.rawBacValue > 0) {
      if (state == AlcoBluetoothConstants.stateWaitBlowing) {
        // WAIT_BLOWING 구간의 BAC는 이전 측정의 stale값이므로 결과에 사용하지 않는다.
        // 단, 이후 블로잉 단계에서 "값이 바뀌었는지" 비교하기 위해 기준값으로 기록한다.
        _waitBlowingBacRaw = notification.rawBacValue;
        FlutterErrorLogger.logInfo(
          '${LogCategory.alco} WAIT_BLOWING BAC 감지 — stale 기준값 기록: $_waitBlowingBacRaw (이전 측정값, 결과 미사용)',
        );
      } else if (notification.rawBacValue != _waitBlowingBacRaw) {
        // WAIT_BLOWING 기준값과 다른 값 → 현재 측정에서 새로 감지된 BAC
        _lastNonZeroBacRaw = notification.rawBacValue;
        FlutterErrorLogger.logInfo(
          '${LogCategory.alco} BAC 업데이트 — state:$stateHex rawBac:$_lastNonZeroBacRaw (기준값 $_waitBlowingBacRaw 에서 변경)',
        );
      } else {
        // WAIT_BLOWING 기준값과 동일 → stale값, 무시
        FlutterErrorLogger.logInfo(
          '${LogCategory.alco} BAC 감지 — state:$stateHex rawBac:${notification.rawBacValue} (WAIT_BLOWING 기준값 $_waitBlowingBacRaw 과 동일, stale로 판단 무시)',
        );
      }
    }

    final prevState = _currentStateCode;

    if (prevState != state) {
      if (state == AlcoBluetoothConstants.stateWarmUp) {
        FlutterErrorLogger.logInfo('${LogCategory.alco} ━━ 상태: 예열 중 (WARM_UP) — warmUpEstMs:${notification.warmUpEstimatedMs}');
      } else if (state == AlcoBluetoothConstants.stateWaitBlowing) {
        FlutterErrorLogger.logInfo('${LogCategory.alco} ━━ 상태: 불기 대기 (WAIT_BLOWING)');
      } else if (state == AlcoBluetoothConstants.stateBlowing) {
        FlutterErrorLogger.logInfo('${LogCategory.alco} ━━ 상태: 불기 중 (BLOWING)');
      } else if (state == AlcoBluetoothConstants.stateAnalyzing) {
        FlutterErrorLogger.logInfo('${LogCategory.alco} ━━ 상태: 분석 중 (ANALYZING)');
      }
    }

    if (state == AlcoBluetoothConstants.stateWarmUp ||
        state == AlcoBluetoothConstants.stateWaitBlowing ||
        state == AlcoBluetoothConstants.stateBlowing ||
        state == AlcoBluetoothConstants.stateAnalyzing) {
      _measurementCycleStarted = true;
      cancelAutoReturnTimer();
    }

    if (mounted) {
      setState(() {
        _currentStateCode = state;
      });
    }

    if (state == AlcoBluetoothConstants.stateResult ||
        state == AlcoBluetoothConstants.stateError) {
      if (!_measurementCycleStarted) {
        FlutterErrorLogger.logWarning(
          '${LogCategory.alco} 결과 수신($stateHex)했지만 측정 사이클 미시작 — 이전 캐시로 판단, 무시',
        );
        return;
      }
      _isNavigating = true;
      cancelAutoReturnTimer();
      // 측정 완료 후 기기를 대기 상태로 복귀시켜 다음 측정 시 빠른 워밍업 가능하게 함
      ServiceLocator().alcoUsbService.sendStandbyCommand();

      final effectiveBacRaw = notification.rawBacValue > 0
          ? notification.rawBacValue
          : _lastNonZeroBacRaw;

      final effectiveNotification = effectiveBacRaw != notification.rawBacValue
          ? AlcoNotification(
              stateCode: notification.stateCode,
              battery: notification.battery,
              rawBacValue: effectiveBacRaw,
              errorCode: notification.errorCode,
              calibDays: notification.calibDays,
              warmUpEstimatedCentiseconds: notification.warmUpEstimatedCentiseconds,
              deviceModeCode: notification.deviceModeCode,
            )
          : notification;

      final result = AlcoMeasurementResult.fromNotification(effectiveNotification);
      FlutterErrorLogger.logInfo(
        '${LogCategory.alco} ━━ 측정 완료 — 상태:$stateHex isPass:${result.isPass} bac:${result.bacValueText} effectiveRaw:$effectiveBacRaw',
      );
      if (state == AlcoBluetoothConstants.stateError) {
        FlutterErrorLogger.logWarning(
          '${LogCategory.alco} 오류 상태로 측정 종료 — errorCode:0x${notification.errorCode.toRadixString(16)}',
        );
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AlcoResultScreen(result: result),
          ),
        );
      }
    }
  }

  void _navigateToDemoResult() {
    final demoResult = AlcoMeasurementResult(
      isSuccess: true,
      bacValue: 0.051,
      isPass: false,
      errorCode: 0,
      measuredAt: DateTime.now(),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AlcoResultScreen(result: demoResult),
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancelAutoReturnTimer();
    _notificationSubscription?.cancel();
    // 측정 화면 이탈 시 기기를 항상 대기 상태로 복귀 (연결은 유지)
    ServiceLocator().alcoUsbService.sendStandbyCommand();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pageOption == null) {
      return CommonLayout(
        child: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final isMobile = screenWidth < 600;

                  final rawTopVideoHeight = screenWidth * 3 / 4;
                  final rawBottomVideoHeight = screenWidth * 9 / 16;
                  final rawTotalVideo = rawTopVideoHeight + rawBottomVideoHeight;

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
                                        'alco_top_${_instanceId}_$_mediaKey'),
                                    mediaItems: _pageOption!.menual,
                                    baseUrl: Config.baseUrl,
                                    playerId: 'alco_top_${_instanceId}',
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
                              maxWidth: screenWidth,
                              maxHeight: bottomVideoMaxHeight,
                            ),
                            child: _pageOption!.cm.isNotEmpty
                                ? MeasurementMediaPlayer(
                                    key: ValueKey(
                                        'alco_bottom_${_instanceId}_$_mediaKey'),
                                    mediaItems: _pageOption!.cm,
                                    baseUrl: Config.baseUrl,
                                    playerId: 'alco_bottom_${_instanceId}',
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
                                        'alco_footer_${_instanceId}_$_mediaKey'),
                                    height: footerHeight,
                                    onHomePressed: () =>
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst),
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
              if (_isDemoMode)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _navigateToDemoResult,
                    child: Container(
                      padding: screenWidth < 600
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                          : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth < 600 ? 4 : 8),
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
                            size: screenWidth < 600 ? 12 : 20,
                          ),
                          SizedBox(width: screenWidth < 600 ? 3 : 6),
                          Text(
                            'DEMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 600 ? 10 : 14,
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

