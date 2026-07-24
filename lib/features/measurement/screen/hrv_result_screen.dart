import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';
import 'package:flutter_template/features/measurement/screen/hrv_measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/measurement/widget/hrv_radar_chart.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/core/utils/hrv_result_calculator.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/main.dart';

/// 자율신경계(HRV) 측정 결과 화면.
/// Figma: 자율신경측정 결과 (node-id 851:304)
class HrvResultScreen extends ConsumerStatefulWidget {
  final HrvMeasurementResult result;

  const HrvResultScreen({super.key, required this.result});

  @override
  ConsumerState<HrvResultScreen> createState() => _HrvResultScreenState();
}

class _HrvResultScreenState extends ConsumerState<HrvResultScreen>
    with AutoReturnMixin, RouteAware {
  bool _isHidden = false;
  bool _isVideoActive = true;
  int _videoKey = 0;

  static const Color _stepVeryBad = Color(0xFFA52748);
  static const Color _stepBad = Color(0xFFDECD5A);
  static const Color _stepNormal = Color(0xFF7EBA68);
  static const Color _stepGood = Color(0xFF699ECD);
  static const Color _stepVeryGood = Color(0xFF8C79AB);

  static const List<Color> _zoneColors5 = [
    _stepVeryBad,
    _stepBad,
    _stepNormal,
    _stepGood,
    _stepVeryGood,
  ];

  static const List<Color> _zoneColors3 = [_stepBad, _stepNormal, _stepGood];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
    FlutterErrorLogger.logInfo(
        '[자율신경측정] 결과 화면 진입 - 종합점수: ${widget.result.basic.totalScore.toStringAsFixed(1)}');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(headerTitleProvider.notifier).setTitle('자율신경측정 결과');

      final pageOption = ref.read(resultPageOptionProvider);
      final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
      if (pageOption != null && mounted) {
        setState(() {
          _isHidden = guestMeasureFlag ? false : pageOption.masking;
        });
      }

      await _saveMeasurementResult();

      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final resulttime = kioskOption?.resulttime ?? 120;
      if (mounted && resulttime > 0) {
        startAutoReturnTimer(resulttime);
      }
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
        _videoKey++;
      });
    }
    _restartTimerAfterAuth();
  }

  Future<void> _restartTimerAfterAuth() async {
    if (!mounted) return;
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    final resulttime = kioskOption?.resulttime ?? 120;
    if (resulttime > 0 && mounted) {
      startAutoReturnTimer(resulttime);
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

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  // ─── 결과 저장 (set-result API, device: 'ST') ──────────────────────────

  Future<void> _saveMeasurementResult() async {
    try {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final measureId = ref.read(measureIdProvider);
      final userAuth = ref.read(userAuthProvider);

      if (kioskOption == null) {
        FlutterErrorLogger.logWarning('[자율신경측정결과] KioskOption 없음');
        return;
      }

      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        FlutterErrorLogger.logWarning('[자율신경측정결과] Token 없음');
        return;
      }

      final result = HrvResultCalculator.createResultData(
        result: widget.result.basic,
        measuredAt: widget.result.measuredAt,
      );

      FlutterErrorLogger.logInfo(
          '[자율신경측정결과] 저장 시작 - Mode: ${kioskOption.mode}, 종합점수: ${widget.result.basic.totalScore.toStringAsFixed(1)}');

      if (kioskOption.mode == 1) {
        if (kioskOption.usecert == 1) {
          final verifiedUserData =
              await ServiceLocator().verifiedUserStorage.getAllData();
          final verifiedPhone = verifiedUserData['phoneNumber'];
          final verifiedBirthday = verifiedUserData['birthday'];
          final verifiedGender = verifiedUserData['gender'];

          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'ST',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            if (verifiedPhone != null &&
                verifiedPhone.isNotEmpty &&
                verifiedBirthday != null &&
                verifiedBirthday.isNotEmpty &&
                verifiedGender != null &&
                verifiedGender.isNotEmpty) {
              try {
                await ServiceLocator().authRepository.updateResultUser(
                      token: token,
                      measureid: finalMeasureId,
                      userid: verifiedPhone,
                      type: 'PHONE',
                      birth: verifiedBirthday,
                      gender: verifiedGender,
                    );
              } catch (e) {
                FlutterErrorLogger.logError('[자율신경측정결과] updateResultUser 실패', e);
              }
            }
          }
          return;
        } else if (kioskOption.usecert == 2) {
          final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();

          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'ST',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            if (guestPhone != null && guestPhone.isNotEmpty) {
              try {
                await ServiceLocator().authRepository.updateResultUser(
                      token: token,
                      measureid: finalMeasureId,
                      userid: guestPhone,
                      type: 'PHONE',
                      birth: null,
                      gender: null,
                    );
              } catch (e) {
                FlutterErrorLogger.logError('[자율신경측정결과] updateResultUser 실패', e);
              }
            }
          }
          return;
        }
      } else {
        // mode == 2 (게스트 모드)
        final targetMeasureId =
            userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty
                ? userAuth.measureid!
                : (measureId ?? '');
        final isAuthenticated =
            userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;

        final setResultResponse = await ServiceLocator().authRepository.setResult(
              token: token,
              measureid: isAuthenticated ? targetMeasureId : '',
              device: 'ST',
              result: result,
              serviceforce: 'true',
            );

        final finalMeasureId = setResultResponse.measureid != null &&
                setResultResponse.measureid!.isNotEmpty
            ? setResultResponse.measureid!
            : targetMeasureId;

        if (finalMeasureId.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
          FlutterErrorLogger.logInfo('[자율신경측정결과] 저장 성공 MeasureId: $finalMeasureId');
        }
      }
    } catch (e) {
      FlutterErrorLogger.logError('[자율신경측정결과] 저장 오류', e);
    }
  }

  // ─── 버튼 동작 ──────────────────────────────────────────────────────────

  void _handleHomeButton() {
    FlutterErrorLogger.logInfo('[화면이동] 자율신경측정 결과 화면에서 홈 버튼 클릭');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleHideResult() {
    setState(() => _isHidden = !_isHidden);
    if (!_isHidden) resetCurrentTimer();
  }

  void _handleRetry() {
    FlutterErrorLogger.logInfo('[자율신경측정] 재측정 버튼 클릭');
    final devices = ref.read(deviceListWithConnectionProvider);
    final connectedDevices = devices.where((d) => d.isConnected).toList();

    if (connectedDevices.length >= 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HrvMeasurementScreen()),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    FlutterErrorLogger.logInfo('[문자전송] 자율신경측정 결과 전송 버튼 클릭');

    final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
    if (guestMeasureFlag) {
      final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();
      if (guestPhone == null || guestPhone.isEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestPhoneInputScreen(hrvResult: widget.result),
            ),
          );
        }
        return;
      }
    }

    final userAuth = ref.read(userAuthProvider);
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();
    final verifiedUserData = await ServiceLocator().verifiedUserStorage.getAllData();
    final verifiedPhone = verifiedUserData['phoneNumber'];

    if (kioskOption == null || !mounted) return;

    final basic = widget.result.basic;
    final resultText = '''▶자율신경계
- 종합점수: ${basic.totalScore.toStringAsFixed(1)}점
- 자율신경 활성도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.tpScore))}
- 스트레스 대처능력: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.sdnnScore))}
- 피로도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.lfScore))}''';
    final dateText = DateFormat('yyyy.MM.dd HH:mm').format(widget.result.measuredAt);
    final isServiceMode = kioskOption.mode == 1;

    if (isServiceMode) {
      if (kioskOption.usecert == 1) {
        if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
          await _sendSmsAndShowSuccess(phoneNumber: verifiedPhone, resultText: resultText, dateText: dateText, place: kioskOption.place);
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthScreenWithBirthdayGender(hrvResult: widget.result),
            ),
          );
        }
        return;
      } else if (kioskOption.usecert == 2) {
        if (guestPhone != null && guestPhone.isNotEmpty) {
          await _sendSmsAndShowSuccess(phoneNumber: guestPhone, resultText: resultText, dateText: dateText, place: kioskOption.place);
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestPhoneInputScreen(hrvResult: widget.result),
            ),
          );
        }
        return;
      }
    }

    // mode 2 (게스트 모드)
    final hasUserAuthPhone = userAuth?.phonenumber != null && userAuth!.phonenumber!.isNotEmpty;
    final hasVerifiedPhone = verifiedPhone != null && verifiedPhone.isNotEmpty;
    final phoneNumber = hasVerifiedPhone ? verifiedPhone : (hasUserAuthPhone ? userAuth.phonenumber : null);

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _sendSmsAndShowSuccess(phoneNumber: phoneNumber, resultText: resultText, dateText: dateText, place: kioskOption.place);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuestPhoneInputScreen(hrvResult: widget.result),
        ),
      );
    }
  }

  Future<void> _sendSmsAndShowSuccess({
    required String phoneNumber,
    required String resultText,
    required String dateText,
    String? place,
  }) async {
    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) return;
      await ServiceLocator().authRepository.sendSms(
            token: token,
            type: 'RESULT_GUEST',
            phonenumber: phoneNumber,
            result: resultText,
            date: dateText,
            place: place,
          );
      FlutterErrorLogger.logInfo('[문자전송] 자율신경측정 결과 SMS 전송 성공');
      if (mounted) {
        SendResultSuccessModal.show(
          context,
          onConfirm: () {
            SendResultSuccessModal.hide(context);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    } catch (e) {
      FlutterErrorLogger.logError('[문자전송] 자율신경측정 결과 SMS 전송 실패', e);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 홈/결과숨김 버튼, 하단 액션 버튼은 항상 실제 크기로 고정 표시하고,
    // 그 사이에 남는 공간(가운데 영역)에 차트+영상 콘텐츠를 스크롤 없이
    // 딱 맞게(필요하면 축소해서) 채운다.
    final topReserved = _getResponsiveSize(context, 150);
    final bottomReserved = _getResponsiveSize(context, 340);

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final middleHeight =
                  (constraints.maxHeight - topReserved - bottomReserved)
                      .clamp(80.0, constraints.maxHeight);

              return Stack(
                children: [
                  Positioned(
                    top: topReserved,
                    left: 0,
                    right: 0,
                    height: middleHeight,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildResultTopSection(context),
                              SizedBox(
                                  height: _getResponsiveSize(context, 24)),
                              _buildVideoSection(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: HomeButton(
                      onTap: _handleHomeButton,
                      topPadding: _getResponsiveSize(context, 20),
                      leftPadding: _getResponsiveSize(context, 30),
                    ),
                  ),
                  Positioned(
                    top: _getResponsiveSize(context, 20),
                    right: _getResponsiveSize(context, 30),
                    child: _buildHideButton(context),
                  ),
                  Positioned(
                    bottom: _getResponsiveSize(context, 40),
                    left: 0,
                    right: 0,
                    child: _buildBottomButtons(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHideButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconPath =
        _isHidden ? 'assets/icons/show.svg' : 'assets/icons/hide.svg';
    final label = _isHidden ? l10n.resultShow : l10n.resultHidden;

    return GestureDetector(
      onTap: _toggleHideResult,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _getResponsiveSize(context, 80),
            height: _getResponsiveSize(context, 80),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EAF3),
              borderRadius: BorderRadius.circular(
                _getResponsiveSize(context, 40),
              ),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(context, 18)),
            child: SvgPicture.asset(
              iconPath,
              width: _getResponsiveSize(context, 44),
              height: _getResponsiveSize(context, 44),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 4)),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
              color: const Color(0xFF4C4948),
              letterSpacing: -0.7,
            ),
          ),
        ],
      ),
    );
  }

  /// 차트(결과 데이터) 영역과 잠금 안내 영역을 담당한다.
  /// 혈압/음주측정 결과화면과 동일한 UI를 사용한다.
  /// 차트는 숨김 상태에도 항상 동일하게 레이아웃되고(크기 유지) 시각적으로만
  /// 가려지므로, 숨김 토글 시 전체 화면 크기(FittedBox 스케일)가 흔들리는
  /// 버그 없이 상단 결과 영역만 정확히 교체된다.
  Widget _buildResultTopSection(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Opacity(
          opacity: _isHidden ? 0 : 1,
          child: IgnorePointer(
            ignoring: _isHidden,
            child: _buildChartsSection(context),
          ),
        ),
        if (_isHidden)
          Positioned.fill(
            child: Center(child: _buildHiddenContent(context)),
          ),
      ],
    );
  }

  Widget _buildHiddenContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lockSize = _getResponsiveSize(context, 240);
    final topSpace = _getResponsiveSize(context, 80);
    final bottomSpace = _getResponsiveSize(context, 120);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topSpace),
          SvgPicture.asset(
            'assets/images/hide_view.svg',
            width: lockSize,
            height: lockSize,
          ),
          SizedBox(height: _getResponsiveSize(context, 30)),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 40)),
            child: Text(
              l10n.resultHiddenGuide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 46),
                fontVariations: const <FontVariation>[FontVariation('wght', 700)],
                color: const Color(0xFF227EFF),
                letterSpacing: -1.6,
              ),
            ),
          ),
          SizedBox(height: bottomSpace),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 28)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildHrvChartGroup(context)),
            SizedBox(
              width: _getResponsiveSize(context, 2),
              child: Container(color: const Color(0xFFDADADA)),
            ),
            Expanded(child: _buildVascularChartGroup(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHrvChartGroup(BuildContext context) {
    final basic = widget.result.basic;
    final chartSize = _getResponsiveSize(context, 420);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _axisLabel(context, '신체적\n대처능력', HrvResultCalculator.step5(basic.psiScore))),
              Expanded(child: _axisLabel(context, '스트레스\n대처능력', HrvResultCalculator.step5(basic.sdnnScore))),
              Expanded(child: _axisLabel(context, '정신적\n스트레스', HrvResultCalculator.step5(basic.ratioScore))),
            ],
          ),
        ),
        HrvRadarChart(
          zoneColors: _zoneColors5,
          valueFractions: [
            basic.sdnnScore.clamp(0, 100) / 100,
            basic.ratioScore.clamp(0, 100) / 100,
            basic.meanHrScore.clamp(0, 100) / 100,
            basic.lfScore.clamp(0, 100) / 100,
            basic.psiScore.clamp(0, 100) / 100,
          ],
          size: chartSize,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _axisLabel(context, '피로도', HrvResultCalculator.step5(basic.lfScore))),
              Expanded(child: _axisLabel(context, '심박수', HrvResultCalculator.step5(basic.meanHrScore), isHeartRate: true)),
            ],
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 20)),
        _buildLegend(context, _zoneColors5, const ['매우나쁨', '나쁨', '정상', '좋음', '매우좋음']),
      ],
    );
  }

  Widget _buildVascularChartGroup(BuildContext context) {
    final basic = widget.result.basic;
    final chartSize = _getResponsiveSize(context, 420);
    // 대표 혈관 단계(1~7)는 기기가 직접 산출하는 값으로, 낮을수록 건강한 상태를
    // 의미한다. 3단계 색상 존(나쁨/보통/좋음) 차트 위에 표시하기 위해
    // 1~7 단계를 7등분하여 위치(fraction)만 매핑하고, 라벨은 "N단계" 그대로 쓴다.
    final vascularFraction =
        1 - ((basic.representativeVascularStage - 1).clamp(0, 6) / 6);

    return Column(
      children: [
        _vascularStageLabel(context, basic.representativeVascularStage),
        HrvRadarChart(
          zoneColors: _zoneColors3,
          valueFractions: [
            vascularFraction,
            basic.peripheralElasticityScore.clamp(0, 100) / 100,
            basic.arterialElasticityScore.clamp(0, 100) / 100,
          ],
          size: chartSize,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _elasticityAxisLabel(context, '동맥혈관\n탄성도', HrvResultCalculator.elasticityStep3(basic.arterialElasticityScore))),
              Expanded(child: _elasticityAxisLabel(context, '말초혈관\n탄성도', HrvResultCalculator.elasticityStep3(basic.peripheralElasticityScore))),
            ],
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 20)),
        _buildLegend(context, _zoneColors3, const ['표준이하', '표준', '표준이상']),
      ],
    );
  }

  /// 대표 혈관 단계(1~7)는 낮을수록 건강한 상태를 의미하므로,
  /// 1~2단계=표준이상, 3~5단계=표준, 6~7단계=표준이하 색상으로 표시한다.
  Widget _vascularStageLabel(BuildContext context, int stage) {
    final step3 = stage <= 2
        ? 3
        : stage <= 5
            ? 2
            : 1;
    final color = _zoneColors3[step3.clamp(1, 3) - 1];
    final label = HrvResultCalculator.vascularStageLabel(stage);
    return _axisLabelContent(context, '혈관단계', color, label);
  }

  Widget _elasticityAxisLabel(BuildContext context, String name, int step) {
    final color = _zoneColors3[step.clamp(1, 3) - 1];
    final label = HrvResultCalculator.elasticityStep3Label(step);
    return _axisLabelContent(context, name, color, label);
  }

  Widget _axisLabel(BuildContext context, String name, int step,
      {bool isHeartRate = false}) {
    final color = _zoneColors5[step.clamp(1, 5) - 1];
    final label = isHeartRate
        ? HrvResultCalculator.heartRateStep5Label(step)
        : HrvResultCalculator.step5Label(step);
    return _axisLabelContent(context, name, color, label);
  }

  Widget _axisLabelContent(
      BuildContext context, String name, Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
              fontVariations: const <FontVariation>[FontVariation('wght', 600)],
              color: const Color(0xFF111111),
              height: 1.25,
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _getResponsiveSize(context, 14),
                height: _getResponsiveSize(context, 14),
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              SizedBox(width: _getResponsiveSize(context, 5)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 19),
                  color: const Color(0xFF111111),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<Color> colors, List<String> labels) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _getResponsiveSize(context, 10),
      runSpacing: _getResponsiveSize(context, 6),
      children: List<Widget>.generate(colors.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _getResponsiveSize(context, 14),
              height: _getResponsiveSize(context, 14),
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i]),
            ),
            SizedBox(width: _getResponsiveSize(context, 4)),
            Text(
              labels[i],
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 19),
                color: const Color(0xFF111111),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    final pageOption = ref.read(resultPageOptionProvider);

    if (pageOption == null || pageOption.cm.isEmpty) {
      return SizedBox(
        width: _getResponsiveSize(context, 1024),
        height: _getResponsiveSize(context, 576),
      );
    }

    return SizedBox(
      width: _getResponsiveSize(context, 1024),
      height: _getResponsiveSize(context, 576),
      child: MeasurementMediaPlayer(
        key: ValueKey('hrv_result_video_$_videoKey'),
        mediaItems: pageOption.cm,
        baseUrl: Config.baseUrl,
        playerId: 'hrv_result_video',
        isActive: _isVideoActive,
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 28)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            context,
            icon: 'assets/icons/refresh.svg',
            label: '재측정',
            onTap: _handleRetry,
          ),
          _buildActionButton(
            context,
            icon: 'assets/icons/message.svg',
            label: '문자전송',
            onTap: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _getResponsiveSize(context, 320),
        height: _getResponsiveSize(context, 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              offset: const Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: _getResponsiveSize(context, 110),
              height: _getResponsiveSize(context, 110),
            ),
            SizedBox(height: _getResponsiveSize(context, 20)),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 36),
                fontVariations: const <FontVariation>[FontVariation('wght', 700)],
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

