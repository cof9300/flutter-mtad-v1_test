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
import 'package:flutter_template/auth/widget/landscape_auth_with_birthday_gender_layout.dart';
import 'package:flutter_template/auth/widget/portrait_auth_with_birthday_gender_layout.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/core/utils/phone_validator.dart';
import 'package:flutter_template/core/utils/birthday_validator.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/utils/cert_number_generator.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/alco_measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/hrv_info_input_screen.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/selected_device_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/height_weight_calculator.dart';
import 'package:flutter_template/core/utils/hrv_result_calculator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

enum InputMode { birthday, phone, verificationCode }

class AuthScreenWithBirthdayGender extends ConsumerStatefulWidget {
  final BloodPressureResult? result;
  final AlcoMeasurementResult? alcoResult;
  final HeightWeightResult? hwResult;
  final HrvMeasurementResult? hrvResult;

  const AuthScreenWithBirthdayGender({
    super.key,
    this.result,
    this.alcoResult,
    this.hwResult,
    this.hrvResult,
  });

  @override
  ConsumerState<AuthScreenWithBirthdayGender> createState() =>
      _AuthScreenWithBirthdayGenderState();
}

class _AuthScreenWithBirthdayGenderState
    extends ConsumerState<AuthScreenWithBirthdayGender>
    with AutoReturnMixin, RouteAware {
  String _phoneInputValue = '010';
  String _birthdayInputValue = '';
  String _selectedGender = 'M';
  String _verificationCode = '';
  String? _generatedCertNumber;
  String? _phoneAtAuthRequest;
  bool _isAuthRequested = false;
  bool _isVerified = false;
  InputMode _currentInputMode = InputMode.birthday;
  final _serviceLocator = ServiceLocator();
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
    // 다른 화면으로 이동할 때 타이머 취소
    cancelAutoReturnTimer();
  }

  @override
  void dispose() {
    cancelAutoReturnTimer();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    // 기존 타이머 명시적으로 취소
    cancelAutoReturnTimer();

    final option = await _serviceLocator.kioskOptionStorage.getOption();
    if (option != null && option.certtime > 0) {
      _certTime = option.certtime;
      startAutoReturnTimer(_certTime);
    }
  }

  void _resetTimer() {
    if (_certTime > 0) {
      resetAutoReturnTimer(_certTime);
    }
  }

  void _onNumberPressed(String number) {
    _resetTimer();

    if (_currentInputMode == InputMode.birthday) {
      if (!BirthdayValidator.canAddDigit(_birthdayInputValue, number)) return;
      final newValue = _birthdayInputValue + number;
      final digits = BirthdayValidator.extractDigits(newValue);
      if (digits.length == 8 && !BirthdayValidator.isValid(newValue)) {
        return;
      }
      setState(() {
        _birthdayInputValue = newValue;
        final newDigits = BirthdayValidator.extractDigits(newValue);
        if (newDigits.length == 8 && BirthdayValidator.isValid(newValue)) {
          _currentInputMode = InputMode.phone;
        }
      });
    } else if (_currentInputMode == InputMode.phone) {
      if (!PhoneValidator.canAddDigit(_phoneInputValue)) return;
      setState(() {
        _phoneInputValue += number;
      });
    } else if (_currentInputMode == InputMode.verificationCode) {
      if (_verificationCode.length >= 4) return;
      setState(() {
        _verificationCode += number;
      });
    }
  }

  void _onClearAll() {
    _resetTimer();
    setState(() {
      if (_currentInputMode == InputMode.birthday) {
        _birthdayInputValue = '';
      } else if (_currentInputMode == InputMode.phone) {
        _phoneInputValue = '';
      } else if (_currentInputMode == InputMode.verificationCode) {
        _verificationCode = '';
      }
    });
  }

  void _onDelete() {
    _resetTimer();
    setState(() {
      if (_currentInputMode == InputMode.birthday) {
        if (_birthdayInputValue.isNotEmpty) {
          _birthdayInputValue = _birthdayInputValue.substring(
            0,
            _birthdayInputValue.length - 1,
          );
        }
      } else if (_currentInputMode == InputMode.phone) {
        if (_phoneInputValue.isNotEmpty) {
          _phoneInputValue = _phoneInputValue.substring(
            0,
            _phoneInputValue.length - 1,
          );
        }
      } else if (_currentInputMode == InputMode.verificationCode) {
        if (_verificationCode.isNotEmpty) {
          _verificationCode = _verificationCode.substring(
            0,
            _verificationCode.length - 1,
          );
        }
      }
    });
  }

  void _onInputFieldTapped(InputMode mode) {
    setState(() {
      _currentInputMode = mode;
    });
  }

  void _onGenderSelected(String gender) {
    _resetTimer();
    setState(() {
      _selectedGender = gender;
      final digits = BirthdayValidator.extractDigits(_birthdayInputValue);
      if (digits.length == 8 &&
          BirthdayValidator.isValid(_birthdayInputValue)) {
        _currentInputMode = InputMode.phone;
      }
    });
  }

  Future<void> _onRequestAuth() async {
    _resetTimer();
    FlutterErrorLogger.logInfo('[사용자인증] 인증 요청 버튼 클릭');
    final l10n = AppLocalizations.of(context)!;

    final phoneDigits = PhoneValidator.extractDigits(_phoneInputValue);
    final birthdayDigits = BirthdayValidator.extractDigits(_birthdayInputValue);

    if (phoneDigits.length != 11) {
      FlutterErrorLogger.logWarning('[사용자인증] 전화번호 형식 오류');
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterPhoneNumberCorrectly,
      );
      return;
    }

    if (birthdayDigits.length != 8 ||
        !BirthdayValidator.isValid(_birthdayInputValue)) {
      FlutterErrorLogger.logWarning('[사용자인증] 생년월일 형식 오류');
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterBirthday,
      );
      return;
    }

    try {
      ProgressModal.show(context);
      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null) {
        FlutterErrorLogger.logWarning('[사용자인증] 인증 요청 Token 없음');
        ProgressModal.hide();
        if (mounted) {
          ErrorModal.show(context);
        }
        return;
      }

      final certNumber = CertNumberGenerator.generate();
      _generatedCertNumber = certNumber;

      FlutterErrorLogger.logInfo(
          '[문자전송] 인증번호 SMS 전송 시작 Phone: $phoneDigits');
      await _serviceLocator.authRepository.sendSms(
        token: token,
        type: 'CERT',
        phonenumber: phoneDigits,
        certnumber: certNumber,
      );

      FlutterErrorLogger.logInfo('[문자전송] 인증번호 SMS 전송 성공');
      ProgressModal.hide();
      if (mounted) {
        setState(() {
          _phoneAtAuthRequest = phoneDigits;
          _isAuthRequested = true;
          _currentInputMode = InputMode.verificationCode;
          _verificationCode = '';
        });
      }
    } catch (e) {
      FlutterErrorLogger.logError('[문자전송] 인증번호 SMS 전송 실패', e);
      ProgressModal.hide();
      if (mounted) {
        ErrorModal.show(context);
      }
    }
  }

  Future<void> _verifyCertNumber() async {
    FlutterErrorLogger.logInfo('[사용자인증] 인증번호 확인 시작');
    final l10n = AppLocalizations.of(context)!;
    if (_verificationCode.length != 4) {
      FlutterErrorLogger.logWarning('[사용자인증] 인증번호 길이 오류');
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterVerificationCode4Digits,
      );
      return;
    }

    if (_generatedCertNumber == null) {
      FlutterErrorLogger.logWarning('[사용자인증] 인증번호 없음');
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.requestVerificationCodeFirst,
      );
      return;
    }

    if (_verificationCode != _generatedCertNumber) {
      FlutterErrorLogger.logWarning('[사용자인증] 인증번호 불일치');
      InfoModal.show(
        context,
        title: l10n.verificationFailed,
        message: l10n.verificationCodeMismatch,
      );
      return;
    }

    if (_phoneAtAuthRequest == null || _phoneAtAuthRequest!.isEmpty) {
      FlutterErrorLogger.logWarning('[사용자인증] 인증 요청 시 전화번호 없음');
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.requestVerificationCodeFirst,
      );
      return;
    }

    final phoneDigits = _phoneAtAuthRequest!;
    final birthdayDigits = BirthdayValidator.extractDigits(_birthdayInputValue);
    final gender = _selectedGender;

    FlutterErrorLogger.logInfo('[사용자인증] 인증번호 확인 성공, 사용자 정보 저장');
    await _serviceLocator.verifiedUserStorage.saveUserData(
      phoneNumber: phoneDigits,
      birthday: birthdayDigits,
      gender: gender,
    );

    setState(() {
      _isVerified = true;
    });
  }

  Future<void> _onConfirm() async {
    FlutterErrorLogger.logInfo('[사용자인증] 확인 버튼 클릭');
    if (!_isVerified) {
      if (_isAuthRequested) {
        await _verifyCertNumber();
        if (!_isVerified) {
          return;
        }
      } else {
        FlutterErrorLogger.logWarning('[사용자인증] 인증 요청 필요');
        final l10n = AppLocalizations.of(context)!;
        InfoModal.show(
          context,
          title: l10n.authRequired,
          message: l10n.requestAuthFirst,
        );
        return;
      }
    }

    final l10n = AppLocalizations.of(context)!;
    final userData = await _serviceLocator.verifiedUserStorage.getAllData();
    final phoneNumber = userData['phoneNumber'];
    final birthday = userData['birthday'];
    final gender = userData['gender'];

    if (phoneNumber == null || birthday == null || gender == null) {
      FlutterErrorLogger.logWarning('[사용자인증] 사용자 정보 없음');
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.authInfoNotFound,
      );
      return;
    }

    try {
      _resetTimer();
      ProgressModal.show(context);
      FlutterErrorLogger.logInfo(
          '[사용자인증] 인증 처리 시작 - Phone: $phoneNumber, HasResult: ${widget.result != null}');

      String? token = await _serviceLocator.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        try {
          final kioskId = await Config.getKioskId();
          if (kioskId == null || kioskId.isEmpty) {
            ProgressModal.hide();
            if (mounted) {
              KioskIdRequiredModal.show(context);
            }
            return;
          }
          final authResponse = await _serviceLocator.authRepository.kioskAuth(
            kioskId,
          );
          await _serviceLocator.tokenStorage.saveToken(authResponse.token);
          token = authResponse.token;
        } catch (e) {
          ProgressModal.hide();
          if (mounted) {
            ErrorModal.show(context);
          }
          return;
        }
      }

      if (widget.result != null ||
          widget.alcoResult != null ||
          widget.hwResult != null ||
          widget.hrvResult != null) {
        final measureId = ref.read(measureIdProvider);
        if (measureId == null || measureId.isEmpty) {
          ProgressModal.hide();
          if (mounted) {
            InfoModal.show(
              context,
              title: l10n.error,
              message: l10n.measurementInfoNotFound,
            );
          }
          return;
        }

        FlutterErrorLogger.logInfo(
            '[측정결과] 사용자 정보 업데이트 시작 MeasureId: $measureId');
        await _serviceLocator.authRepository.updateResultUser(
          token: token,
          measureid: measureId,
          userid: phoneNumber,
          type: 'PHONE',
          birth: birthday,
          gender: gender,
        );

        FlutterErrorLogger.logInfo('[측정결과] 사용자 정보 업데이트 성공');
        final kioskOption =
            await _serviceLocator.kioskOptionStorage.getOption();

        final String resultText;
        final String dateText;
        final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

        if (widget.alcoResult != null) {
          resultText =
              '▶음주\n- 음주 결과: ${widget.alcoResult!.isPass ? 'PASS' : 'FAIL'}\n- 음주량: ${widget.alcoResult!.bacValueText}';
          dateText = dateFormat.format(widget.alcoResult!.measuredAt);
        } else if (widget.hwResult != null) {
          final status = HeightWeightCalculator.getBmiStatus(widget.hwResult!.bmi, context);
          resultText = '▶신장체중\n- 신장: ${widget.hwResult!.height} cm\n- 체중: ${widget.hwResult!.weight} kg\n- BMI: ${widget.hwResult!.bmi.toStringAsFixed(1)}\n- 측정결과: $status';
          dateText = dateFormat.format(widget.hwResult!.measuredAt);
        } else if (widget.hrvResult != null) {
          final basic = widget.hrvResult!.basic;
          resultText = '''▶자율신경계
- 종합점수: ${basic.totalScore.toStringAsFixed(1)}점
- 자율신경 활성도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.tpScore))}
- 스트레스 대처능력: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.sdnnScore))}
- 피로도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.lfScore))}''';
          dateText = dateFormat.format(widget.hrvResult!.measuredAt);
        } else {
          final status = BloodPressureCalculator.getStatus(
            widget.result!.systolic,
            widget.result!.diastolic,
            context,
          );
          resultText = _buildResultText(status);
          dateText = dateFormat.format(widget.result!.measuredAt);
        }

        final place = kioskOption?.place;

        FlutterErrorLogger.logInfo('[문자전송] 결과 SMS 전송 시작');
        await _serviceLocator.authRepository.sendSms(
          token: token,
          type: 'RESULT_GUEST',
          phonenumber: phoneNumber,
          result: resultText,
          date: dateText,
          place: place,
        );

        FlutterErrorLogger.logInfo('[문자전송] 결과 SMS 전송 성공');
        ProgressModal.hide();

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
      }

      FlutterErrorLogger.logInfo('[사용자인증] 사용자 인증 시작');
      final authResponse = await _serviceLocator.authRepository.userAuth(
        phoneNumber: phoneNumber,
        token: token,
        birthday: birthday,
        gender: gender,
        serviceforce: 'true',
      );

      FlutterErrorLogger.logInfo(
          '[사용자인증] 인증 성공 MeasureId: ${authResponse.measureid ?? "없음"}');
      ref.read(userAuthProvider.notifier).setUserAuth(authResponse);

      if (authResponse.measureid != null &&
          authResponse.measureid!.isNotEmpty) {
        ref
            .read(measureIdProvider.notifier)
            .setMeasureId(authResponse.measureid!);
      }

      ProgressModal.hide();

      if (mounted) {
        final kioskOption =
            await _serviceLocator.kioskOptionStorage.getOption();

        if (kioskOption != null && kioskOption.mode == 1) {
          final stepParts = kioskOption.step.split(';');
          if (stepParts.length >= 2 &&
              stepParts[0].trim() == '1' &&
              stepParts[1].trim() == '2') {
            // 실제 연결된 기기 수 기준으로 분기
            // (미연결 기기가 있을 경우 장비선택 화면에서 흑백으로 표시되어야 함)
            final allDevices = ref.read(deviceListProvider);
            final hwDevicesWithStatus =
                ref.read(deviceListWithConnectionProvider);
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceSelectionScreen(),
                ),
              );
            }
            return;
          }
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      ProgressModal.hide();
      if (mounted) {
        ErrorModal.show(context);
      }
    }
  }

  String _buildResultText(String status) {
    if (widget.result == null) {
      return '';
    }
    final l10n = AppLocalizations.of(context)!;
    return '''▶${l10n.bloodPressure}
- ${l10n.systolicBloodPressure}: ${widget.result!.systolic} ${l10n.mmHg}
- ${l10n.diastolicBloodPressure}: ${widget.result!.diastolic} ${l10n.mmHg}
- ${l10n.pulse}: ${widget.result!.pulse} ${l10n.bpm}
- ${l10n.measurementResult}: $status''';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final topPadding = (screenSize.height * 0.01).clamp(5.0, 15.0);

    return GestureDetector(
      onTapDown: (_) => _resetTimer(),
      onPanDown: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Column(
            children: [
              HomeButton(
                onTap: () {
                  FlutterErrorLogger.logInfo('[화면이동] 인증 화면에서 홈 버튼 클릭');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                topPadding: topPadding,
                leftPadding: topPadding,
              ),
              Expanded(
                child: isLandscape
                    ? LandscapeAuthWithBirthdayGenderLayout(
                        phoneInputValue: _phoneInputValue,
                        birthdayInputValue: _birthdayInputValue,
                        selectedGender: _selectedGender,
                        verificationCode: _verificationCode,
                        isAuthRequested: _isAuthRequested,
                        phoneInputHint: AppLocalizations.of(
                          context,
                        )!
                            .authInputHint,
                        currentInputMode: _currentInputMode,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                        onGenderSelected: _onGenderSelected,
                        onInputFieldTapped: _onInputFieldTapped,
                        onRequestAuth: _onRequestAuth,
                      )
                    : PortraitAuthWithBirthdayGenderLayout(
                        phoneInputValue: _phoneInputValue,
                        birthdayInputValue: _birthdayInputValue,
                        selectedGender: _selectedGender,
                        verificationCode: _verificationCode,
                        isAuthRequested: _isAuthRequested,
                        phoneInputHint: AppLocalizations.of(
                          context,
                        )!
                            .authInputHint,
                        currentInputMode: _currentInputMode,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                        onGenderSelected: _onGenderSelected,
                        onInputFieldTapped: _onInputFieldTapped,
                        onRequestAuth: _onRequestAuth,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
