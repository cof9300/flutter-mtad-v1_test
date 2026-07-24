import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/core/widget/error_modal.dart';
import 'package:flutter_template/core/widget/kiosk_id_required_modal.dart';
import 'package:flutter_template/core/widget/info_modal.dart';
import 'package:flutter_template/core/widget/register_confirm_modal.dart';
import 'package:flutter_template/core/widget/user_confirm_modal.dart';
import 'package:flutter_template/core/widget/phone_check_modal.dart';
import 'package:flutter_template/auth/widget/registration_complete_modal.dart';
import 'package:flutter_template/auth/widget/landscape_auth_layout.dart';
import 'package:flutter_template/auth/widget/portrait_auth_layout.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/height_weight_calculator.dart';
import 'package:flutter_template/core/utils/pending_result_save_flag.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/alco_measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/hrv_info_input_screen.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/selected_device_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/core/utils/phone_validator.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/data/model/response/user_auth_response.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_mode_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/main.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool returnToPreviousScreen;
  final BloodPressureResult? pendingResultForGuestSave;
  final HeightWeightResult? pendingHwResultForGuestSave;

  const AuthScreen({
    super.key,
    this.returnToPreviousScreen = false,
    this.pendingResultForGuestSave,
    this.pendingHwResultForGuestSave,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with AutoReturnMixin, RouteAware {
  String _inputValue = '';
  final _serviceLocator = ServiceLocator();
  UserAuthResponse? _lastAuthResponse;
  String? _lastNextstep; // 이전 응답의 nextstep 저장
  int _certTime = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    cancelAutoReturnTimer();
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
  void didPush() {
    super.didPush();
    // 화면이 push될 때마다 기존 타이머 취소 후 새 타이머 시작
    cancelAutoReturnTimer();
    _initializeTimer();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    cancelAutoReturnTimer();
    UserConfirmModal.hide();
    RegisterConfirmModal.hide();
    RegistrationCompleteModal.hide();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _initializeTimer();
  }

  @override
  Future<void> onBeforeAutoReturn() async {
    cancelAutoReturnTimer();
    UserConfirmModal.hide();
    RegisterConfirmModal.hide();
    RegistrationCompleteModal.hide();
    if (widget.returnToPreviousScreen &&
        widget.pendingResultForGuestSave != null &&
        mounted) {
      await _savePendingResultAsGuest();
    }
    if (widget.returnToPreviousScreen &&
        widget.pendingHwResultForGuestSave != null &&
        mounted) {
      await _saveHwPendingResultAsGuest();
    }
  }

  Future<void> _savePendingResultAsGuest() async {
    final r = widget.pendingResultForGuestSave;
    if (r == null || !mounted) return;
    PendingResultSaveFlag.guestSaveHandledByAuth = true;
    try {
      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null) return;
      final result = BloodPressureCalculator.createResultData(
        systolic: r.systolic,
        diastolic: r.diastolic,
        pulse: r.pulse,
        context: context,
      );
      final setResultResponse = await _serviceLocator.authRepository.setResult(
        token: token,
        measureid: '',
        device: 'BP',
        result: result,
        serviceforce: 'true',
      );
      final finalMeasureId = setResultResponse.measureid != null &&
              setResultResponse.measureid!.isNotEmpty
          ? setResultResponse.measureid!
          : '';
      if (finalMeasureId.isNotEmpty && mounted) {
        ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
      }
    } catch (_) {}
  }

  Future<void> _saveHwPendingResultAsGuest() async {
    final r = widget.pendingHwResultForGuestSave;
    if (r == null || !mounted) return;
    PendingResultSaveFlag.guestSaveHandledByAuth = true;
    try {
      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null) return;
      final result = HeightWeightCalculator.createResultData(
        height: r.height,
        weight: r.weight,
        bmi: r.bmi,
        context: context,
      );
      final setResultResponse = await _serviceLocator.authRepository.setResult(
        token: token,
        measureid: '',
        device: 'HS',
        result: result,
        serviceforce: 'true',
      );
      final finalMeasureId = setResultResponse.measureid != null &&
              setResultResponse.measureid!.isNotEmpty
          ? setResultResponse.measureid!
          : '';
      if (finalMeasureId.isNotEmpty && mounted) {
        ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    UserConfirmModal.hide();
    RegisterConfirmModal.hide();
    RegistrationCompleteModal.hide();
    if (widget.returnToPreviousScreen && _inputValue.isNotEmpty) {
      final digits = PhoneValidator.extractDigits(_inputValue);
      if (digits.isNotEmpty) {
        _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
        print('[AuthScreen dispose] 전화번호 저장: $digits');
      }
    }
    cancelAutoReturnTimer();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    cancelAutoReturnTimer();
    _certTime = 10;
    startAutoReturnTimer(_certTime);
  }

  void _resetTimer() {
    if (_certTime > 0) {
      resetAutoReturnTimer(_certTime);
    }
  }

  void _onNumberPressed(String number) {
    if (!PhoneValidator.canAddDigit(_inputValue)) return;

    _resetTimer();
    setState(() {
      _inputValue += number;
    });
  }

  void _onClearAll() {
    _resetTimer();
    setState(() {
      _inputValue = '';
    });
  }

  void _onDelete() {
    if (_inputValue.isEmpty) return;

    _resetTimer();
    setState(() {
      _inputValue = _inputValue.substring(0, _inputValue.length - 1);
    });
  }

  bool _validateInput() {
    final digits = PhoneValidator.extractDigits(_inputValue);
    if (digits.isEmpty) return false;
    return true;
  }

  Future<void> _processAuth(String phoneNumber) async {
    try {
      _resetTimer();

      ProgressModal.show(context);

      String? token = await _serviceLocator.tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        print('Token not found, getting new token...');
        try {
          final kioskId = await Config.getKioskId();
      if (kioskId == null || kioskId.isEmpty) {
        ProgressModal.hide();
        if (mounted) {
          if (widget.returnToPreviousScreen && _inputValue.isNotEmpty) {
            final digits = PhoneValidator.extractDigits(_inputValue);
            if (digits.isNotEmpty) {
              _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
            }
          }
          KioskIdRequiredModal.show(context);
        }
        return;
      }
          final authResponse = await _serviceLocator.authRepository.kioskAuth(
            kioskId,
          );
          await _serviceLocator.tokenStorage.saveToken(authResponse.token);
          token = authResponse.token;
          print('New token obtained');
        } catch (e) {
          print('Failed to get new token: $e');
          ProgressModal.hide();
          if (mounted) {
            if (widget.returnToPreviousScreen && _inputValue.isNotEmpty) {
              final digits = PhoneValidator.extractDigits(_inputValue);
              if (digits.isNotEmpty) {
                _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
              }
            }
            ErrorModal.show(context);
          }
          return;
        }
      }

      print('Calling user auth with token: ${token.substring(0, 10)}...');

      final digits = PhoneValidator.extractDigits(phoneNumber);
      final authType = digits.length == 11 ? 'PHONE' : 'ID';

      final response = await _serviceLocator.authRepository.userAuth(
        phoneNumber: phoneNumber,
        token: token,
        type: authType,
      );

      print(
          'User auth response: nextstep=${response.nextstep}, measureid=${response.measureid}');

      ProgressModal.hide();

      if (mounted) {
        try {
          _handleAuthResponse(response, phoneNumber);
        } catch (e) {
          print('Handle auth response error: $e');
          if (widget.returnToPreviousScreen && _inputValue.isNotEmpty) {
            final digits = PhoneValidator.extractDigits(_inputValue);
            if (digits.isNotEmpty) {
              _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
              print('[AuthScreen] 인증 처리 오류 - 전화번호 저장: $digits');
            }
          }
          ErrorModal.show(context);
        }
      }
    } catch (e) {
      print('Process auth error: $e');
      ProgressModal.hide();

      if (mounted) {
        // 인증 실패 시 전화번호 저장 (결과화면 복귀 시 updateResultUser에서 사용)
        if (widget.returnToPreviousScreen && _inputValue.isNotEmpty) {
          final digits = PhoneValidator.extractDigits(_inputValue);
          if (digits.isNotEmpty) {
            _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
            print('[AuthScreen] 인증 실패 - 전화번호 저장: $digits');
          }
        }
        ErrorModal.show(context);
      }
    }
  }

  void _handleAuthResponse(UserAuthResponse response, String phoneNumber) async {
    _lastAuthResponse = response;
    cancelAutoReturnTimer();

    if (response.nextstep.isEmpty && response.measureid == null) {
      _logAuthResponse(response);
      ProgressModal.hide();
      
      if (widget.returnToPreviousScreen && _lastNextstep == 'NOTI' && mounted) {
        _showRegistrationModal(phoneNumber, 'NOTI', response);
        return;
      }
      
      if (mounted) {
        // 인증 실패(API 응답 오류) 시 전화번호 저장
        if (widget.returnToPreviousScreen && phoneNumber.isNotEmpty) {
          final digits = PhoneValidator.extractDigits(phoneNumber);
          if (digits.isNotEmpty) {
            _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
            print('[AuthScreen] 인증 실패(응답) - 전화번호 저장: $digits');
          }
        }
        ErrorModal.show(context);
      }
      return;
    }

    // nextstep 저장
    if (response.nextstep.isNotEmpty) {
      _lastNextstep = response.nextstep;
    }

    if (response.nextstep == 'REGI' || response.nextstep == 'NOTI') {
      // REGI/NOTI: "예" 클릭 시에만 userAuth/measureId 저장 ("아니요" 시 게스트로 측정하므로 저장하지 않음)
      _showRegistrationModal(phoneNumber, response.nextstep, response);
    } else if (response.username != null && response.username!.isNotEmpty) {
      // 인증 성공 모달: "예"를 눌렀을 때만 userAuth/measureId 저장 (모달 표시 시점에는 저장하지 않음)
      _showUserConfirmModal(response);
    } else {
      ref.read(userAuthProvider.notifier).setUserAuth(response);
      if (response.measureid != null && response.measureid!.isNotEmpty) {
        ref.read(measureIdProvider.notifier).setMeasureId(response.measureid!);
      }
      _logAuthResponse(response);
      // 결과 화면에서 왔으면 인증 성공 후 돌아가기
      if (widget.returnToPreviousScreen && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showUserConfirmModal(UserAuthResponse response) {
    if (response.status == '2' || response.status == '3') {
      final l10n = AppLocalizations.of(context)!;
      InfoModal.show(
        context,
        title: l10n.systemErrorTitle,
        message: '관리자에게 문의해주세요.',
      );
      return;
    }

    UserConfirmModal.show(
      context,
      username: response.username ?? '',
      returnToPreviousScreen: widget.returnToPreviousScreen,
      onConfirm: () {
        UserConfirmModal.hide();
        // "예"를 눌렀을 때만 전역 변수에 인증 정보 저장
        ref.read(userAuthProvider.notifier).setUserAuth(response);
        if (response.measureid != null && response.measureid!.isNotEmpty) {
          ref.read(measureIdProvider.notifier).setMeasureId(response.measureid!);
        }
        // 결과 화면에서 왔으면 인증 성공 후 돌아가기
        if (widget.returnToPreviousScreen && mounted) {
          Navigator.of(context).pop();
          return;
        }
        
        // 실제 연결된 기기 수 기준으로 분기
        // (미연결 기기가 있을 경우 장비선택 화면에서 흑백으로 표시되어야 함)
        final allDevices = ref.read(deviceListProvider);
        final hwDevicesWithStatus = ref.read(deviceListWithConnectionProvider);
        final hasMf = ref.read(mfDeviceProvider) != null;
        final totalConfigured = allDevices.length + (hasMf ? 1 : 0);
        final connectedHwDevices =
            hwDevicesWithStatus.where((d) => d.isConnected).toList();

        // 단일 기기 자동 이동: 설정 1개 + 실제 연결 1개 + MF 없음
        if (totalConfigured == 1 &&
            !hasMf &&
            connectedHwDevices.length == 1 &&
            mounted) {
          final device = connectedHwDevices.first;
          ref.read(selectedDeviceProvider.notifier).selectDevice(device.type);
          if (device.type.toUpperCase() == 'AL') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AlcoMeasurementScreen(),
              ),
            );
          } else if (device.type.toUpperCase() == 'ST') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HrvInfoInputScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MeasurementScreen(deviceType: device.type),
              ),
            );
          }
        } else if (mounted) {
          // 미연결 기기가 있거나 설정 기기가 여러 개면 장비선택 화면으로 이동
          // (미연결 기기는 흑백으로 표시되어 선택 불가)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeviceSelectionScreen(),
            ),
          );
        }
      },
      onCancel: () {
        UserConfirmModal.hide();
        _initializeTimer();
      },
    );
  }

  void _showRegistrationModal(
      String phoneNumber, String nextstep, UserAuthResponse response) {
    RegisterConfirmModal.show(
      context,
      phoneNumber: phoneNumber,
      nextstep: nextstep,
      returnToPreviousScreen: widget.returnToPreviousScreen,
      onConfirm: () async {
        RegisterConfirmModal.hide();

        if (nextstep == 'NOTI') {
          final option = await _serviceLocator.kioskOptionStorage.getOption();
          if (option != null && option.mode == 2 && option.nextstep == 'NOTI') {
            ref.read(guestMeasureFlagProvider.notifier).setGuestMeasureFlag(true);
          }
          final digits = PhoneValidator.extractDigits(phoneNumber);
          if (digits.isNotEmpty) {
            _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
          }
          if (mounted) {
            if (widget.returnToPreviousScreen) {
              // 결과화면에서 온 경우 → 결과화면으로 복귀
              // 인증 없음으로 처리되어 didPopNext → _savePendingResultAfterAuth(게스트 저장)
              Navigator.of(context).pop();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceSelectionScreen(),
                ),
              );
            }
          }
          return;
        }

        // nextstep이 REGI일 때: "예" 클릭 시에만 userAuth/measureId 저장 후 회원가입 SMS 전송
        if (nextstep == 'REGI') {
          ref.read(userAuthProvider.notifier).setUserAuth(response);
          if (response.measureid != null &&
              response.measureid!.isNotEmpty) {
            ref.read(measureIdProvider.notifier).setMeasureId(response.measureid!);
          }
        }
        final digits = PhoneValidator.extractDigits(phoneNumber);
        if (digits.length != 11) {
          PhoneCheckModal.show(
            context,
            onClose: () {
              PhoneCheckModal.hide();
            },
          );
          return;
        }

        await _sendRegistrationSms(phoneNumber);
      },
      onCancel: () {
        RegisterConfirmModal.hide();

        if (widget.returnToPreviousScreen && nextstep == 'REGI') {
          // REGI "아니오" 선택 시에도 전화번호 저장 (결과 화면 복귀 시 updateResultUser에서 사용)
          final digits = PhoneValidator.extractDigits(phoneNumber);
          if (digits.isNotEmpty) {
            _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
            print('[AuthScreen] REGI 취소 - 전화번호 저장: $digits');
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }

        if (nextstep == 'REGI') {
          ref.read(userAuthProvider.notifier).clearUserAuth();
          ref.read(measureIdProvider.notifier).clearMeasureId();
          ref.read(guestModeProvider.notifier).setGuestMode(true);
          final digits = PhoneValidator.extractDigits(phoneNumber);
          if (digits.isNotEmpty) {
            _serviceLocator.guestPhoneStorage.savePhoneNumberSync(digits);
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeviceSelectionScreen(),
              ),
            );
          }
          return;
        }

        // NOTI "아니오" 시 AuthScreen에 머물므로 타이머 재시작
        _initializeTimer();
      },
    );
  }

  Future<void> _sendRegistrationSms(String phoneNumber) async {
    try {
      ProgressModal.show(context);

      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null) {
        ProgressModal.hide();
        if (mounted) {
          ErrorModal.show(context);
        }
        return;
      }

      await _serviceLocator.authRepository.sendSms(
        token: token,
        type: 'REGI',
        measureid: _lastAuthResponse?.measureid,
        phonenumber: phoneNumber,
      );

      ProgressModal.hide();

      if (mounted) {
        RegistrationCompleteModal.show(context);
      }
    } catch (e) {
      ProgressModal.hide();

      if (mounted) {
        ErrorModal.show(context);
      }
    }
  }

  void _logAuthResponse(UserAuthResponse response) {
    debugPrint('User Auth Response: $response');
    debugPrint('measureid: ${response.measureid}');
    debugPrint('username: ${response.username}');
    debugPrint('nextstep: ${response.nextstep}');
    debugPrint('status: ${response.status}');
    debugPrint('gender: ${response.gender}');
    debugPrint('birthday: ${response.birthday}');
    debugPrint('phonenumber: ${response.phonenumber}');
  }

  Future<void> _onConfirm() async {
    if (!_validateInput()) return;

    final phoneNumber = PhoneValidator.extractDigits(_inputValue);
    await _processAuth(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final topPadding = (screenSize.height * 0.03).clamp(15.0, 30.0);

    return GestureDetector(
      onTapDown: (_) => _resetTimer(),
      onPanDown: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
          ),
          child: Column(
            children: [
              HomeButton(
                onTap: () async {
                  if (widget.returnToPreviousScreen) {
                    if (widget.pendingResultForGuestSave != null) {
                      await _savePendingResultAsGuest();
                    }
                    if (widget.pendingHwResultForGuestSave != null) {
                      await _saveHwPendingResultAsGuest();
                    }
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                topPadding: topPadding,
                leftPadding: topPadding,
              ),
              Expanded(
                child: isLandscape
                    ? LandscapeAuthLayout(
                        inputValue: _inputValue,
                        inputHint: l10n.authInputHint,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                      )
                    : PortraitAuthLayout(
                        inputValue: _inputValue,
                        inputHint: l10n.authInputHint,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
