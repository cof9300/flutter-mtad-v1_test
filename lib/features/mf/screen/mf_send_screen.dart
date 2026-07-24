import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/features/measurement/widget/measurement_media_player.dart';
import 'package:flutter_template/features/measurement/widget/send_result_success_modal.dart';
import 'package:flutter_template/features/mf/widget/mf_send_content.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/last_bp_result_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:intl/intl.dart';

class MfSendScreen extends ConsumerStatefulWidget {
  const MfSendScreen({super.key});

  @override
  ConsumerState<MfSendScreen> createState() => _MfSendScreenState();
}

class _MfSendScreenState extends ConsumerState<MfSendScreen>
    with AutoReturnMixin, RouteAware {
  bool _isVideoActive = true;
  final int _videoKey = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      final screentime = kioskOption?.screentime ?? 120;
      if (mounted && screentime > 0) {
        startAutoReturnTimer(screentime);
      }
      _sendMediform();
    });
  }

  Future<void> _sendMediform() async {
    final measureId = ref.read(measureIdProvider);
    if (measureId == null || measureId.isEmpty) return;

    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) return;

      await ServiceLocator().authRepository.sendMediform(
            token: token,
            measureid: measureId,
          );
    } catch (e) {
      FlutterErrorLogger.logError('[메디폼] 알림톡 전송 실패', e);
    }
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
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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

  void _handleRetry() {
    final devices = ref.read(deviceListWithConnectionProvider);
    final connectedDevices = devices.where((d) => d.isConnected).toList();
    final hasMf = ref.read(mfDeviceProvider) != null;
    final totalConnected = connectedDevices.length + (hasMf ? 1 : 0);

    if (totalConnected >= 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const MeasurementScreen(deviceType: 'BP')),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final lastResult = ref.read(lastBpResultProvider);
    if (lastResult == null) return;

    try {
      final token = await ServiceLocator().tokenStorage.getToken();
      if (token == null) return;

      final kioskOption = await ServiceLocator().kioskOptionStorage.getOption();
      if (kioskOption == null) return;

      final measureId = ref.read(measureIdProvider);
      final userAuth = ref.read(userAuthProvider);
      final verifiedUserData =
          await ServiceLocator().verifiedUserStorage.getAllData();
      final verifiedPhone = verifiedUserData['phoneNumber'];
      final guestPhone =
          await ServiceLocator().guestPhoneStorage.getPhoneNumber();

      final status = BloodPressureCalculator.getStatus(
        lastResult.systolic,
        lastResult.diastolic,
        context,
      );
      final resultText = _buildResultText(lastResult, status);
      final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
      final dateText = dateFormat.format(lastResult.measuredAt);
      final place = kioskOption.place;

      String? phoneNumber;
      if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
        phoneNumber = verifiedPhone;
      } else if (userAuth?.phonenumber != null &&
          userAuth!.phonenumber!.isNotEmpty) {
        phoneNumber = userAuth.phonenumber;
      } else if (guestPhone != null && guestPhone.isNotEmpty) {
        phoneNumber = guestPhone;
      }

      if (phoneNumber != null) {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT_GUEST',
              phonenumber: phoneNumber,
              measureid: measureId,
              result: resultText,
              date: dateText,
              place: place,
            );
      } else if (measureId != null && measureId.isNotEmpty) {
        await ServiceLocator().authRepository.sendSms(
              token: token,
              type: 'RESULT',
              measureid: measureId,
              result: resultText,
            );
      } else {
        return;
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
      FlutterErrorLogger.logError('[메디폼] 문자 전송 실패', e);
    }
  }

  String _buildResultText(dynamic result, String status) {
    return '''▶혈압
- 수축기: ${result.systolic} mmHg
- 이완기: ${result.diastolic} mmHg
- 맥박: ${result.pulse} bpm
- 측정결과: $status''';
  }

  @override
  Widget build(BuildContext context) {
    final lastResult = ref.watch(lastBpResultProvider);
    final hasResult = lastResult != null;

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: _getResponsiveSize(context, 50)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            const MfSendContent(),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            _buildVideoSection(context),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _getResponsiveSize(context, 40),
                          ),
                          child: _buildBottomButtons(context, hasResult),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                child: HomeButton(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  topPadding: _getResponsiveSize(context, 20),
                  leftPadding: _getResponsiveSize(context, 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, bool hasResult) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            context,
            icon: 'assets/icons/refresh.svg',
            label: '재측정',
            onTap: _handleRetry,
          ),
          if (hasResult) ...[
            SizedBox(width: _getResponsiveSize(context, 28)),
            _buildActionButton(
              context,
              icon: 'assets/icons/message.svg',
              label: '문자전송',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _getResponsiveSize(context, 498),
        height: _getResponsiveSize(context, 255),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 32)),
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
              width: _getResponsiveSize(context, 80),
              height: _getResponsiveSize(context, 80),
            ),
            SizedBox(height: _getResponsiveSize(context, 24)),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 32),
                fontVariations: const [FontVariation('wght', 700)],
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    final pageOption = ref.read(resultPageOptionProvider);
    final w = _getResponsiveSize(context, 1024);
    final h = _getResponsiveSize(context, 576);

    if (pageOption == null || pageOption.cm.isEmpty) {
      return Container(width: w, height: h, color: Colors.black);
    }

    return Container(
      width: w,
      height: h,
      color: Colors.black,
      child: MeasurementMediaPlayer(
        key: ValueKey('mf_video_$_videoKey'),
        mediaItems: pageOption.cm,
        baseUrl: Config.baseUrl,
        playerId: 'mf_video',
        isActive: _isVideoActive,
      ),
    );
  }
}
