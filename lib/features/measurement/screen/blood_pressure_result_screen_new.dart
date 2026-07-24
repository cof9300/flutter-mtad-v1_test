import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/widget/blood_pressure_chart.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/features/measurement/widget/guest_auth_required_modal.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/auth/screen/auth_screen.dart';
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/pending_result_save_flag.dart';
import 'package:flutter_template/core/utils/blood_pressure_constants.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_mode_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_skip_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/providers/notifier/last_bp_result_notifier.dart';
import 'package:flutter_template/providers/notifier/session_results_notifier.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/main.dart';

class BloodPressureResultScreenNew extends ConsumerStatefulWidget {
  final BloodPressureResult result;

  const BloodPressureResultScreenNew({super.key, required this.result});

  @override
  ConsumerState<BloodPressureResultScreenNew> createState() =>
      _BloodPressureResultScreenNewState();
}

class _BloodPressureResultScreenNewState
    extends ConsumerState<BloodPressureResultScreenNew>
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

    FlutterErrorLogger.logInfo(
        '[측정결과] 화면 진입 - 수축기: ${widget.result.systolic}, Diastolic: ${widget.result.diastolic}, Pulse: ${widget.result.pulse}');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(lastBpResultProvider.notifier).setResult(widget.result);
      final l10n = AppLocalizations.of(context)!;
      final pageOption = ref.read(resultPageOptionProvider);

      ref
          .read(headerTitleProvider.notifier)
          .setTitle(l10n.bloodPressureResultTitle);

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

      // 측정 결과 저장 (비동기지만 타이머는 독립적으로 시작)
      _saveMeasurementResult().catchError((e) {
        FlutterErrorLogger.logError('[측정결과] 저장 실패', e);
      });

      // 모달 표시 여부와 관계없이 타이머 시작
      if (mounted && resulttime > 0) {
        startAutoReturnTimer(resulttime);
        FlutterErrorLogger.logInfo('[측정결과] 타이머 시작, 자동복귀: $resulttime초');
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
      if (resulttime > 0) {
        startAutoReturnTimer(resulttime);
        FlutterErrorLogger.logInfo('[측정결과] 타이머 재시작, 자동복귀: $resulttime초');
      }
    }
  }

  @override
  void closeModalsBeforeReturn() {
    // AutoReturnMixin의 _onAutoReturn()에서 호출됨
    // 스탠바이 화면으로 돌아가기 전에 모달 닫기 및 사용자 정보 초기화
    if (mounted) {
      GuestAuthRequiredModal.hide(context);
      
      // 사용자 관련 전역 정보 초기화
      try {
        ref.read(userAuthProvider.notifier).clearUserAuth();
        ref.read(measureIdProvider.notifier).clearMeasureId();
        ref.read(guestModeProvider.notifier).clearGuestMode();
        ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
        ref.read(lastBpResultProvider.notifier).clearResult();
        FlutterErrorLogger.logInfo('[시스템] 사용자 정보 초기화 완료');
      } catch (e) {
        FlutterErrorLogger.logError('[시스템] 사용자 정보 초기화 실패', e);
      }
      
      // 로컬 저장소 정보 초기화
      try {
        ServiceLocator().verifiedUserStorage.clearAll();
        ServiceLocator().guestPhoneStorage.clearPhoneNumber();
        FlutterErrorLogger.logInfo('[시스템] 로컬 저장소 초기화 완료');
      } catch (e) {
        FlutterErrorLogger.logError('[시스템] 로컬 저장소 초기화 실패', e);
      }
    }
  }

  @override
  void didPop() {
    // 화면이 pop될 때 모달 닫기
    if (mounted) {
      GuestAuthRequiredModal.hide(context);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    cancelAutoReturnTimer();
    try {
      if (mounted) {
        GuestAuthRequiredModal.hide(context);
      }
    } catch (e) {
    }

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    super.dispose();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize).clamp(
      baseSize * 0.5,
      baseSize * 1.5,
    );
  }

  void _handleHomeButton(BuildContext context) {
    FlutterErrorLogger.logInfo('[화면이동] 홈 버튼 클릭');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleRetry() async {
    FlutterErrorLogger.logInfo('[혈압측정] 재측정 버튼 클릭');

    if (!mounted) return;

    final devices = ref.read(deviceListWithConnectionProvider);
    final connectedDevices = devices.where((d) => d.isConnected).toList();
    final hasMf = ref.read(mfDeviceProvider) != null;
    final totalConnected = connectedDevices.length + (hasMf ? 1 : 0);

    if (totalConnected >= 2) {
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
          builder: (context) => const MeasurementScreen(deviceType: 'BP'),
        ),
        (route) => route.isFirst,
      );
    }
  }

  void _storeSessionResult() {
    try {
      if (!mounted) return;
      final status = BloodPressureCalculator.getStatus(
        widget.result.systolic,
        widget.result.diastolic,
        context,
      );
      ref
          .read(sessionResultsProvider.notifier)
          .addResult('BP', _buildResultText(status));
    } catch (_) {}
  }

  String _combinedResultText(String fallback) {
    return ref.read(sessionResultsProvider.notifier).combinedText(fallback);
  }

  Future<void> _saveMeasurementResult() async {
    _storeSessionResult();
    try {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final measureId = ref.read(measureIdProvider);
      final userAuth = ref.read(userAuthProvider);

      if (kioskOption == null) {
        FlutterErrorLogger.logWarning('[측정결과] KioskOption 없음');
        return;
      }

      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        FlutterErrorLogger.logWarning('[측정결과] Token 없음');
        return;
      }

      FlutterErrorLogger.logInfo(
          '[측정결과] 저장 시작 - Mode: ${kioskOption.mode}, Systolic: ${widget.result.systolic}, Diastolic: ${widget.result.diastolic}, Pulse: ${widget.result.pulse}');

      final result = BloodPressureCalculator.createResultData(
        systolic: widget.result.systolic,
        diastolic: widget.result.diastolic,
        pulse: widget.result.pulse,
        context: context,
      );

      if (kioskOption.mode == 1) {
        if (kioskOption.usecert == 1) {
          // 측정 전 인증 정보 확인
          final verifiedUserData =
              await ServiceLocator().verifiedUserStorage.getAllData();
          final verifiedPhone = verifiedUserData['phoneNumber'];
          final verifiedBirthday = verifiedUserData['birthday'];
          final verifiedGender = verifiedUserData['gender'];

          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'BP',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);

            // 측정 전 인증이 완료된 경우 인증 정보 업데이트
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
                FlutterErrorLogger.logInfo('[측정결과] updateResultUser 완료 MeasureId: $finalMeasureId');
              } catch (e) {
                // updateResultUser 실패 시에도 계속 진행
                print('Failed to update result user: $e');
              }
            }
          }
          return;
        } else if (kioskOption.usecert == 2) {
          // guest_phone_input_screen 거쳐온 경우
          final guestPhone = await ServiceLocator().guestPhoneStorage.getPhoneNumber();
          
          FlutterErrorLogger.logInfo('[측정결과] 게스트 전화번호: $guestPhone');
          
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'BP',
                    result: result,
                    serviceforce: 'true',
                  );

          final finalMeasureId = setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : measureId;

          if (finalMeasureId != null && finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            FlutterErrorLogger.logInfo('[측정결과] setResult 완료 MeasureId: $finalMeasureId');

            // 게스트 전화번호가 있으면 updateResultUser 호출
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
                FlutterErrorLogger.logInfo('[측정결과] updateResultUser 완료 MeasureId: $finalMeasureId, Phone: $guestPhone');
              } catch (e) {
                FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
              }
            } else {
              FlutterErrorLogger.logWarning('[측정결과] 게스트 전화번호 없음');
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

        FlutterErrorLogger.logInfo(
            '[측정결과] Mode2 인증 상태: ${isAuthenticated ? "인증됨" : "인증 안됨"}, MeasureId: $targetMeasureId');

        if (isAuthenticated) {
          // 인증된 경우: 바로 결과 저장
          final serviceforce = 'false';
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: targetMeasureId,
                    device: 'BP',
                    result: result,
                    serviceforce: serviceforce,
                  );

          final finalMeasureId = setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : (measureId ?? targetMeasureId);

          if (finalMeasureId.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
            FlutterErrorLogger.logInfo(
                '[측정결과] 저장 성공 FinalMeasureId: $finalMeasureId');
          } else {
            FlutterErrorLogger.logWarning('[측정결과] FinalMeasureId 없음');
          }
        } else {
          // 인증 없는 경우: 게스트 모드 플래그 및 게스트 측정 플래그 확인
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
                            pendingResultForGuestSave: widget.result,
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
      FlutterErrorLogger.logError('[측정결과] 저장 오류', e);
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
            device: 'BP',
            result: result,
            serviceforce: 'true',
          );
      final finalMeasureId =
          setResultResponse.measureid != null &&
                  setResultResponse.measureid!.isNotEmpty
              ? setResultResponse.measureid!
              : guestMeasureId;
      if (finalMeasureId.isNotEmpty) {
        ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        FlutterErrorLogger.logInfo(
            '[측정결과] 게스트 저장 성공 MeasureId: $finalMeasureId, ServiceForce: true');
      }
    } catch (e) {
      FlutterErrorLogger.logError('[측정결과] 게스트 setResult 실패', e);
    }
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    if (mounted) {
      setState(() {
        _pendingResult = null;
        _isHidden = kioskOption?.masking ?? false;
      });
    }
    FlutterErrorLogger.logInfo('[측정결과] 게스트 모드: 결과 화면 표시');
  }

  Future<void> _savePendingResultAfterAuth() async {
    if (_pendingResult == null) return;

    try {
      final userAuthAfterAuth = ref.read(userAuthProvider);
      final isAuthenticatedAfterAuth = userAuthAfterAuth != null &&
          userAuthAfterAuth.measureid != null &&
          userAuthAfterAuth.measureid!.isNotEmpty;

      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        if (mounted) setState(() => _pendingResult = null);
        return;
      }

      String finalMeasureId = '';

      if (isAuthenticatedAfterAuth) {
        final setResultResponse =
            await ServiceLocator().authRepository.setResult(
                  token: token,
                  measureid: userAuthAfterAuth.measureid!,
                  device: 'BP',
                  result: _pendingResult!,
                  serviceforce: 'false',
                );
        finalMeasureId = setResultResponse.measureid != null &&
                setResultResponse.measureid!.isNotEmpty
            ? setResultResponse.measureid!
            : userAuthAfterAuth.measureid!;
        if (finalMeasureId.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        }
        if (userAuthAfterAuth.phonenumber != null &&
            userAuthAfterAuth.phonenumber!.isNotEmpty) {
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
            FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
          }
        }
      } else {
        final setResultResponse =
            await ServiceLocator().authRepository.setResult(
                  token: token,
                  measureid: '',
                  device: 'BP',
                  result: _pendingResult!,
                  serviceforce: 'true',
                );
        finalMeasureId = setResultResponse.measureid != null &&
                setResultResponse.measureid!.isNotEmpty
            ? setResultResponse.measureid!
            : '';
        if (finalMeasureId.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
        }
      }

      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      if (mounted) {
        final maskingValue = kioskOption?.masking ?? false;
        setState(() {
          _isHidden = maskingValue;
          _pendingResult = null;
        });
      }
    } catch (e) {
      FlutterErrorLogger.logError('[측정결과] 인증 후 처리 오류', e);
      if (mounted) setState(() => _pendingResult = null);
    }
  }

  Future<void> _handleSendMessage() async {
    FlutterErrorLogger.logInfo('[문자전송] 전송 버튼 클릭');

    final guestMeasureFlag = ref.read(guestMeasureFlagProvider);
    if (guestMeasureFlag) {
      final guestPhone =
          await ServiceLocator().guestPhoneStorage.getPhoneNumber();
      if (guestPhone == null || guestPhone.isEmpty) {
        FlutterErrorLogger.logInfo(
            '[문자전송] 게스트 전화번호 없음, 입력 화면으로 이동');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: widget.result),
            ),
          );
        }
        return;
      }
    }

    final userAuth = ref.read(userAuthProvider);

    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();

    final guestPhone =
        await ServiceLocator().guestPhoneStorage.getPhoneNumber();

    final measureId = ref.read(measureIdProvider);

    final verifiedUserData =
        await ServiceLocator().verifiedUserStorage.getAllData();
    final verifiedPhone = verifiedUserData['phoneNumber'];

    if (kioskOption == null) {
      FlutterErrorLogger.logWarning('[문자전송] KioskOption 없음');
      return;
    }

    final isServiceMode = kioskOption.mode == 1;
    FlutterErrorLogger.logInfo(
        '[문자 전송] Mode: ${kioskOption.mode}, UseCert: ${kioskOption.usecert}, VerifiedPhone: ${verifiedPhone != null ? "있음" : "없음"}, GuestPhone: ${guestPhone != null ? "있음" : "없음"}');

    if (isServiceMode) {
      if (kioskOption.usecert == 1) {
        if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
          try {
            final token = await ServiceLocator().tokenStorage.getToken();
            if (token == null) {
              return;
            }

            // updateResultUser로 사용자 정보 업데이트
            final currentMeasureId = ref.read(measureIdProvider);
            if (currentMeasureId != null && currentMeasureId.isNotEmpty) {
              final verifiedUserData = await ServiceLocator().verifiedUserStorage.getAllData();
              final birthday = verifiedUserData['birthday'];
              final gender = verifiedUserData['gender'];
              
              try {
                await ServiceLocator().authRepository.updateResultUser(
                  token: token,
                  measureid: currentMeasureId,
                  userid: verifiedPhone,
                  type: 'PHONE',
                  birth: birthday,
                  gender: gender,
                );
                FlutterErrorLogger.logInfo('[문자전송] updateResultUser 완료 MeasureId: $currentMeasureId, Phone: $verifiedPhone');
              } catch (e) {
                FlutterErrorLogger.logError('[문자전송] updateResultUser 실패', e);
              }
            }

            final status = BloodPressureCalculator.getStatus(
              widget.result.systolic,
              widget.result.diastolic,
              context,
            );
            final resultText = _buildResultText(status);
            final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
            final dateText = dateFormat.format(widget.result.measuredAt);
            final place = kioskOption.place;

            FlutterErrorLogger.logInfo(
                '[문자전송] SMS 전송 시작 Type: RESULT_GUEST, Phone: $verifiedPhone');
            await ServiceLocator().authRepository.sendSms(
                  token: token,
                  type: 'RESULT_GUEST',
                  phonenumber: verifiedPhone,
                  result: _combinedResultText(resultText),
                  date: dateText,
                  place: place,
                );

            FlutterErrorLogger.logInfo('[문자전송] SMS 전송 성공');
            if (mounted) {
              SendResultSuccessModal.show(
                context,
                onConfirm: () {
                  FlutterErrorLogger.logInfo('[문자전송] 전송 성공 모달 확인');
                  SendResultSuccessModal.hide(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }
            return;
          } catch (e) {
            FlutterErrorLogger.logError('[문자전송] SMS 전송 실패', e);
            return;
          }
        }

        FlutterErrorLogger.logInfo('[화면이동] 인증 화면으로 이동 (생년월일)');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AuthScreenWithBirthdayGender(result: widget.result),
            ),
          );
        }
        return;
      } else if (kioskOption.usecert == 2) {
        final stepParts = kioskOption.step.split(';');
        final isStep12 = stepParts.length >= 2 &&
            stepParts[0].trim() == '1' &&
            stepParts[1].trim() == '2';

        if (isStep12 && guestPhone != null && guestPhone.isNotEmpty) {
          try {
            final token = await ServiceLocator().tokenStorage.getToken();
            if (token == null) {
              return;
            }

            // updateResultUser로 전화번호 업데이트
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
                FlutterErrorLogger.logInfo('[문자전송] updateResultUser 완료 MeasureId: $currentMeasureId, Phone: $guestPhone');
              } catch (e) {
                FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
              }
            }

            final status = BloodPressureCalculator.getStatus(
              widget.result.systolic,
              widget.result.diastolic,
              context,
            );
            final resultText = _buildResultText(status);
            final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
            final dateText = dateFormat.format(widget.result.measuredAt);
            final place = kioskOption.place;

            await ServiceLocator().authRepository.sendSms(
                  token: token,
                  type: 'RESULT_GUEST',
                  phonenumber: guestPhone,
                  result: _combinedResultText(resultText),
                  date: dateText,
                  place: place,
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
          } catch (e) {
            return;
          }
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: widget.result),
            ),
          );
        }
        return;
      }
    }

    // mode 2 (게스트 모드)인 경우
    if (!isServiceMode) {
      // 인증 완료 여부 확인
      // 전화번호: verifiedPhone (AuthScreenWithBirthdayGender) 또는 userAuth?.phonenumber (AuthScreen)
      // measureId: userAuth?.measureid 또는 measureId provider
      final hasUserAuthMeasureId =
          userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;
      final hasUserAuthPhone =
          userAuth?.phonenumber != null && userAuth!.phonenumber!.isNotEmpty;
      final hasVerifiedPhone =
          verifiedPhone != null && verifiedPhone.isNotEmpty;
      final hasMeasureId = measureId != null && measureId.isNotEmpty;

      // 전화번호가 있는지 확인 (둘 중 하나라도)
      final hasPhone = hasVerifiedPhone || hasUserAuthPhone;
      // measureId가 있는지 확인 (둘 중 하나라도)
      final hasAuthId = hasUserAuthMeasureId || hasMeasureId;
      final isAuthenticated = hasPhone && hasAuthId;

      FlutterErrorLogger.logInfo(
          '[문자전송] Mode2 인증 상태: HasPhone: $hasPhone, HasAuthId: $hasAuthId, IsAuthenticated: $isAuthenticated');

      final isGuestMode = ref.read(guestModeProvider);

      if (isGuestMode) {
        // 게스트 모드인 경우: 게스트 전화번호 입력 화면으로 이동
        FlutterErrorLogger.logInfo('[화면이동] 게스트 전화번호 입력 화면으로 이동');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: widget.result),
            ),
          );
        }
        return;
      }

      if (isAuthenticated) {
        try {
          final token = await ServiceLocator().tokenStorage.getToken();
          if (token == null) {
            FlutterErrorLogger.logWarning('[문자전송] Token 없음');
            return;
          }

          final status = BloodPressureCalculator.getStatus(
            widget.result.systolic,
            widget.result.diastolic,
            context,
          );
          final resultText = _buildResultText(status);
          final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
          final dateText = dateFormat.format(widget.result.measuredAt);
          final place = kioskOption.place;
          final phoneNumber =
              hasVerifiedPhone ? verifiedPhone : userAuth!.phonenumber;

          FlutterErrorLogger.logInfo(
              '[문자전송] Mode2 SMS 전송 시작 Phone: $phoneNumber');
          await ServiceLocator().authRepository.sendSms(
                token: token,
                type: 'RESULT_GUEST',
                phonenumber: phoneNumber,
                result: _combinedResultText(resultText),
                date: dateText,
                place: place,
              );

          FlutterErrorLogger.logInfo('[문자전송] Mode2 SMS 전송 성공');
          if (mounted) {
            SendResultSuccessModal.show(
              context,
              onConfirm: () {
                FlutterErrorLogger.logInfo('[문자전송] 전송 성공 모달 확인');
                SendResultSuccessModal.hide(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            );
          }
          return;
        } catch (e) {
          FlutterErrorLogger.logError('[문자전송] Mode2 SMS 전송 실패', e);
          return;
        }
      }

      FlutterErrorLogger.logInfo('[화면이동] 게스트 전화번호 입력 화면으로 이동');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuestPhoneInputScreen(result: widget.result),
          ),
        );
      }
      return;
    }

    // mode 1 (서비스 모드)의 추가 처리
    final stepParts = kioskOption.step.split(';');
    final isServiceModeStep12 = isServiceMode &&
        stepParts.length >= 2 &&
        stepParts[0].trim() == '1' &&
        stepParts[1].trim() == '2';
    final isServiceModeStep13452 = isServiceMode &&
        stepParts.length >= 5 &&
        stepParts[0].trim() == '1' &&
        stepParts[1].trim() == '3' &&
        stepParts[2].trim() == '4' &&
        stepParts[3].trim() == '5' &&
        stepParts[4].trim() == '2';
    final isServiceModeWithPhone =
        isServiceModeStep12 && guestPhone != null && guestPhone.isNotEmpty;
    final isGuestModeWithMeasureId = isServiceMode &&
        kioskOption.usecert == 1 &&
        measureId != null &&
        measureId.isNotEmpty &&
        verifiedPhone != null &&
        verifiedPhone.isNotEmpty;
    final isStep13452WithAuth = isServiceModeStep13452 &&
        kioskOption.usecert == 1 &&
        measureId != null &&
        measureId.isNotEmpty;

    if (isStep13452WithAuth) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AuthScreenWithBirthdayGender(result: widget.result),
          ),
        );
      }
      return;
    }

    // mode 1에서 인증이 필요한 경우 (회원가입 모달에서 "아니오"를 누른 경우 등)
    if (isServiceMode) {
      final hasUserAuth =
          userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;

      if (!hasUserAuth &&
          !isServiceModeWithPhone &&
          !isGuestModeWithMeasureId) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuestPhoneInputScreen(result: widget.result),
            ),
          );
        }
        return;
      }
    }

    try {
      final token = await ServiceLocator().tokenStorage.getToken();

      if (token == null) {
        return;
      }

      final status = BloodPressureCalculator.getStatus(
        widget.result.systolic,
        widget.result.diastolic,
        context,
      );
      final resultText = _buildResultText(status);

      if (isServiceModeWithPhone || isGuestModeWithMeasureId) {
        final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
        final dateText = dateFormat.format(widget.result.measuredAt);
        final place = kioskOption.place;
        final phoneNumber =
            isGuestModeWithMeasureId ? verifiedPhone : guestPhone;

        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT_GUEST',
              phonenumber: phoneNumber,
              result: _combinedResultText(resultText),
              date: dateText,
              place: place,
            );
      } else {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT',
              measureid: userAuth!.measureid,
              result: _combinedResultText(resultText),
            );
      }

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
      return;
    }
  }

  String _buildResultText(String status) {
    final l10n = AppLocalizations.of(context)!;
    return '''▶${l10n.bloodPressure}
- ${l10n.systolicBloodPressure}: ${widget.result.systolic} ${l10n.mmHg}
- ${l10n.diastolicBloodPressure}: ${widget.result.diastolic} ${l10n.mmHg}
- ${l10n.pulse}: ${widget.result.pulse} ${l10n.bpm}
- ${l10n.measurementResult}: $status''';
  }

  void _toggleHideResult() {
    setState(() {
      _isHidden = !_isHidden;
    });
    if (!_isHidden) {
      resetCurrentTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = BloodPressureCalculator.getStatus(
      widget.result.systolic,
      widget.result.diastolic,
      context,
    );
    final statusColor = BloodPressureConstants.getStatusColor(status);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final screenHeight = MediaQuery.of(context).size.height;

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
          decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: isMobile
                      ? (screenHeight < 850 ? 96.0 : 112.0)
                      : (DeviceConfig().isTabletSized(context)
                          ? _getResponsiveSize(context, 200)
                          : _getResponsiveSize(context, 320)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 0 : _getResponsiveSize(context, 50)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: ClampingScrollPhysics(),
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: isMobile ? 0 : _getResponsiveSize(context, 30),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: isMobile
                                      ? (screenWidth * 3 / 4)
                                      : _getResponsiveSize(context, 620),
                                  alignment: _isHidden ? Alignment.center : Alignment.topCenter,
                                  child: _isHidden
                                      ? _buildHiddenContent(context)
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.topCenter,
                                          child: SizedBox(
                                            width: screenWidth,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                    height: isMobile ? _getResponsiveSize(context, 140) : _getResponsiveSize(
                                                        context, 60)),
                                                _buildVitalsInfo(context),
                                                SizedBox(
                                                  height: _getResponsiveSize(
                                                    context,
                                                    10,
                                                  ),
                                                ),
                                                _buildStatusSection(
                                                  context,
                                                  status,
                                                  statusColor,
                                                ),
                                                SizedBox(
                                                  height: _getResponsiveSize(
                                                    context,
                                                    10,
                                                  ),
                                                ),
                                                _buildChartSection(context),
                                                SizedBox(
                                                  height: _getResponsiveSize(
                                                    context,
                                                    10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                                _buildVideoSection(context),
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
                  onTap: () => _handleHomeButton(context),
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
          ),
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
      onTap: _toggleHideResult,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isMobile ? Colors.white : Color(0xFFE7EAF3),
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
                color: isMobile ? Color(0xFF505050) : Color(0xFF4C4948),
                letterSpacing: isMobile ? -0.8 : -0.7,
                height: isMobile ? 1.0 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVitalItem(
          context,
          '${widget.result.systolic}',
          l10n.systolicPressure,
          '(${l10n.mmHg})',
        ),
        SizedBox(width: _getResponsiveSize(context, 90)),
        _buildVitalItem(
          context,
          '${widget.result.diastolic}',
          l10n.diastolicPressure,
          '(${l10n.mmHg})',
        ),
        SizedBox(width: _getResponsiveSize(context, 90)),
        _buildVitalItem(
          context,
          '${widget.result.pulse}',
          l10n.pulse,
          '(${l10n.bpm})',
        ),
      ],
    );
  }

  Widget _buildHiddenContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final lockSize = isMobile
        ? _getResponsiveSize(context, 160)
        : _getResponsiveSize(context, 240);
    final topSpace = isMobile
        ? 0.0
        : _getResponsiveSize(context, 80);
    final bottomSpace = isMobile
        ? 0.0
        : _getResponsiveSize(context, 120);

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
              l10n.resultHiddenGuide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 46),
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                color: Color(0xFF227EFF),
                letterSpacing: -1.6,
              ),
            ),
          ),
          SizedBox(height: bottomSpace),
        ],
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    String status,
    Color statusColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _getResponsiveSize(context, 24),
          height: _getResponsiveSize(context, 24),
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
        ),
        SizedBox(width: _getResponsiveSize(context, 15)),
        Text(
          status,
          style: TextStyle(
            fontFamily: AppTextStyles.titleFontFamily,
            fontSize: _getResponsiveSize(context, 72),
            color: Color(0xFF111111),
            letterSpacing: -1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalItem(
    BuildContext context,
    String value,
    String label1,
    String label2,
  ) {
    return Column(
      children: [
        Text(
          label1,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 32),
            color: Color(0xFF505050),
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 8)),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.titleFontFamily,
            fontSize: _getResponsiveSize(context, 90),
            color: Color(0xFF111111),
            letterSpacing: -2.25,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 8)),
        Text(
          label2,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 32),
            color: Color(0xFF505050),
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : _getResponsiveSize(context, 800),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 0.0 : _getResponsiveSize(context, 20),
          ),
          child: BloodPressureChart(
            systolic: widget.result.systolic,
            diastolic: widget.result.diastolic,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    final pageOption = ref.read(resultPageOptionProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double width = isMobile
        ? screenWidth
        : _getResponsiveSize(context, 1024);
    final double height = isMobile
        ? (width * 9.0 / 16.0)
        : _getResponsiveSize(context, 576);

    if (pageOption == null || pageOption.cm.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: MeasurementMediaPlayer(
        key: ValueKey('result_video_$_videoKey'),
        mediaItems: pageOption.cm,
        baseUrl: Config.baseUrl,
        playerId: 'result_video',
        isActive: _isVideoActive,
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : _getResponsiveSize(context, 28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            context,
            icon: 'assets/icons/refresh.svg',
            label: l10n.remeasure,
            onTap: _handleRetry,
          ),
          if (_isSmsEnabled) ...[
            SizedBox(width: isMobile ? 12.0 : _getResponsiveSize(context, 28)),
            _buildActionButton(
              context,
              icon: 'assets/icons/message.svg',
              label: l10n.sendMessage,
              onTap: _handleSendMessage,
            ),
          ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double width = isMobile
        ? (screenWidth - 48) / (_isSmsEnabled ? 2 : 1)
        : _getResponsiveSize(context, 498);
    final double height = isMobile
        ? 64.0
        : _getResponsiveSize(context, 255);
    final double borderRadius = isMobile
        ? 12.0
        : _getResponsiveSize(context, 32);
    final double iconSize = isMobile
        ? 24.0
        : _getResponsiveSize(context, 80);
    final double gap = isMobile
        ? 4.0
        : _getResponsiveSize(context, 24);
    final double fontSize = isMobile
        ? 12.0
        : _getResponsiveSize(context, 32);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              offset: Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 0,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: gap),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
