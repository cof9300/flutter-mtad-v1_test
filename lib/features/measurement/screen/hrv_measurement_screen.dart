import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/info_modal.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';
import 'package:flutter_template/features/measurement/parser/hrv_frame.dart';
import 'package:flutter_template/features/measurement/screen/hrv_result_screen.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/features/measurement/widget/measurement_footer.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/hrv_user_info_notifier.dart';
import 'package:flutter_template/main.dart';

/// 자율신경계(HRV) 측정 화면.
/// 혈압/음주 측정 화면과 동일하게 상단/하단 영상(콘텐츠, device: 'ST')을 보여주며,
/// 화면 진입 시 자동으로 측정을 시작한다(미리보기 10초 + 측정 60초).
/// 측정이 완료되면 결과 화면으로 이동한다.
class HrvMeasurementScreen extends ConsumerStatefulWidget {
  const HrvMeasurementScreen({super.key});

  @override
  ConsumerState<HrvMeasurementScreen> createState() =>
      _HrvMeasurementScreenState();
}

class _HrvMeasurementScreenState extends ConsumerState<HrvMeasurementScreen>
    with AutoReturnMixin, RouteAware {
  static const String _deviceType = 'ST';
  static const int _previewTime = 10;
  static const int _measureTime = 60;
  int get _totalSeconds => _previewTime + _measureTime;

  static int _instanceCounter = 0;
  late final int _instanceId;

  DevicePageOptionResponse? _pageOption;
  bool _isLoading = true;
  bool _isVideoActive = true;
  int _mediaKey = 0;

  bool _navigated = false;
  StreamSubscription<HrvBasicResult>? _resultSub;
  StreamSubscription<int>? _errorSub;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _instanceId = _instanceCounter++;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
    FlutterErrorLogger.logInfo('[자율신경측정] 측정 화면 진입');
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
          .getStoredDevicePageOption(_deviceType);

      if (option == null) {
        final token = await ServiceLocator().tokenStorage.getToken();
        if (token != null) {
          option = await ServiceLocator().authRepository.getDevicePageOption(
            token: token,
            device: _deviceType,
          );
          await ServiceLocator()
              .contentStorageService
              .saveDevicePageOption(_deviceType, option);
        }
      }

      if (mounted) {
        ProgressModal.hide();
        ref.read(headerTitleProvider.notifier).setTitle('자율신경측정');
        setState(() {
          _pageOption = option ??
              DevicePageOptionResponse(cm: [], menual: [], waittime: 120);
          _isLoading = false;
        });
      }
    } catch (e) {
      FlutterErrorLogger.logError('[자율신경측정] 페이지 옵션 로드 실패', e);
      if (mounted) {
        ProgressModal.hide();
        ref.read(headerTitleProvider.notifier).setTitle('자율신경측정');
        setState(() {
          _pageOption =
              DevicePageOptionResponse(cm: [], menual: [], waittime: 120);
          _isLoading = false;
        });
      }
    }

    _startMeasurement();
  }

  Future<void> _startMeasurement() async {
    final userInfo = ref.read(hrvUserInfoProvider);
    final gender = userInfo?.gender == 'F'
        ? HrvGenderCode.female
        : HrvGenderCode.male;
    final age = (userInfo?.age ?? 30).clamp(5, 80);

    FlutterErrorLogger.logInfo(
        '[자율신경측정] 측정 시작 요청 - Gender: ${userInfo?.gender}, Age: $age');

    MeasurementListener().startListening();

    _resultSub = MeasurementListener().hrvResultStream.listen(_onResult);
    _errorSub = MeasurementListener().hrvErrorStream.listen(_onError);

    // 기기가 포트 오픈 직후라면 안정화될 시간을 약간 준다.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final started = await MeasurementListener().startHrvMeasurement(
      _deviceType,
      previewTime: _previewTime,
      measureTime: _measureTime,
      sensorType: HrvSensorType.finger,
      gender: gender,
      age: age,
      referenceType: HrvReferenceType.asian,
    );

    if (!started) {
      FlutterErrorLogger.logWarning('[자율신경측정] 측정 시작 명령 전송 실패');
      _showErrorAndReturn('기기와 연결할 수 없습니다.\n다시 시도해주세요.');
      return;
    }

    // 측정 완료 후에도 기기 응답이 지연될 경우를 대비한 안전 타임아웃.
    _safetyTimer = Timer(Duration(seconds: _totalSeconds + 20), () {
      if (!mounted || _navigated) return;
      FlutterErrorLogger.logWarning('[자율신경측정] 결과 수신 타임아웃');
      _showErrorAndReturn('측정 결과를 받지 못했습니다.\n다시 시도해주세요.');
    });
  }

  void _onError(int code) {
    if (!mounted || _navigated) return;
    if (code == HrvErrorCode.startError ||
        code == HrvErrorCode.signalError ||
        code == HrvErrorCode.noResult) {
      final message = code == HrvErrorCode.signalError
          ? '측정 신호가 불안정합니다.\n손가락을 센서에 올바르게 올려주세요.'
          : '측정 중 오류가 발생했습니다.\n다시 시도해주세요.';
      _showErrorAndReturn(message);
    }
  }

  void _onResult(HrvBasicResult result) {
    if (_navigated) return;
    _navigated = true;
    _safetyTimer?.cancel();
    FlutterErrorLogger.logInfo(
        '[자율신경측정] 측정 완료 - 종합점수: ${result.totalScore.toStringAsFixed(1)}');

    final measurementResult = HrvMeasurementResult(
      basic: result,
      measuredAt: DateTime.now(),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HrvResultScreen(result: measurementResult),
      ),
    );
  }

  void _showErrorAndReturn(String message) {
    _navigated = true;
    if (!mounted) return;
    InfoModal.show(context, title: '오류', message: message);
    Future.delayed(const Duration(seconds: 3), () {
      InfoModal.hide();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  void _handleHomeButton() {
    FlutterErrorLogger.logInfo('[화면이동] 자율신경측정 화면에서 홈 버튼 클릭');
    unawaited(MeasurementListener().stopHrvMeasurement(_deviceType));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancelAutoReturnTimer();
    _resultSub?.cancel();
    _errorSub?.cancel();
    _safetyTimer?.cancel();
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

    return CommonLayout(
      child: Container(
        decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            final rawTopVideoHeight = screenWidth * 3 / 4;
            final rawBottomVideoHeight = screenWidth * 9 / 16;
            final rawTotalVideo = rawTopVideoHeight + rawBottomVideoHeight;

            final minFooterHeight =
                (availableHeight * 0.12).clamp(80.0, 200.0);
            final maxTotalVideo = availableHeight - minFooterHeight;

            final double topVideoHeight;
            final double bottomVideoMaxHeight;

            if (rawTotalVideo <= maxTotalVideo) {
              topVideoHeight = rawTopVideoHeight;
              bottomVideoMaxHeight = rawBottomVideoHeight;
            } else {
              final scale = maxTotalVideo / rawTotalVideo;
              topVideoHeight = rawTopVideoHeight * scale;
              bottomVideoMaxHeight = rawBottomVideoHeight * scale;
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
                                  'hrv_top_${_instanceId}_$_mediaKey'),
                              mediaItems: _pageOption!.menual,
                              baseUrl: Config.baseUrl,
                              playerId: 'hrv_top_$_instanceId',
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
                                  'hrv_bottom_${_instanceId}_$_mediaKey'),
                              mediaItems: _pageOption!.cm,
                              baseUrl: Config.baseUrl,
                              playerId: 'hrv_bottom_$_instanceId',
                              isActive: _isVideoActive,
                            )
                          : Container(color: Colors.black),
                    ),
                  ),
                ),
                Expanded(
                  child: MeasurementFooter(
                    key: ValueKey('hrv_footer_${_instanceId}_$_mediaKey'),
                    height: double.infinity,
                    onHomePressed: _handleHomeButton,
                    waitTimeSeconds: _totalSeconds,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
