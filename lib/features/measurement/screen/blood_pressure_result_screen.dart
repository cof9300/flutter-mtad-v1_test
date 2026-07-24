import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/measurement/screen/result_auth_screen.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/blood_pressure_constants.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class BloodPressureResultScreen extends ConsumerStatefulWidget {
  final BloodPressureResult result;

  const BloodPressureResultScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<BloodPressureResultScreen> createState() =>
      _BloodPressureResultScreenState();
}

class _BloodPressureResultScreenState
    extends ConsumerState<BloodPressureResultScreen> with AutoReturnMixin {
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    cancelAutoReturnTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final l10n = AppLocalizations.of(context)!;
      final pageOption = ref.read(resultPageOptionProvider);

      ref
          .read(headerTitleProvider.notifier)
          .setTitle(l10n.bloodPressureResultTitle);

      if (pageOption != null) {
        setState(() {
          _isHidden = pageOption.masking;
        });
      }

      _saveMeasurementResult().catchError((e) {
        debugPrint('Failed to save measurement result: $e');
      });

      if (mounted) {
        final kioskOption =
            await ServiceLocator().kioskOptionStorage.getOption();
        final resulttime = kioskOption?.resulttime ?? 120;
        if (resulttime > 0) {
          startAutoReturnTimer(resulttime);
        }
      }
    });
  }

  Future<void> _saveMeasurementResult() async {
    try {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final measureId = ref.read(measureIdProvider);
      final userAuth = ref.read(userAuthProvider);

      if (kioskOption == null) {
        return;
      }

      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) {
        return;
      }

      final result = BloodPressureCalculator.createResultData(
        systolic: widget.result.systolic,
        diastolic: widget.result.diastolic,
        pulse: widget.result.pulse,
        context: context,
      );

      if (kioskOption.mode == 1) {
        if (kioskOption.usecert == 1) {
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'BP',
                    result: result,
                    serviceforce: 'true',
                  );

          if (setResultResponse.measureid != null &&
              setResultResponse.measureid!.isNotEmpty) {
            ref
                .read(measureIdProvider.notifier)
                .setMeasureId(setResultResponse.measureid!);
          }
          return;
        }
      } else {
        if (userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty) {
          await ServiceLocator().authRepository.setResult(
                token: token,
                measureid: userAuth.measureid!,
                device: 'BP',
                result: result,
                serviceforce: 'false',
              );
          return;
        }

        final stepParts = kioskOption.step.split(';');
        final isStep13452 = stepParts.length >= 5 &&
            stepParts[0].trim() == '1' &&
            stepParts[1].trim() == '3' &&
            stepParts[2].trim() == '4' &&
            stepParts[3].trim() == '5' &&
            stepParts[4].trim() == '2';

        final isGuestModeStep12 = kioskOption.usecert == 1 &&
            measureId != null &&
            measureId.isNotEmpty &&
            stepParts.length >= 2 &&
            stepParts[0].trim() == '1' &&
            stepParts[1].trim() == '2';

        if (isStep13452 && kioskOption.usecert == 1) {
          final setResultResponse =
              await ServiceLocator().authRepository.setResult(
                    token: token,
                    measureid: measureId ?? '',
                    device: 'BP',
                    result: result,
                    serviceforce: 'true',
                  );

          if (setResultResponse.measureid != null &&
              setResultResponse.measureid!.isNotEmpty) {
            ref
                .read(measureIdProvider.notifier)
                .setMeasureId(setResultResponse.measureid!);
          }
          return;
        }

        if (isGuestModeStep12) {
          await ServiceLocator().authRepository.setResult(
                token: token,
                measureid: measureId,
                device: 'BP',
                result: result,
                serviceforce: 'false',
              );

          final verifiedUserData =
              await ServiceLocator().verifiedUserStorage.getAllData();
          final phoneNumber = verifiedUserData['phoneNumber'];
          final birthday = verifiedUserData['birthday'];
          final gender = verifiedUserData['gender'];

          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            await ServiceLocator().authRepository.updateResultUser(
                  token: token,
                  measureid: measureId,
                  userid: phoneNumber,
                  type: 'PHONE',
                  birth: birthday,
                  gender: gender,
                );
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving measurement result: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _handleHomeButton(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleRetry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MeasurementScreen(deviceType: 'BP'),
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final userAuth = ref.read(userAuthProvider);
    final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
    final guestPhone =
        await ServiceLocator().guestPhoneStorage.getPhoneNumber();
    final measureId = ref.read(measureIdProvider);
    final verifiedUserData =
        await ServiceLocator().verifiedUserStorage.getAllData();
    final verifiedPhone = verifiedUserData['phoneNumber'];

    if (kioskOption == null) {
      return;
    }

    final isServiceMode = kioskOption.mode == 1;

    if (isServiceMode) {
      if (kioskOption.usecert == 1) {
        if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
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
            final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
            final dateText = dateFormat.format(widget.result.measuredAt);
            final place = kioskOption.place;

            await ServiceLocator().authRepository.sendSms(
                  token: token,
                  type: 'RESULT_GUEST',
                  phonenumber: verifiedPhone,
                  result: resultText,
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
              builder: (context) => ResultAuthScreen(result: widget.result),
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
                  result: resultText,
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
            builder: (context) => ResultAuthScreen(result: widget.result),
          ),
        );
      }
      return;
    }

    if (userAuth?.measureid == null &&
        !isServiceModeWithPhone &&
        !isGuestModeWithMeasureId) {
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
              result: resultText,
              date: dateText,
              place: place,
            );
      } else {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT',
              measureid: userAuth!.measureid,
              result: resultText,
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
    return '''▶혈압
- 수축기 혈압: ${widget.result.systolic} mmHg
- 이완기 혈압: ${widget.result.diastolic} mmHg
- 맥박: ${widget.result.pulse} bpm
- 측정 결과: $status''';
  }

  void _toggleHideResult() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = BloodPressureCalculator.getStatus(
      widget.result.systolic,
      widget.result.diastolic,
      context,
    );
    final statusColor = BloodPressureConstants.getStatusColor(status);

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.resultScreenGradient,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: _getResponsiveSize(context, 15)),
                  SizedBox(
                    height: _getResponsiveSize(context, 550),
                    child: Padding(
                      padding:
                          EdgeInsets.only(top: _getResponsiveSize(context, 30)),
                      child: _isHidden
                          ? _buildHiddenContent(context)
                          : Column(
                              children: [
                                _buildVitalsInfo(context),
                                SizedBox(
                                    height: _getResponsiveSize(context, 15)),
                                _buildStatusSection(
                                    context, status, statusColor),
                                SizedBox(
                                    height: _getResponsiveSize(context, 15)),
                                _buildChartSection(context),
                              ],
                            ),
                    ),
                  ),
                  if (!DeviceConfig().isG10)
                    SizedBox(height: _getResponsiveSize(context, 20)),
                  _buildVideoSection(context),
                  Spacer(),
                  _buildBottomButtons(context),
                  SizedBox(height: _getResponsiveSize(context, 30)),
                ],
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
            ],
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
              color: Color(0xFFE7EAF3),
              borderRadius:
                  BorderRadius.circular(_getResponsiveSize(context, 40)),
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
              color: Color(0xFF4C4948),
              letterSpacing: -0.7,
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/hide_view.svg',
          width: _getResponsiveSize(context, 280),
          height: _getResponsiveSize(context, 280),
        ),
        SizedBox(height: _getResponsiveSize(context, 30)),
        Text(
          l10n.resultHiddenGuide,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 64),
            fontVariations: <FontVariation>[
              FontVariation('wght', 700),
            ],
            color: Color(0xFF227EFF),
            letterSpacing: -1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(
      BuildContext context, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _getResponsiveSize(context, 24),
          height: _getResponsiveSize(context, 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
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
      BuildContext context, String value, String label1, String label2) {
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 80),
      ),
      child: BloodPressureChart(
        systolic: widget.result.systolic,
        diastolic: widget.result.diastolic,
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    final pageOption = ref.watch(resultPageOptionProvider);

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
        mediaItems: pageOption.cm,
        baseUrl: Config.baseUrl,
        playerId: 'bp_result_video',
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            context,
            icon: 'assets/icons/refresh.svg',
            label: l10n.remeasure,
            onTap: _handleRetry,
          ),
          _buildActionButton(
            context,
            icon: 'assets/icons/message.svg',
            label: l10n.sendMessage,
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
        width: _getResponsiveSize(context, 498),
        height: _getResponsiveSize(context, 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 32)),
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
              width: _getResponsiveSize(context, 110),
              height: _getResponsiveSize(context, 110),
            ),
            SizedBox(height: _getResponsiveSize(context, 40)),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 36),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
