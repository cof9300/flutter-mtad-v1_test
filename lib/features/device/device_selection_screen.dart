import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/device_card.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/data/model/device.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/device_usb_mappings_notifier.dart';
import 'package:flutter_template/providers/notifier/selected_device_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/features/mf/screen/mf_send_screen.dart';
import 'package:flutter_template/features/measurement/screen/measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/alco_measurement_screen.dart';
import 'package:flutter_template/features/measurement/screen/hrv_info_input_screen.dart';
import 'package:flutter_template/features/measurement/screen/debug_screen.dart';
import 'package:flutter_template/features/measurement/screen/blood_pressure_result_screen_new.dart';
import 'package:flutter_template/features/measurement/screen/height_weight_result_screen.dart';
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/widget/guest_auth_required_modal.dart';
import 'package:flutter_template/auth/screen/auth_screen.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/main.dart';

class DeviceSelectionScreen extends ConsumerStatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  ConsumerState<DeviceSelectionScreen> createState() =>
      _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends ConsumerState<DeviceSelectionScreen>
    with RouteAware {
  bool _hasCheckedSingleDevice = false;
  bool _isDemoMode = false;
  bool _isKioskDemo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSingleConnectedDevice();
      _checkDemoMode();
      _checkKioskDemo();
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
  void didPopNext() {
    _checkDemoMode();
    _checkKioskDemo();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _checkDemoMode() async {
    final isDebugMode = await ServiceLocator().debugModeService.isDebugMode();
    if (mounted) {
      setState(() {
        _isDemoMode = isDebugMode;
      });
    }
  }

  Future<void> _checkKioskDemo() async {
    final option = await ServiceLocator().kioskOptionStorage.getOption();
    if (mounted) {
      setState(() {
        _isKioskDemo = option?.demo == 1;
      });
    }
  }

  Future<void> _checkSingleConnectedDevice() async {
    if (_hasCheckedSingleDevice) return;
    _hasCheckedSingleDevice = true;

    final hwDevices = ref.read(deviceListWithConnectionProvider);
    final mfDevice = ref.read(mfDeviceProvider);

    final connectedHwDevices = hwDevices.where((d) => d.isConnected).toList();
    final hasMf = mfDevice != null;

    final totalConnected = connectedHwDevices.length + (hasMf ? 1 : 0);
    final totalConfigured = hwDevices.length + (hasMf ? 1 : 0);

    if (totalConfigured == 1 && totalConnected == 1 && !hasMf) {
      final device = connectedHwDevices.first;
      final type = device.type.toUpperCase();

      final usbMappings = ref.read(deviceUsbMappingsProvider);
      final isUsbMapped =
          usbMappings.any((m) => m.deviceType.toUpperCase() == type);

      // provider 상태가 restart/grace-period로 인해 일시적으로 true일 수 있으므로
      // USB 물리 연결을 직접 재검증한 뒤 자동 이동 여부를 결정한다.
      // AL은 AlcoUsbService.isConnected로, 나머지는 VID/PID 스캔으로 확인한다.
      //
      // 단, 블루투스로만 매핑된 기기(예: Omron 블루투스 혈압계)는 예외다.
      // 이런 기기는 측정을 마친 순간에만 잠깐 GATT가 붙고 그 외에는 연결이
      // 끊겨 있는 게 정상 동작이라, 인증 직후(측정 전) 시점에 실시간 GATT
      // 상태를 요구하면 항상 미연결로 판정되어 자동 이동이 막힌다.
      // 기기 목록 화면의 "연결됨" 표시 자체도 실시간 GATT가 아니라 매핑
      // 등록+활성화 여부를 기준으로 하므로, 자동 이동 판단도 동일한 정책을
      // 따르도록 목록 상태를 그대로 신뢰한다.
      final bool isPhysicallyConnected;
      if (type == 'AL') {
        final alcoUsb = ServiceLocator().alcoUsbService;
        if (alcoUsb.isConnectedReliable) {
          isPhysicallyConnected = true;
        } else if (alcoUsb.isPortOpen) {
          // 포트는 점유 중이나 응답이 끊김 → 미연결 (stale 기기목록 오탐 방지)
          isPhysicallyConnected = false;
        } else if (isUsbMapped) {
          isPhysicallyConnected =
              await ServiceLocator().usbService.isDeviceConnected(device.type);
        } else {
          isPhysicallyConnected = ServiceLocator().alcoBleService.isConnected;
        }
      } else if (isUsbMapped) {
        isPhysicallyConnected =
            await ServiceLocator().usbService.isDeviceConnected(device.type);
      } else {
        isPhysicallyConnected = true;
      }

      if (!mounted || !isPhysicallyConnected) return;

      if (type == 'AL') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AlcoMeasurementScreen(),
          ),
        );
      } else if (type == 'ST') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HrvInfoInputScreen(),
          ),
        );
      } else {
        ref.read(selectedDeviceProvider.notifier).selectDevice(device.type);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MeasurementScreen(deviceType: device.type),
          ),
        );
      }
    }
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  int _computeCols(int count, bool isPortrait) {
    if (count == 1) return 1;
    if (count == 2) return isPortrait ? 1 : 2;
    if (count == 3) return isPortrait ? 1 : 3;
    if (count == 4) return 2;
    return math.sqrt(count.toDouble()).ceil();
  }

  void _handleDeviceSelection(
      BuildContext context, WidgetRef ref, String deviceId) {
    debugPrint('Selected device: $deviceId');

    if (deviceId.toUpperCase() == 'AMP' || deviceId.toUpperCase() == 'BP_AMP') {
      ref.read(selectedDeviceProvider.notifier).selectDevice('BP');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MeasurementScreen(deviceType: 'AMP'),
        ),
      );
      return;
    }

    if (deviceId.toUpperCase() == 'MF') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MfSendScreen()),
      );
      return;
    }

    if (deviceId.toUpperCase() == 'AL') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AlcoMeasurementScreen(),
        ),
      );
      return;
    }

    if (deviceId.toUpperCase() == 'ST') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HrvInfoInputScreen(),
        ),
      );
      return;
    }

    ref.read(selectedDeviceProvider.notifier).selectDevice(deviceId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementScreen(deviceType: deviceId),
      ),
    );
  }

  void _handleHomeButton(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  List<Device> _buildDisplayDevices(List<Device> devices) {
    if (_isKioskDemo) {
      if (devices.isEmpty) {
        return [
          Device(type: 'BP', name: '혈압', isConnected: true),
          Device(type: 'AL', name: '음주', isConnected: true),
        ];
      }
      return devices.map((d) {
        final type = d.type.toUpperCase();
        if (type == 'BP' || type == 'AL') {
          return d.copyWith(isConnected: true);
        }
        return d;
      }).toList();
    }
    return devices;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rawDevices = ref.watch(deviceListWithConnectionProvider);
    final mfDevice = ref.watch(mfDeviceProvider);
    final hwDevices = _buildDisplayDevices(rawDevices);
    final devices = [
      ...hwDevices,
      if (mfDevice != null) mfDevice.copyWith(isConnected: true),
      const Device(type: 'AMP', name: '에이엠피올 BP 868F', isConnected: true),
    ];
    final topPadding = _getResponsiveSize(context, 20);
    final contentTopPadding = _getResponsiveSize(context, 50);
    final gridSpacing = _getResponsiveSize(context, 45);
    final horizontalPadding = _getResponsiveSize(context, 75);

    return CommonLayout(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                HomeButton(
                  onTap: () => _handleHomeButton(context),
                  topPadding: topPadding,
                  leftPadding: topPadding,
                ),
                SizedBox(height: contentTopPadding),
                Expanded(
                  child: devices.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noDevicesAvailable,
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: _getResponsiveSize(context, 32),
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            gridSpacing,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final count = devices.length;
                              final isPortrait =
                                  constraints.maxHeight >= constraints.maxWidth;
                              final cols = _computeCols(count, isPortrait);
                              final rows = (count / cols).ceil();
                              final cellW = (constraints.maxWidth -
                                      gridSpacing * (cols - 1)) /
                                  cols;
                              final cellH = (constraints.maxHeight -
                                      gridSpacing * (rows - 1)) /
                                  rows;
                              final aspectRatio =
                                  (cellW / cellH).clamp(0.1, 10.0);

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                  childAspectRatio: aspectRatio,
                                ),
                                itemCount: count,
                                itemBuilder: (context, index) {
                                  final device = devices[index];
                                  return DeviceCard(
                                    device: device,
                                    onTap: () => _handleDeviceSelection(
                                        context, ref, device.type),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
                if (_isDemoMode) ...[
                  SizedBox(height: _getResponsiveSize(context, 40)),
                  _buildTestButtons(context),
                  SizedBox(height: _getResponsiveSize(context, 40)),
                ],
              ],
            ),
            if (_isDemoMode)
              Positioned(
                top: topPadding,
                right: topPadding,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: _getResponsiveSize(context, 80),
                    height: _getResponsiveSize(context, 80),
                    decoration: BoxDecoration(
                      color: Color(0xFFE7EAF3),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(context, 40),
                      ),
                    ),
                    child: Icon(
                      Icons.bug_report,
                      size: _getResponsiveSize(context, 40),
                      color: Color(0xFF4C4948),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons(BuildContext context) {
    final buttonSpacing = _getResponsiveSize(context, 15);
    final horizontalPadding = _getResponsiveSize(context, 75);
    final fontSize = _getResponsiveSize(context, 24);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '테스트 화면',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: fontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 700),
              ],
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: buttonSpacing),
          Wrap(
            spacing: buttonSpacing,
            runSpacing: buttonSpacing,
            children: [
              _buildTestButton(
                context,
                '인증 화면',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthScreen(),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '인증(생년월일)',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AuthScreenWithBirthdayGender(),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '측정 화면',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeasurementScreen(deviceType: 'BP'),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '측정 결과',
                () {
                  final dummyResult = BloodPressureResult(
                    systolic: 160,
                    diastolic: 100,
                    pulse: 72,
                    measuredAt: DateTime.now(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BloodPressureResultScreenNew(result: dummyResult),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '게스트 전화번호',
                () {
                  final dummyResult = BloodPressureResult(
                    systolic: 130,
                    diastolic: 85,
                    pulse: 75,
                    measuredAt: DateTime.now(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GuestPhoneInputScreen(result: dummyResult),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '게스트 인증 모달',
                () {
                  GuestAuthRequiredModal.show(
                    context,
                    onConfirm: () {},
                    onDecline: () {},
                  );
                },
              ),
              _buildTestButton(
                context,
                '신장체중계 결과',
                () {
                  final dummyResult = HeightWeightResult(
                    height: 172.2,
                    weight: 82.5,
                    bmi: 27.5,
                    measuredAt: DateTime.now(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HeightWeightResultScreen(result: dummyResult),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '자율신경 정보입력 화면',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HrvInfoInputScreen(),
                    ),
                  );
                },
              ),
              _buildTestButton(
                context,
                '음주 측정 화면',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlcoMeasurementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, String label, VoidCallback onTap) {
    final fontSize = _getResponsiveSize(context, 22);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSize(context, 24),
          vertical: _getResponsiveSize(context, 12),
        ),
        decoration: BoxDecoration(
          color: Color(0xFF227EFF),
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: fontSize,
            fontVariations: <FontVariation>[
              FontVariation('wght', 600),
            ],
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
