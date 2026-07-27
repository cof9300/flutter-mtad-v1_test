import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/features/measurement/screen/alco_measurement_screen.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/measurement/widget/alco_result_action_buttons.dart';
import 'package:flutter_template/features/measurement/widget/alco_result_fail_content.dart';
import 'package:flutter_template/features/measurement/widget/alco_result_pass_content.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_mode_notifier.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/session_results_notifier.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class AlcoResultScreen extends ConsumerStatefulWidget {
  final AlcoMeasurementResult result;

  const AlcoResultScreen({super.key, required this.result});

  @override
  ConsumerState<AlcoResultScreen> createState() => _AlcoResultScreenState();
}

class _AlcoResultScreenState extends ConsumerState<AlcoResultScreen>
    with AutoReturnMixin, RouteAware {
  int _videoKey = 0;
  bool _isVideoActive = true;
  bool _isHidden = false;
  bool _isSmsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isLoading = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final l10n = AppLocalizations.of(context)!;
      ref.read(headerTitleProvider.notifier).setTitle(l10n.alcoResultTitle);
      await _loadPageOption();
      _saveAlcoResult().catchError((e) {
        FlutterErrorLogger.logError('[AlcoResult] 결과 저장 실패', e);
      });
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
    if (mounted) setState(() => _isVideoActive = true);
    _restartTimer();
  }

  Future<void> _loadPageOption() async {
    try {
      final kioskOption =
          await ServiceLocator().kioskOptionStorage.getOption();
      final resulttime = kioskOption?.resulttime ?? 120;
      final smsEnabled = (kioskOption?.sms ?? 0) != 0;

      if (mounted) {
        setState(() {
          _isSmsEnabled = smsEnabled;
        });
        if (resulttime > 0) startAutoReturnTimer(resulttime);
      }
    } catch (e) {
      FlutterErrorLogger.logError('[AlcoResult] 페이지 옵션 로드 실패', e);
      final kioskOption =
          await ServiceLocator().kioskOptionStorage.getOption();
      final resulttime = kioskOption?.resulttime ?? 120;
      if (mounted) {
        setState(() {
          _isSmsEnabled = (kioskOption?.sms ?? 0) != 0;
        });
        if (resulttime > 0) startAutoReturnTimer(resulttime);
      }
    }
  }

  Future<void> _restartTimer() async {
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    final resulttime = kioskOption?.resulttime ?? 120;
    if (mounted && resulttime > 0) startAutoReturnTimer(resulttime);
  }

  Future<void> _saveAlcoResult() async {
    _storeSessionResult();
    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        FlutterErrorLogger.logWarning('[AlcoResult] Token 없음');
        return;
      }
      final measureId = ref.read(measureIdProvider);
      final dateString =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.result.measuredAt);

      final setResultResponse = await ServiceLocator().authRepository.setResult(
        token: token,
        measureid: measureId ?? '',
        device: 'AL',
        result: {
          'alcohol_result': widget.result.isPass ? 'PASS' : 'FAIL',
          'alcohol_yang': widget.result.bacValue.toStringAsFixed(3),
          'datatime': dateString,
        },
        serviceforce: (measureId != null && measureId.isNotEmpty) ? 'false' : 'true',
      );

      final finalMeasureId =
          setResultResponse.measureid != null && setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : measureId;
      if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
        ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
      }

      FlutterErrorLogger.logInfo(
        '[AlcoResult] set-result 완료 — ${widget.result.isPass ? "PASS" : "FAIL"}, ${widget.result.bacValueText}',
      );
    } catch (e) {
      FlutterErrorLogger.logError('[AlcoResult] set-result 오류', e);
    }
  }

  void _handleRetry() {
    cancelAutoReturnTimer();

    final devices = ref.read(deviceListWithConnectionProvider);
    final hasMf = ref.read(mfDeviceProvider) != null;
    final totalConfigured = devices.length + (hasMf ? 1 : 0);

    if (totalConfigured >= 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DeviceSelectionScreen(),
        ),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const AlcoMeasurementScreen(),
        ),
        (route) => route.isFirst,
      );
    }
  }

  void _toggleHidden() {
    setState(() => _isHidden = !_isHidden);
    if (!_isHidden) resetCurrentTimer();
  }

  @override
  void closeModalsBeforeReturn() {}

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
    return (screenWidth / baseWidth * baseSize).clamp(
      baseSize * 0.5,
      baseSize * 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return GestureDetector(
      onTapDown: (_) {
        if (!_isHidden) resetCurrentTimer();
      },
      onPanDown: (_) {
        if (!_isHidden) resetCurrentTimer();
      },
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: isMobile
                      ? (MediaQuery.of(context).size.height < 850 ? 150.0 : 175.0)
                      : (DeviceConfig().isTabletSized(context)
                          ? _getResponsiveSize(context, 200)
                          : _getResponsiveSize(context, 280)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: _getResponsiveSize(context, 50)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: isMobile ? 0.0 : _getResponsiveSize(context, 30),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: isMobile
                                      ? (screenWidth * 0.68)
                                      : _getResponsiveSize(context, 620),
                                  child: Align(
                                    alignment: _isHidden
                                        ? Alignment.center
                                        : Alignment.topCenter,
                                    child: _isHidden
                                        ? _buildHiddenContent(context)
                                        : (widget.result.isPass
                                            ? AlcoResultPassContent(
                                                result: widget.result)
                                            : AlcoResultFailContent(
                                                result: widget.result)),
                                  ),
                                ),
                                _buildVideoSection(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: HomeButton(
                  onTap: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
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
                bottom: isMobile ? 54.0 : _getResponsiveSize(context, 40),
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 28),
                  ),
                  child: AlcoResultActionButtons(
                    onRetry: _handleRetry,
                    onSendMessage: _isSmsEnabled ? _handleSendMessage : null,
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {},
                    onPanDown: (_) {},
                    behavior: HitTestBehavior.opaque,
                    child: _buildLoadingOverlay(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _getResponsiveSize(context, 120),
              height: _getResponsiveSize(context, 120),
              child: CircularProgressIndicator(
                strokeWidth: _getResponsiveSize(context, 8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF227EFF),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 48)),
            Text(
              AppLocalizations.of(context)!.alcoResultLoading,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 42),
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 600),
                ],
                color: const Color(0xFF227EFF),
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHideButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final iconPath =
        _isHidden ? 'assets/icons/show.svg' : 'assets/icons/hide.svg';
    final label = _isHidden ? l10n.resultShow : l10n.resultHidden;

    final double buttonSize = isMobile ? 38.0 : _getResponsiveSize(context, 80);
    final double iconSize = isMobile ? 22.0 : _getResponsiveSize(context, 44);
    final double borderRadius = isMobile ? 19.0 : _getResponsiveSize(context, 40);
    final double paddingValue = isMobile ? 8.0 : _getResponsiveSize(context, 18);

    return GestureDetector(
      onTap: _toggleHidden,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isMobile ? Colors.white : const Color(0xFFE7EAF3),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.all(paddingValue),
            child: SvgPicture.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
            ),
          ),
          SizedBox(height: isMobile ? 0.0 : _getResponsiveSize(context, 4)),
          Transform.translate(
            offset: Offset(0, isMobile ? -4.0 : 0.0),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: isMobile ? 11.2 : _getResponsiveSize(context, 28),
                color: isMobile ? const Color(0xFF505050) : const Color(0xFF4C4948),
                letterSpacing: isMobile ? -0.8 : -0.7,
                height: isMobile ? 1.0 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final lockSize = isMobile
        ? 70.0
        : _getResponsiveSize(context, 240);
    final topSpace = isMobile
        ? 0.0
        : _getResponsiveSize(context, 80);

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
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSize(context, 40),
            ),
            child: Text(
              AppLocalizations.of(context)!.alcoResultHidden,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: isMobile ? 15.0 : _getResponsiveSize(context, 46),
                fontVariations: const <FontVariation>[FontVariation('wght', 700)],
                color: const Color(0xFF227EFF),
                letterSpacing: isMobile ? -0.8 : -1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    final resultPageOption = ref.watch(resultPageOptionProvider);
    final cmList = resultPageOption?.cm ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double width = isMobile
        ? screenWidth
        : _getResponsiveSize(context, 1024);
    final double height = isMobile
        ? width * 9 / 16
        : _getResponsiveSize(context, 576);

    return SizedBox(
      width: width,
      height: height,
      child: cmList.isNotEmpty
          ? MeasurementMediaPlayer(
              key: ValueKey('alco_result_video_$_videoKey'),
              mediaItems: cmList,
              baseUrl: Config.baseUrl,
              playerId: 'alco_result_video',
              isActive: _isVideoActive,
            )
          : null,
    );
  }

  Future<void> _handleSendMessage() async {
    FlutterErrorLogger.logInfo('[AlcoResult] 문자전송 버튼 클릭');
    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) return;

      final kioskOption =
          await ServiceLocator().kioskOptionStorage.getOption();
      if (kioskOption == null) return;

      final userAuth = ref.read(userAuthProvider);
      final guestPhone =
          await ServiceLocator().guestPhoneStorage.getPhoneNumber();
      final verifiedUserData =
          await ServiceLocator().verifiedUserStorage.getAllData();
      final verifiedPhone = verifiedUserData['phoneNumber'];

      final resultText = _buildAlcoResultText();
      final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
      final dateText = dateFormat.format(widget.result.measuredAt);
      final place = kioskOption.place;
      final isServiceMode = kioskOption.mode == 1;

      FlutterErrorLogger.logInfo(
          '[AlcoResult] 문자전송 Mode: ${kioskOption.mode}, UseCert: ${kioskOption.usecert}');

      if (isServiceMode && kioskOption.usecert == 1) {
        if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
          final currentMeasureId = ref.read(measureIdProvider);
          if (currentMeasureId != null && currentMeasureId.isNotEmpty) {
            try {
              await ServiceLocator().authRepository.updateResultUser(
                token: token,
                measureid: currentMeasureId,
                userid: verifiedPhone,
                type: 'PHONE',
                birth: verifiedUserData['birthday'],
                gender: verifiedUserData['gender'],
              );
            } catch (e) {
              FlutterErrorLogger.logError('[AlcoResult] updateResultUser 실패', e);
            }
          }
          await ServiceLocator().authRepository.sendSms(
            token: token,
            type: 'RESULT_GUEST',
            phonenumber: verifiedPhone,
            result: _combinedResultText(resultText),
            date: dateText,
            place: place,
          );
          _showSmsSuccess();
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AuthScreenWithBirthdayGender(alcoResult: widget.result),
            ),
          );
        }
        return;
      }

      if (isServiceMode && kioskOption.usecert == 2) {
        final stepParts = kioskOption.step.split(';');
        final isStep12 = stepParts.length >= 2 &&
            stepParts[0].trim() == '1' &&
            stepParts[1].trim() == '2';
        if (isStep12 && guestPhone != null && guestPhone.isNotEmpty) {
          final currentMeasureId = ref.read(measureIdProvider);
          if (currentMeasureId != null && currentMeasureId.isNotEmpty) {
            try {
              await ServiceLocator().authRepository.updateResultUser(
                token: token,
                measureid: currentMeasureId,
                userid: guestPhone,
                type: 'PHONE',
                birth: null,
                gender: null,
              );
            } catch (e) {
              FlutterErrorLogger.logError('[AlcoResult] updateResultUser 실패', e);
            }
          }
          await ServiceLocator().authRepository.sendSms(
            token: token,
            type: 'RESULT_GUEST',
            phonenumber: guestPhone,
            result: _combinedResultText(resultText),
            date: dateText,
            place: place,
          );
          _showSmsSuccess();
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(alcoResult: widget.result),
            ),
          );
        }
        return;
      }

      if (!isServiceMode) {
        final isGuestMode = ref.read(guestModeProvider);
        final hasVerifiedPhone =
            verifiedPhone != null && verifiedPhone.isNotEmpty;
        final hasUserAuthPhone =
            userAuth?.phonenumber != null && userAuth!.phonenumber!.isNotEmpty;

        if (isGuestMode) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestPhoneInputScreen(alcoResult: widget.result),
              ),
            );
          }
          return;
        }

        if (hasVerifiedPhone || hasUserAuthPhone) {
          final phoneNumber =
              hasVerifiedPhone ? verifiedPhone : userAuth!.phonenumber;
          await ServiceLocator().authRepository.sendSms(
                token: token,
                type: 'RESULT_GUEST',
                phonenumber: phoneNumber,
                result: _combinedResultText(resultText),
                date: dateText,
                place: place,
              );
          _showSmsSuccess();
          return;
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestPhoneInputScreen(alcoResult: widget.result),
            ),
          );
        }
        return;
      }

      final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
      final hasGuestPhone = guestPhone != null && guestPhone.isNotEmpty;
      final hasVerifiedPhone =
          verifiedPhone != null && verifiedPhone.isNotEmpty;

      if (guestMeasureFlag && hasGuestPhone) {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT_GUEST',
              phonenumber: guestPhone,
              result: _combinedResultText(resultText),
              date: dateText,
              place: place,
            );
        _showSmsSuccess();
        return;
      }

      if (hasVerifiedPhone) {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT_GUEST',
              phonenumber: verifiedPhone,
              result: _combinedResultText(resultText),
              date: dateText,
              place: place,
            );
        _showSmsSuccess();
        return;
      }

      final hasUserAuthMeasureId =
          userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;
      await ServiceLocator().authRepository.sendSms(
            token: token,
            type: hasUserAuthMeasureId ? 'RESULT' : 'RESULT_GUEST',
            measureid: hasUserAuthMeasureId ? userAuth.measureid : null,
            phonenumber: hasUserAuthMeasureId
                ? null
                : (guestPhone ?? userAuth?.phonenumber),
            result: _combinedResultText(resultText),
            date: dateText,
            place: place,
          );
      _showSmsSuccess();
    } catch (e) {
      FlutterErrorLogger.logError('[AlcoResult] SMS 전송 실패', e);
    }
  }

  void _showSmsSuccess() {
    if (mounted) {
      SendResultSuccessModal.show(
        context,
        onConfirm: () {
          SendResultSuccessModal.hide(context);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }
  }

  String _buildAlcoResultText() {
    return '▶음주\n- 음주 결과: ${widget.result.isPass ? 'PASS' : 'FAIL'}\n- 음주량: ${widget.result.bacValueText}';
  }

  void _storeSessionResult() {
    try {
      if (!mounted) return;
      ref
          .read(sessionResultsProvider.notifier)
          .addResult('AL', _buildAlcoResultText());
    } catch (_) {}
  }

  String _combinedResultText(String fallback) {
    return ref.read(sessionResultsProvider.notifier).combinedText(fallback);
  }
}
