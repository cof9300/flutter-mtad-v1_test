import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/utils/pending_result_save_flag.dart';
import 'package:flutter_template/core/utils/height_weight_calculator.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/widget/bmi_chart.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/features/measurement/widget/guest_auth_required_modal.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/auth/screen/auth_screen.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_mode_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_skip_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/session_results_notifier.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/main.dart';

class HeightWeightResultScreen extends ConsumerStatefulWidget {
  final HeightWeightResult result;

  const HeightWeightResultScreen({super.key, required this.result});

  @override
  ConsumerState<HeightWeightResultScreen> createState() =>
      _HeightWeightResultScreenState();
}

class _HeightWeightResultScreenState
    extends ConsumerState<HeightWeightResultScreen>
    with AutoReturnMixin, RouteAware {
  bool _isHidden = false;
  int _videoKey = 0;
  bool _isSmsEnabled = true;
  bool _isVideoActive = true;
  Map<String, dynamic>? _pendingResult;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final l10n = AppLocalizations.of(context)!;
      final pageOption = ref.read(resultPageOptionProvider);
      ref.read(headerTitleProvider.notifier).setTitle(l10n.heightWeightResultTitle);

      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      if (pageOption != null) {
        final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
        setState(() {
          _isHidden = guestMeasureFlag
              ? (kioskOption?.masking ?? false)
              : pageOption.masking;
        });
      }
      final resulttime = kioskOption?.resulttime ?? 120;
      if (mounted) {
        setState(() {
          _isSmsEnabled = kioskOption?.sms != 0;
        });
      }
      _saveMeasurementResult().catchError((e) {
        FlutterErrorLogger.logError('[HS측정결과] 저장 실패', e);
      });
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
    if (mounted) setState(() => _isVideoActive = true);
    _restartTimerAfterAuth();
    if (PendingResultSaveFlag.guestSaveHandledByAuth) {
      PendingResultSaveFlag.guestSaveHandledByAuth = false;
      if (_pendingResult != null && mounted) {
        setState(() => _pendingResult = null);
      }
      return;
    }
    if (_pendingResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingResult != null) {
          _savePendingResultAfterAuth();
        }
      });
    }
  }

  Future<void> _restartTimerAfterAuth() async {
    if (mounted) {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final resulttime = kioskOption?.resulttime ?? 120;
      if (resulttime > 0) startAutoReturnTimer(resulttime);
    }
  }

  @override
  void closeModalsBeforeReturn() {
    if (mounted) {
      GuestAuthRequiredModal.hide(context);
      try {
        ref.read(userAuthProvider.notifier).clearUserAuth();
        ref.read(measureIdProvider.notifier).clearMeasureId();
        ref.read(guestModeProvider.notifier).clearGuestMode();
        ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
      } catch (_) {}
      try {
        ServiceLocator().verifiedUserStorage.clearAll();
        ServiceLocator().guestPhoneStorage.clearPhoneNumber();
      } catch (_) {}
    }
  }

  @override
  void didPop() {
    if (mounted) GuestAuthRequiredModal.hide(context);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancelAutoReturnTimer();
    try {
      if (mounted) GuestAuthRequiredModal.hide(context);
    } catch (_) {}
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

  Map<String, dynamic> _buildResultData() {
    return HeightWeightCalculator.createResultData(
      height: widget.result.height,
      weight: widget.result.weight,
      bmi: widget.result.bmi,
      context: context,
    );
  }

  Future<void> _saveMeasurementResult() async {
    _storeSessionResult();
    try {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final measureId = ref.read(measureIdProvider);
      final userAuth = ref.read(userAuthProvider);

      if (kioskOption == null) return;
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) return;

      final result = _buildResultData();

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
                    device: 'HS',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid?.isNotEmpty == true
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            if (verifiedPhone?.isNotEmpty == true &&
                verifiedBirthday?.isNotEmpty == true &&
                verifiedGender?.isNotEmpty == true) {
              try {
                await ServiceLocator().authRepository.updateResultUser(
                      token: token,
                      measureid: finalMeasureId,
                      userid: verifiedPhone!,
                      type: 'PHONE',
                      birth: verifiedBirthday,
                      gender: verifiedGender,
                    );
              } catch (_) {}
            }
          }
          return;
        } else if (kioskOption.usecert == 2) {
          final guestPhone =
              await ServiceLocator().guestPhoneStorage.getPhoneNumber();
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'HS',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid?.isNotEmpty == true
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            if (guestPhone?.isNotEmpty == true) {
              try {
                await ServiceLocator().authRepository.updateResultUser(
                      token: token,
                      measureid: finalMeasureId,
                      userid: guestPhone!,
                      type: 'PHONE',
                      birth: null,
                      gender: null,
                    );
              } catch (e) {
                FlutterErrorLogger.logError('[HS측정결과] updateResultUser 실패', e);
              }
            }
          }
          return;
        }
      } else {
        final targetMeasureId =
            userAuth?.measureid?.isNotEmpty == true
                ? userAuth!.measureid!
                : (measureId ?? '');
        final isAuthenticated = userAuth?.measureid?.isNotEmpty == true;

        if (isAuthenticated) {
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: targetMeasureId,
                    device: 'HS',
                    result: result,
                    serviceforce: 'false',
                  );

          final finalMeasureId = setResultResponse.measureid?.isNotEmpty == true
              ? setResultResponse.measureid!
              : targetMeasureId;

          if (finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
          }
        } else {
          final isGuestMode = ref.read(guestModeProvider);
          final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
          final guestSkipAuth = ref.read(guestSkipAuthProvider);

          if (isGuestMode || guestMeasureFlag || guestSkipAuth) {
            await _saveAsGuestAndShow(result);
          } else {
            setState(() {
              _pendingResult = result;
              _isHidden = true;
            });
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  GuestAuthRequiredModal.show(
                    context,
                    onConfirm: () {
                      GuestAuthRequiredModal.hide(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(
                            returnToPreviousScreen: true,
                            pendingHwResultForGuestSave: widget.result,
                          ),
                        ),
                      );
                    },
                    onDecline: () {
                      ref.read(guestSkipAuthProvider.notifier).setSkipAuth();
                      ref.read(guestModeProvider.notifier).setGuestMode(true);
                      _saveAsGuestAndShow(result);
                    },
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      FlutterErrorLogger.logError('[HS측정결과] 저장 오류', e);
    }
  }

  Future<void> _saveAsGuestAndShow(dynamic result) async {
    final measureId = ref.read(measureIdProvider);
    final token = await ServiceLocator().tokenStorage.getToken() ?? '';
    final guestMeasureId = measureId ?? '';
    try {
      final setResultResponse = await ServiceLocator().authRepository.setResult(
            token: token,
            measureid: guestMeasureId,
            device: 'HS',
            result: result,
            serviceforce: 'true',
          );
      final finalMeasureId =
          setResultResponse.measureid?.isNotEmpty == true
              ? setResultResponse.measureid!
              : guestMeasureId;
      if (finalMeasureId.isNotEmpty) {
        ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        FlutterErrorLogger.logInfo(
            '[HS측정결과] 게스트 저장 성공 MeasureId: $finalMeasureId, ServiceForce: true');
      }
    } catch (e) {
      FlutterErrorLogger.logError('[HS측정결과] 게스트 setResult 실패', e);
    }
    final option = await ServiceLocator().kioskOptionStorage.getOption();
    if (mounted) {
      setState(() {
        _pendingResult = null;
        _isHidden = option?.masking ?? false;
      });
    }
    FlutterErrorLogger.logInfo('[HS측정결과] 게스트 모드: 결과 화면 표시');
  }

  Future<void> _savePendingResultAfterAuth() async {
    if (_pendingResult == null) return;
    try {
      final userAuthAfterAuth = ref.read(userAuthProvider);
      final isAuthenticated = userAuthAfterAuth?.measureid?.isNotEmpty == true;
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        if (mounted) setState(() => _pendingResult = null);
        return;
      }

      String finalMeasureId = '';

      if (isAuthenticated) {
        final setResultResponse =
            await ServiceLocator().authRepository.setResult(
                  token: token,
                  measureid: userAuthAfterAuth!.measureid!,
                  device: 'HS',
                  result: _pendingResult!,
                  serviceforce: 'false',
                );
        finalMeasureId = setResultResponse.measureid?.isNotEmpty == true
            ? setResultResponse.measureid!
            : userAuthAfterAuth.measureid!;
        if (finalMeasureId.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        }
        if (userAuthAfterAuth.phonenumber?.isNotEmpty == true) {
          try {
            await ServiceLocator().authRepository.updateResultUser(
                  token: token,
                  measureid: finalMeasureId,
                  userid: userAuthAfterAuth.phonenumber!,
                  type: 'PHONE',
                  birth: userAuthAfterAuth.birthday,
                  gender: userAuthAfterAuth.gender,
                );
          } catch (e) {
            FlutterErrorLogger.logError('[HS측정결과] updateResultUser 실패', e);
          }
        }
      } else {
        final setResultResponse =
            await ServiceLocator().authRepository.setResult(
                  token: token,
                  measureid: '',
                  device: 'HS',
                  result: _pendingResult!,
                  serviceforce: 'true',
                );
        finalMeasureId = setResultResponse.measureid?.isNotEmpty == true
            ? setResultResponse.measureid!
            : '';
        if (finalMeasureId.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        }
      }

      final option = await ServiceLocator().kioskOptionStorage.getOption();
      if (mounted) {
        setState(() {
          _isHidden = option?.masking ?? false;
          _pendingResult = null;
        });
      }
    } catch (e) {
      FlutterErrorLogger.logError('[HS측정결과] 인증 후 처리 오류', e);
      if (mounted) setState(() => _pendingResult = null);
    }
  }

  Future<void> _handleSendMessage() async {
    final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
    if (guestMeasureFlag) {
      final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();
      if (guestPhone == null || guestPhone.isEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: null, hwResult: widget.result),
            ),
          );
        }
        return;
      }
    }

    final userAuth = ref.read(userAuthProvider);
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();
    final measureId = ref.read(measureIdProvider);
    final verifiedUserData =
        await ServiceLocator().verifiedUserStorage.getAllData();
    final verifiedPhone = verifiedUserData['phoneNumber'];

    if (kioskOption == null) return;

    final isServiceMode = kioskOption.mode == 1;

    if (isServiceMode) {
      if (kioskOption.usecert == 1) {
        if (verifiedPhone?.isNotEmpty == true) {
          try {
            final token = await ServiceLocator().tokenStorage.getToken();
            if (token == null) return;

            final status = HeightWeightCalculator.getBmiStatus(
              widget.result.bmi,
              context,
            );
            final resultText = _buildSmsText(status);
            final dateText =
                DateFormat('yyyy.MM.dd HH:mm').format(widget.result.measuredAt);

            await ServiceLocator().authRepository.sendSms(
                  token: token,
                  type: 'RESULT_GUEST',
                  phonenumber: verifiedPhone,
                  result: _combinedResultText(resultText),
                  date: dateText,
                  place: kioskOption.place,
                );

            if (mounted) {
              SendResultSuccessModal.show(
                context,
                onConfirm: () {
                  SendResultSuccessModal.hide(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }
            return;
          } catch (_) {
            return;
          }
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AuthScreenWithBirthdayGender(result: null, hwResult: widget.result),
            ),
          );
        }
        return;
      } else if (kioskOption.usecert == 2) {
        final stepParts = kioskOption.step.split(';');
        final isStep12 = stepParts.length >= 2 &&
            stepParts[0].trim() == '1' &&
            stepParts[1].trim() == '2';

        if (isStep12 && guestPhone?.isNotEmpty == true) {
          try {
            final token = await ServiceLocator().tokenStorage.getToken();
            if (token == null) return;

            final status = HeightWeightCalculator.getBmiStatus(
              widget.result.bmi,
              context,
            );
            final resultText = _buildSmsText(status);
            final dateText =
                DateFormat('yyyy.MM.dd HH:mm').format(widget.result.measuredAt);

            await ServiceLocator().authRepository.sendSms(
                  token: token,
                  type: 'RESULT_GUEST',
                  phonenumber: guestPhone,
                  result: _combinedResultText(resultText),
                  date: dateText,
                  place: kioskOption.place,
                );

            if (mounted) {
              SendResultSuccessModal.show(
                context,
                onConfirm: () {
                  SendResultSuccessModal.hide(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }
            return;
          } catch (_) {
            return;
          }
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: null, hwResult: widget.result),
            ),
          );
        }
        return;
      }
    }

    if (!isServiceMode) {
      final hasPhone = verifiedPhone?.isNotEmpty == true ||
          userAuth?.phonenumber?.isNotEmpty == true;
      final hasMeasureId = userAuth?.measureid?.isNotEmpty == true ||
          (measureId != null && measureId.isNotEmpty);
      final isAuthenticated = hasPhone && hasMeasureId;
      final isGuestMode = ref.read(guestModeProvider);

      if (isGuestMode) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: null, hwResult: widget.result),
            ),
          );
        }
        return;
      }

      if (isAuthenticated) {
        try {
          final token = await ServiceLocator().tokenStorage.getToken();
          if (token == null) return;

          final status = HeightWeightCalculator.getBmiStatus(
            widget.result.bmi,
            context,
          );
          final resultText = _buildSmsText(status);
          final dateText =
              DateFormat('yyyy.MM.dd HH:mm').format(widget.result.measuredAt);
          final phoneNumber = verifiedPhone?.isNotEmpty == true
              ? verifiedPhone
              : userAuth?.phonenumber;

          await ServiceLocator().authRepository.sendSms(
                token: token,
                type: 'RESULT_GUEST',
                phonenumber: phoneNumber,
                result: _combinedResultText(resultText),
                date: dateText,
                place: kioskOption.place,
              );

          if (mounted) {
            SendResultSuccessModal.show(
              context,
              onConfirm: () {
                SendResultSuccessModal.hide(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            );
          }
          return;
        } catch (_) {
          return;
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GuestPhoneInputScreen(result: null, hwResult: widget.result),
          ),
        );
      }
    }
  }

  String _buildSmsText(String status) {
    return '▶신장체중\n'
        '- 신장: ${widget.result.height} cm\n'
        '- 체중: ${widget.result.weight} kg\n'
        '- BMI: ${widget.result.bmi.toStringAsFixed(1)}\n'
        '- 측정결과: $status';
  }

  void _storeSessionResult() {
    try {
      if (!mounted) return;
      final status = HeightWeightCalculator.getBmiStatus(
        widget.result.bmi,
        context,
      );
      ref
          .read(sessionResultsProvider.notifier)
          .addResult('HS', _buildSmsText(status));
    } catch (_) {}
  }

  String _combinedResultText(String fallback) {
    return ref.read(sessionResultsProvider.notifier).combinedText(fallback);
  }

  void _handleRetry() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
      (route) => route.isFirst,
    );
  }

  void _handleHomeButton() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleHideResult() {
    setState(() => _isHidden = !_isHidden);
    if (!_isHidden) resetCurrentTimer();
  }

  @override
  Widget build(BuildContext context) {
    final status = HeightWeightCalculator.getBmiStatus(
      widget.result.bmi,
      context,
    );
    final statusColor =
        HeightWeightCalculator.getStatusColor(status, context);

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
                  bottom: DeviceConfig().isTabletSized(context)
                      ? _getResponsiveSize(context, 200)
                      : _getResponsiveSize(context, 320),
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
                              top: _getResponsiveSize(context, 30),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: _getResponsiveSize(context, 620),
                                  child: _isHidden
                                      ? _HiddenContent(
                                          getResponsiveSize:
                                              _getResponsiveSize,
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: _getResponsiveSize(
                                                  context, 60),
                                            ),
                                            _VitalsRow(
                                              result: widget.result,
                                              getResponsiveSize:
                                                  _getResponsiveSize,
                                            ),
                                            SizedBox(
                                              height: _getResponsiveSize(
                                                  context, 30),
                                            ),
                                            _StatusRow(
                                              status: status,
                                              statusColor: statusColor,
                                              getResponsiveSize:
                                                  _getResponsiveSize,
                                            ),
                                            SizedBox(
                                              height: _getResponsiveSize(
                                                  context, 10),
                                            ),
                                            _ChartSection(
                                              bmi: widget.result.bmi,
                                              getResponsiveSize:
                                                  _getResponsiveSize,
                                            ),
                                            SizedBox(
                                              height: _getResponsiveSize(
                                                  context, 10),
                                            ),
                                          ],
                                        ),
                                ),
                                _VideoSection(
                                  videoKey: _videoKey,
                                  isActive: _isVideoActive,
                                  getResponsiveSize: _getResponsiveSize,
                                ),
                                SizedBox(
                                  height: _getResponsiveSize(context, 40),
                                ),
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
                  onTap: _handleHomeButton,
                  topPadding: _getResponsiveSize(context, 20),
                  leftPadding: _getResponsiveSize(context, 30),
                ),
              ),
              Positioned(
                top: _getResponsiveSize(context, 20),
                right: _getResponsiveSize(context, 30),
                child: _HideButton(
                  isHidden: _isHidden,
                  onTap: _toggleHideResult,
                  getResponsiveSize: _getResponsiveSize,
                ),
              ),
              Positioned(
                bottom: _getResponsiveSize(context, 40),
                left: 0,
                right: 0,
                child: _BottomButtons(
                  isSmsEnabled: _isSmsEnabled,
                  onRetry: _handleRetry,
                  onSendMessage: _handleSendMessage,
                  getResponsiveSize: _getResponsiveSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HideButton extends StatelessWidget {
  final bool isHidden;
  final VoidCallback onTap;
  final double Function(BuildContext, double) getResponsiveSize;

  const _HideButton({
    required this.isHidden,
    required this.onTap,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconPath =
        isHidden ? 'assets/icons/show.svg' : 'assets/icons/hide.svg';
    final label = isHidden ? l10n.resultShow : l10n.resultHidden;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getResponsiveSize(context, 80),
            height: getResponsiveSize(context, 80),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EAF3),
              borderRadius: BorderRadius.circular(
                getResponsiveSize(context, 40),
              ),
            ),
            padding: EdgeInsets.all(getResponsiveSize(context, 18)),
            child: SvgPicture.asset(
              iconPath,
              width: getResponsiveSize(context, 44),
              height: getResponsiveSize(context, 44),
            ),
          ),
          SizedBox(height: getResponsiveSize(context, 4)),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: getResponsiveSize(context, 28),
              color: const Color(0xFF4C4948),
              letterSpacing: -0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenContent extends StatelessWidget {
  final double Function(BuildContext, double) getResponsiveSize;

  const _HiddenContent({required this.getResponsiveSize});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: getResponsiveSize(context, 80)),
          SvgPicture.asset(
            'assets/images/hide_view.svg',
            width: getResponsiveSize(context, 240),
            height: getResponsiveSize(context, 240),
          ),
          SizedBox(height: getResponsiveSize(context, 30)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getResponsiveSize(context, 40),
            ),
            child: Text(
              l10n.resultHiddenGuide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: getResponsiveSize(context, 46),
                fontVariations: const [FontVariation('wght', 700)],
                color: const Color(0xFF227EFF),
                letterSpacing: -1.6,
              ),
            ),
          ),
          SizedBox(height: getResponsiveSize(context, 120)),
        ],
      ),
    );
  }
}

