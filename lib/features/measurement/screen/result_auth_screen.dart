import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
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
import 'package:flutter_template/main.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ResultAuthScreen extends ConsumerStatefulWidget {
  final BloodPressureResult result;

  const ResultAuthScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<ResultAuthScreen> createState() => _ResultAuthScreenState();
}

class _ResultAuthScreenState extends ConsumerState<ResultAuthScreen>
    with AutoReturnMixin, RouteAware {
  String _phoneInputValue = '';
  String _birthdayInputValue = '';
  String _selectedGender = 'M';
  String _verificationCode = '';
  String? _generatedCertNumber;
  String? _phoneAtAuthRequest;
  bool _isAuthRequested = false;
  bool _isVerified = false;
  InputMode _currentInputMode = InputMode.birthday;
  final _serviceLocator = ServiceLocator();

  @override
  void initState() {
    super.initState();
    _initializeTimer();
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
    super.didPushNext();
    cancelAutoReturnTimer();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _initializeTimer();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    _resetTimer();
  }

  void _resetTimer() {
    cancelAutoReturnTimer();
    startAutoReturnTimer(300);
  }

  void _onNumberPressed(String number) {
    _resetTimer();

    if (_currentInputMode == InputMode.birthday) {
      if (!BirthdayValidator.canAddDigit(_birthdayInputValue, number)) return;
      setState(() {
        _birthdayInputValue += number;
        if (_birthdayInputValue.length == BirthdayValidator.maxDigits) {
          if (BirthdayValidator.isValid(_birthdayInputValue)) {
            _currentInputMode = InputMode.phone;
          }
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
          _birthdayInputValue =
              _birthdayInputValue.substring(0, _birthdayInputValue.length - 1);
        }
      } else if (_currentInputMode == InputMode.phone) {
        if (_phoneInputValue.isNotEmpty) {
          _phoneInputValue =
              _phoneInputValue.substring(0, _phoneInputValue.length - 1);
        }
      } else if (_currentInputMode == InputMode.verificationCode) {
        if (_verificationCode.isNotEmpty) {
          _verificationCode =
              _verificationCode.substring(0, _verificationCode.length - 1);
        }
      }
    });
  }

  void _onInputFieldTapped(InputMode mode) {
    _resetTimer();
    setState(() {
      _currentInputMode = mode;
    });
  }

  void _onGenderSelected(String gender) {
    _resetTimer();
    setState(() {
      _selectedGender = gender;
      if (BirthdayValidator.isValid(_birthdayInputValue)) {
        _currentInputMode = InputMode.phone;
      }
    });
  }

  Future<void> _onRequestAuth() async {
    final l10n = AppLocalizations.of(context)!;
    if (!BirthdayValidator.isValid(_birthdayInputValue)) {
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterCorrectBirthday,
      );
      return;
    }

    if (_phoneInputValue.length < 10) {
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterCorrectPhoneNumber,
      );
      return;
    }

    try {
      _resetTimer();
      ProgressModal.show(context);

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
          final authResponse =
              await _serviceLocator.authRepository.kioskAuth(kioskId);
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

      final phoneDigits = PhoneValidator.extractDigits(_phoneInputValue);
      final certNumber = CertNumberGenerator.generate();

      await _serviceLocator.authRepository.sendSms(
        token: token,
        type: 'CERT',
        phonenumber: phoneDigits,
        certnumber: certNumber,
      );

      setState(() {
        _phoneAtAuthRequest = phoneDigits;
        _generatedCertNumber = certNumber;
        _isAuthRequested = true;
        _currentInputMode = InputMode.verificationCode;
      });

      ProgressModal.hide();
    } catch (e) {
      ProgressModal.hide();
      if (mounted) {
        ErrorModal.show(context);
      }
    }
  }

  Future<void> _verifyCertNumber() async {
    final l10n = AppLocalizations.of(context)!;
    if (_verificationCode.length != 4) {
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterVerificationCode4Digits,
      );
      return;
    }

    if (_generatedCertNumber == null) {
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.requestVerificationCodeFirst,
      );
      return;
    }

    if (_verificationCode != _generatedCertNumber) {
      InfoModal.show(
        context,
        title: l10n.verificationFailed,
        message: l10n.verificationCodeMismatch,
      );
      return;
    }

    if (_phoneAtAuthRequest == null || _phoneAtAuthRequest!.isEmpty) {
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
    if (!_isVerified) {
      if (_isAuthRequested) {
        await _verifyCertNumber();
        if (!_isVerified) {
          return;
        }
      } else {
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
          final authResponse =
              await _serviceLocator.authRepository.kioskAuth(kioskId);
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

      await _serviceLocator.authRepository.updateResultUser(
        token: token,
        measureid: measureId,
        userid: phoneNumber,
        type: 'PHONE',
        birth: birthday,
        gender: gender,
      );

      final kioskOption = await _serviceLocator.kioskOptionStorage.getOption();
      final status = BloodPressureCalculator.getStatus(
        widget.result.systolic,
        widget.result.diastolic,
        context,
      );
      final resultText = _buildResultText(status);
      final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
      final dateText = dateFormat.format(widget.result.measuredAt);
      final place = kioskOption?.place;

      await _serviceLocator.authRepository.sendSms(
        token: token,
        type: 'RESULT_GUEST',
        phonenumber: phoneNumber,
        result: resultText,
        date: dateText,
        place: place,
      );

      ProgressModal.hide();

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
      ProgressModal.hide();
      if (mounted) {
        ErrorModal.show(context);
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
          ),
          child: Column(
            children: [
              Expanded(
                child: isLandscape
                    ? LandscapeAuthWithBirthdayGenderLayout(
                        phoneInputValue: _phoneInputValue,
                        birthdayInputValue: _birthdayInputValue,
                        selectedGender: _selectedGender,
                        verificationCode: _verificationCode,
                        isAuthRequested: _isAuthRequested,
                        phoneInputHint: l10n.authInputHint,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                        onGenderSelected: _onGenderSelected,
                        onInputFieldTapped: _onInputFieldTapped,
                        onRequestAuth: _onRequestAuth,
                        currentInputMode: _currentInputMode,
                      )
                    : PortraitAuthWithBirthdayGenderLayout(
                        phoneInputValue: _phoneInputValue,
                        birthdayInputValue: _birthdayInputValue,
                        selectedGender: _selectedGender,
                        verificationCode: _verificationCode,
                        isAuthRequested: _isAuthRequested,
                        phoneInputHint: l10n.authInputHint,
                        onConfirm: _onConfirm,
                        onNumberPressed: _onNumberPressed,
                        onClearAll: _onClearAll,
                        onDelete: _onDelete,
                        onGenderSelected: _onGenderSelected,
                        onInputFieldTapped: _onInputFieldTapped,
                        onRequestAuth: _onRequestAuth,
                        currentInputMode: _currentInputMode,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
