import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/core/widget/agreement_image_modal.dart';
import 'package:flutter_template/core/widget/info_modal.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/core/widget/error_modal.dart';
import 'package:flutter_template/auth/widget/number_keypad.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/features/measurement/model/alco_measurement_result.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/model/hrv_measurement_result.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/height_weight_calculator.dart';
import 'package:flutter_template/core/utils/hrv_result_calculator.dart';
import 'package:flutter_template/core/utils/phone_formatter.dart';
import 'package:flutter_template/core/utils/phone_validator.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';
import 'package:flutter_template/providers/notifier/agreement_option_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/providers/notifier/rich_text_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/core/widget/rich_text_renderer.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/providers/notifier/session_results_notifier.dart';

class GuestPhoneInputScreen extends ConsumerStatefulWidget {
  final BloodPressureResult? result;
  final AlcoMeasurementResult? alcoResult;
  final HeightWeightResult? hwResult;
  final HrvMeasurementResult? hrvResult;

  const GuestPhoneInputScreen({
    super.key,
    this.result,
    this.alcoResult,
    this.hwResult,
    this.hrvResult,
  });

  @override
  ConsumerState<GuestPhoneInputScreen> createState() =>
      _GuestPhoneInputScreenState();
}

class _GuestPhoneInputScreenState extends ConsumerState<GuestPhoneInputScreen>
    with AutoReturnMixin, RouteAware {
  late String _phoneNumber;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final savedPhone = ServiceLocator().guestPhoneStorage.getPhoneNumberSync();
    print('[전화번호 입력 화면] 저장된 전화번호 로드: $savedPhone');
    _phoneNumber =
        savedPhone != null && savedPhone.isNotEmpty ? savedPhone : '010';
    print('[전화번호 입력 화면] 초기값 설정: $_phoneNumber');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final certtime = kioskOption?.certtime ?? 0;
      if (mounted && certtime > 0) {
        startAutoReturnTimer(certtime);
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

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _handleNumberPressed(String number) {
    resetCurrentTimer();
    if (PhoneValidator.canAddDigit(_phoneNumber)) {
      setState(() {
        _phoneNumber += number;
      });
    }
  }

  void _handleClearAll() {
    resetCurrentTimer();
    setState(() {
      _phoneNumber = '';
    });
  }

  void _handleDelete() {
    resetCurrentTimer();
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _handleHomeButton(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits = PhoneValidator.extractDigits(_phoneNumber);
    if (phoneDigits.length != 11) {
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterCorrectPhoneNumber,
      );
      return;
    }

    final fullPhoneNumber = phoneDigits;
    await ServiceLocator().guestPhoneStorage.savePhoneNumber(fullPhoneNumber);

    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();

    if (kioskOption != null &&
        kioskOption.mode == 1 &&
        kioskOption.usecert == 2) {
      final stepParts = kioskOption.step.split(';');
      final isStep12345 = stepParts.length >= 5 &&
          stepParts[0].trim() == '1' &&
          stepParts[1].trim() == '2' &&
          stepParts[2].trim() == '3' &&
          stepParts[3].trim() == '4' &&
          stepParts[4].trim() == '5';

      if (isStep12345) {
        if (widget.result == null && widget.alcoResult == null && widget.hwResult == null && widget.hrvResult == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeviceSelectionScreen(),
            ),
          );
          return;
        }

        try {
          ProgressModal.show(context);

          final token = await ServiceLocator().tokenStorage.getToken();

          if (token == null) {
            ProgressModal.hide();
            if (mounted) {
              ErrorModal.show(context);
            }
            return;
          }

          final measureId = ref.read(measureIdProvider);
          FlutterErrorLogger.logInfo('[측정결과] 게스트 결과 저장 MeasureId: $measureId');

          if (measureId != null && measureId.isNotEmpty) {
            try {
              await ServiceLocator().authRepository.updateResultUser(
                token: token,
                measureid: measureId,
                userid: fullPhoneNumber,
                type: 'PHONE',
                birth: null,
                gender: null,
              );
              FlutterErrorLogger.logInfo('[측정결과] updateResultUser 완료 MeasureId: $measureId, Phone: $fullPhoneNumber');
            } catch (e) {
              FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
            }
          }

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
            resultText = _buildHrvResultText();
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

          final place = kioskOption.place;

          await ServiceLocator().authRepository.sendSms(
                token: token,
                type: 'RESULT_GUEST',
                phonenumber: fullPhoneNumber,
                result: _combinedResultText(resultText),
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
          return;
        } catch (e) {
          ProgressModal.hide();
          if (mounted) {
            ErrorModal.show(context);
          }
          return;
        }
      }
    }

    if (kioskOption != null && kioskOption.mode == 1) {
      final stepParts = kioskOption.step.split(';');
      if (stepParts.length >= 2 &&
          stepParts[0].trim() == '1' &&
          stepParts[1].trim() == '2') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSelectionScreen(),
          ),
        );
        return;
      }
    }

    if (kioskOption != null && kioskOption.mode == 2) {
      if (widget.result == null && widget.alcoResult == null && widget.hwResult == null && widget.hrvResult == null) {
        InfoModal.show(
          context,
          title: l10n.error,
          message: l10n.measurementResultNotFound,
        );
        return;
      }

      try {
        ProgressModal.show(context);

        final token = await ServiceLocator().tokenStorage.getToken();
        if (token == null) {
          ProgressModal.hide();
          if (mounted) ErrorModal.show(context);
          return;
        }

        final measureId = ref.read(measureIdProvider);
        if (measureId != null && measureId.isNotEmpty) {
          try {
            await ServiceLocator().authRepository.updateResultUser(
              token: token,
              measureid: measureId,
              userid: fullPhoneNumber,
              type: 'PHONE',
              birth: null,
              gender: null,
            );
            FlutterErrorLogger.logInfo('[측정결과] updateResultUser 완료 MeasureId: $measureId, Phone: $fullPhoneNumber');
          } catch (e) {
            FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
          }
        }

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
          resultText = _buildHrvResultText();
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

        final place = kioskOption.place;

        await ServiceLocator().authRepository.sendSms(
          token: token,
          type: 'RESULT_GUEST',
          phonenumber: fullPhoneNumber,
          result: _combinedResultText(resultText),
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
        return;
      } catch (e) {
        ProgressModal.hide();
        if (mounted) ErrorModal.show(context);
        return;
      }
    }

    if (widget.result == null && widget.alcoResult == null && widget.hwResult == null && widget.hrvResult == null) {
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.measurementResultNotFound,
      );
      return;
    }

    try {
      ProgressModal.show(context);

      final token = await ServiceLocator().tokenStorage.getToken();

      if (token == null) {
        ProgressModal.hide();
        if (mounted) {
          ErrorModal.show(context);
        }
        return;
      }

      final measureId = ref.read(measureIdProvider);
      if (measureId != null && measureId.isNotEmpty) {
        try {
          await ServiceLocator().authRepository.updateResultUser(
            token: token,
            measureid: measureId,
            userid: fullPhoneNumber,
            type: 'PHONE',
            birth: null,
            gender: null,
          );
        } catch (e) {
          FlutterErrorLogger.logError('[측정결과] updateResultUser 실패', e);
        }
      }

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
        resultText = _buildHrvResultText();
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

      final place = kioskOption?.place ?? l10n.defaultKioskPlace;

      await ServiceLocator().authRepository.sendSms(
            token: token,
            type: 'RESULT_GUEST',
            phonenumber: fullPhoneNumber,
            result: _combinedResultText(resultText),
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

  String _buildHrvResultText() {
    final hrv = widget.hrvResult;
    if (hrv == null) return '';
    final basic = hrv.basic;
    return '''▶자율신경계
- 종합점수: ${basic.totalScore.toStringAsFixed(1)}점
- 자율신경 활성도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.tpScore))}
- 스트레스 대처능력: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.sdnnScore))}
- 피로도: ${HrvResultCalculator.step5Label(HrvResultCalculator.step5(basic.lfScore))}''';
  }

  String _combinedResultText(String fallback) {
    return ref.read(sessionResultsProvider.notifier).combinedText(fallback);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget content;

    if (isMobile) {
      content = Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: _getResponsiveSize(context, 100)),
                _buildTitle(context, l10n),
                SizedBox(height: _getResponsiveSize(context, 20)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildPhoneInputSection(context),
                ),
                SizedBox(height: _getResponsiveSize(context, 40)),
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: NumberKeypad(
                    onNumberPressed: _handleNumberPressed,
                    onClearAll: _handleClearAll,
                    onDelete: _handleDelete,
                  ),
                ),
                const SizedBox(height: 24.0),
                _buildSendButton(context, l10n),
                const SizedBox(height: 16.0),
                _buildTermsSection(context, l10n),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
          Positioned(
            top: _getResponsiveSize(context, 20),
            left: _getResponsiveSize(context, 20),
            child: HomeButton(
              onTap: () => _handleHomeButton(context),
              topPadding: 0,
              leftPadding: 0,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: _getResponsiveSize(context, 100)),
                      _buildTitle(context, l10n),
                      SizedBox(height: _getResponsiveSize(context, 20)),
                      _buildPhoneInputSection(context),
                      SizedBox(height: _getResponsiveSize(context, 40)),
                      GestureDetector(
                        onTap: () {},
                        behavior: HitTestBehavior.opaque,
                        child: NumberKeypad(
                          onNumberPressed: _handleNumberPressed,
                          onClearAll: _handleClearAll,
                          onDelete: _handleDelete,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: _getResponsiveSize(context, 20),
                  left: _getResponsiveSize(context, 20),
                  child: HomeButton(
                    onTap: () => _handleHomeButton(context),
                    topPadding: 0,
                    leftPadding: 0,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: _buildSendButton(context, l10n),
          ),
          SizedBox(height: _getResponsiveSize(context, 40)),
          _buildTermsSection(context, l10n),
        ],
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => resetCurrentTimer(),
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, AppLocalizations l10n) {
    final locale = ref.watch(localeProvider);
    final richTextNotifier = ref.watch(richTextNotifierProvider.notifier);
    final guestPhoneTitleText = richTextNotifier.getText(
      'guest_phone_title',
      locale.languageCode,
      l10n.guestPhoneInputTitle,
    );

    return Container(
      height: _getResponsiveSize(context, 90),
      alignment: Alignment.center,
      child: RichTextRenderer(
        text: guestPhoneTitleText,
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontSize: _getResponsiveSize(context, 36),
          fontVariations: <FontVariation>[
            FontVariation('wght', 400),
          ],
          color: Color(0xFF595757),
          letterSpacing: -0.9,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPhoneInputSection(BuildContext context) {
    return Container(
      width: _getResponsiveSize(context, 860),
      child: _buildInputDisplay(context),
    );
  }

  Widget _buildInputDisplay(BuildContext context) {
    final displayText = _phoneNumber.isEmpty
        ? '010-1234-5678'
        : PhoneFormatter.format(_phoneNumber);

    return Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            offset: Offset(0, 4),
            blurRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: AppTextStyles.titleFontFamily,
          fontSize: _getResponsiveSize(context, 56),
          color: _phoneNumber.isEmpty ? Color(0xFF999999) : Color(0xFF111111),
          height: 56 / 56,
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: _handleSend,
      child: Container(
        width: isMobile ? (screenWidth - 80.0) : _getResponsiveSize(context, 780),
        height: _getResponsiveSize(context, 120),
        decoration: BoxDecoration(
          color: Color(0xFF227EFF),
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.agreeAllAndSend,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 48),
            fontVariations: <FontVariation>[
              FontVariation('wght', 700),
            ],
            color: Colors.white,
            height: 56 / 48,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 150),
        vertical: _getResponsiveSize(context, 35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.termsAgreement,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 26),
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: Color(0xFF595757),
              height: 1.2,
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 7)),
          _buildTermsItem(context, l10n.privacyPolicy, l10n.viewDetails, 2),
          SizedBox(height: _getResponsiveSize(context, 7)),
          _buildTermsItem(context, l10n.termsOfService, l10n.viewDetails, 1),
          SizedBox(height: _getResponsiveSize(context, 7)),
          _buildTermsItem(context, l10n.thirdPartyInfo, l10n.viewDetails, 3),
          SizedBox(height: _getResponsiveSize(context, 7)),
          _buildTermsItem(context, l10n.sensitiveInfo, l10n.viewDetails, 4),
        ],
      ),
    );
  }

  bool _isLocalFile(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  Future<void> _handleViewAgreement(int type) async {
    var agreementOption = ref.read(agreementOptionProvider);
    String imagePath = _agreementPathFor(agreementOption, type);

    if (imagePath.isEmpty) {
      final refreshed = await _ensureAgreementOptionFresh();
      if (refreshed != null) {
        agreementOption = refreshed;
        imagePath = _agreementPathFor(agreementOption, type);
      }
    }

    if (imagePath.isEmpty) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      InfoModal.show(
        context,
        title: l10n.error,
        message: l10n.agreementContentUnavailable,
      );
      return;
    }

    final imageUrl =
        _isLocalFile(imagePath) ? imagePath : '${Config.baseUrl}$imagePath';
    AgreementImageModal.show(context, imageUrl: imageUrl);
  }

  String _agreementPathFor(AgreementOptionResponse? option, int type) {
    if (option == null) return '';
    switch (type) {
      case 1:
        return option.agreeimage1;
      case 2:
        return option.agreeimage2;
      case 3:
        return option.agreeimage3;
      case 4:
        return option.agreeimage4;
      default:
        return '';
    }
  }

  Future<AgreementOptionResponse?> _ensureAgreementOptionFresh() async {
    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null || token.isEmpty) return null;
      final fresh =
          await ServiceLocator().authRepository.getAgreementOption(token);
      await ServiceLocator()
          .contentStorageService
          .saveAgreementOption(fresh);
      final reloaded = ServiceLocator()
          .contentStorageService
          .getStoredAgreementOption();
      if (reloaded != null && mounted) {
        ref
            .read(agreementOptionProvider.notifier)
            .setAgreementOption(reloaded);
      }
      return reloaded;
    } catch (e) {
      FlutterErrorLogger.logError('[GuestPhone] Agreement refresh failed', e);
      return null;
    }
  }

  Widget _buildTermsItem(
      BuildContext context, String title, String linkText, int type) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 26),
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Color(0xFF595757),
              height: 1.2,
            ),
          ),
        ),
        Container(
          width: _getResponsiveSize(context, 300),
          height: 1,
          color: Color(0xFFD9D9D9),
        ),
        SizedBox(width: _getResponsiveSize(context, 30)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleViewAgreement(type),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: _getResponsiveSize(context, 12),
              horizontal: _getResponsiveSize(context, 8),
            ),
            child: Text(
              linkText,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 26),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 500),
                ],
                color: Color(0xFF227EFF),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF227EFF),
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