class _VitalsRow extends StatelessWidget {
  final HeightWeightResult result;
  final double Function(BuildContext, double) getResponsiveSize;

  const _VitalsRow({required this.result, required this.getResponsiveSize});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _VitalItem(
          value: result.height.toStringAsFixed(1),
          labelTop: l10n.hwHeightLabel,
          labelBottom: '(Height)',
          getResponsiveSize: getResponsiveSize,
        ),
        _VerticalDivider(getResponsiveSize: getResponsiveSize),
        _VitalItem(
          value: result.weight.toStringAsFixed(1),
          labelTop: l10n.hwWeightLabel,
          labelBottom: '(Weight)',
          getResponsiveSize: getResponsiveSize,
        ),
        _VerticalDivider(getResponsiveSize: getResponsiveSize),
        _VitalItem(
          value: result.bmi.toStringAsFixed(1),
          labelTop: l10n.hwBmiLabel,
          labelBottom: '(BMI)',
          getResponsiveSize: getResponsiveSize,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final double Function(BuildContext, double) getResponsiveSize;

  const _VerticalDivider({required this.getResponsiveSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: getResponsiveSize(context, 189),
      color: const Color(0xFFCCCCCC),
      margin: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(context, 60),
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final String value;
  final String labelTop;
  final String labelBottom;
  final double Function(BuildContext, double) getResponsiveSize;

  const _VitalItem({
    required this.value,
    required this.labelTop,
    required this.labelBottom,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.titleFontFamily,
            fontSize: getResponsiveSize(context, 90),
            color: const Color(0xFF111111),
            letterSpacing: -2.25,
          ),
        ),
        SizedBox(height: getResponsiveSize(context, 8)),
        Text(
          labelTop,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: getResponsiveSize(context, 32),
            color: const Color(0xFF505050),
            letterSpacing: -0.8,
          ),
        ),
        Text(
          labelBottom,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: getResponsiveSize(context, 32),
            color: const Color(0xFF505050),
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final Color statusColor;
  final double Function(BuildContext, double) getResponsiveSize;

  const _StatusRow({
    required this.status,
    required this.statusColor,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: getResponsiveSize(context, 24),
          height: getResponsiveSize(context, 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        SizedBox(width: getResponsiveSize(context, 15)),
        Text(
          status,
          style: TextStyle(
            fontFamily: AppTextStyles.titleFontFamily,
            fontSize: getResponsiveSize(context, 72),
            color: const Color(0xFF111111),
            letterSpacing: -1.8,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  final double bmi;
  final double Function(BuildContext, double) getResponsiveSize;

  const _ChartSection({required this.bmi, required this.getResponsiveSize});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: getResponsiveSize(context, 800)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getResponsiveSize(context, 20),
          ),
          child: BmiChart(bmi: bmi),
        ),
      ),
    );
  }
}

class _VideoSection extends ConsumerWidget {
  final int videoKey;
  final bool isActive;
  final double Function(BuildContext, double) getResponsiveSize;

  const _VideoSection({
    required this.videoKey,
    required this.isActive,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageOption = ref.read(resultPageOptionProvider);

    if (pageOption == null || pageOption.cm.isEmpty) {
      return SizedBox(
        width: getResponsiveSize(context, 1024),
        height: getResponsiveSize(context, 576),
      );
    }

    return SizedBox(
      width: getResponsiveSize(context, 1024),
      height: getResponsiveSize(context, 576),
      child: MeasurementMediaPlayer(
        key: ValueKey('hc_result_video_$videoKey'),
        mediaItems: pageOption.cm,
        baseUrl: Config.baseUrl,
        playerId: 'hc_result_video',
        isActive: isActive,
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final bool isSmsEnabled;
  final VoidCallback onRetry;
  final VoidCallback onSendMessage;
  final double Function(BuildContext, double) getResponsiveSize;

  const _BottomButtons({
    required this.isSmsEnabled,
    required this.onRetry,
    required this.onSendMessage,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(context, 28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: 'assets/icons/refresh.svg',
            label: l10n.remeasure,
            onTap: onRetry,
            getResponsiveSize: getResponsiveSize,
          ),
          if (isSmsEnabled) ...[
            SizedBox(width: getResponsiveSize(context, 28)),
            _ActionButton(
              icon: 'assets/icons/message.svg',
              label: l10n.sendMessage,
              onTap: onSendMessage,
              getResponsiveSize: getResponsiveSize,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final double Function(BuildContext, double) getResponsiveSize;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.getResponsiveSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: getResponsiveSize(context, 498),
        height: getResponsiveSize(context, 255),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(getResponsiveSize(context, 32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              offset: const Offset(2, 2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              offset: const Offset(1, 1),
              blurRadius: 2,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: getResponsiveSize(context, 80),
              height: getResponsiveSize(context, 80),
            ),
            SizedBox(height: getResponsiveSize(context, 24)),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: getResponsiveSize(context, 32),
                fontVariations: const [FontVariation('wght', 700)],
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
