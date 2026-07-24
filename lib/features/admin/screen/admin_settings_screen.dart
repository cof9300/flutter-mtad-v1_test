import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/features/admin/screen/admin_password_change_screen.dart';
import 'package:flutter_template/features/admin/screen/text_management_screen.dart';
import 'package:flutter_template/features/admin/screen/usb_device_registration_screen.dart';
import 'package:flutter_template/features/admin/screen/bluetooth_device_registration_screen.dart';
import 'package:flutter_template/features/admin/screen/content_update_screen.dart';
import 'package:flutter_template/features/admin/screen/kiosk_id_setting_screen.dart';
import 'package:flutter_template/features/admin/screen/app_start_delay_screen.dart';
import 'package:flutter_template/features/admin/screen/reboot_schedule_screen.dart';
import 'package:flutter_template/features/admin/screen/shutdown_schedule_screen.dart';
import 'package:flutter_template/features/admin/widget/language_selection_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/config/app_version.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/providers/notifier/app_lock_notifier.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _serviceLocator = ServiceLocator();
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _loadDebugMode();
  }

  Future<void> _loadDebugMode() async {
    final isDebugMode = await _serviceLocator.debugModeService.isDebugMode();
    if (mounted) {
      setState(() {
        _isDebugMode = isDebugMode;
      });
    }
  }

  Future<void> _toggleDebugMode(bool value) async {
    await _serviceLocator.debugModeService.setDebugMode(value);
    setState(() {
      _isDebugMode = value;
    });
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _getResponsiveSize(context, 20);
    final horizontalPadding = _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);
    final cardHeight = _getResponsiveSize(context, 120);
    final cardFontSize = _getResponsiveSize(context, 36);

    return CommonLayout(
      disableClockAdminEntry: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: topPadding, top: topPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              _getResponsiveSize(context, 8)),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/keypad-back.svg',
                            width: iconSize * 1.07,
                            height: iconSize * 1.07,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 60)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    '관리자 환경설정',
                    style: TextStyle(
                      fontFamily: AppTextStyles.titleFontFamily,
                      fontSize: titleFontSize,
                      fontVariations: <FontVariation>[FontVariation('wght', 900)],
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 80)),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.all(_getResponsiveSize(context, 40)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              _getResponsiveSize(context, 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: LanguageSelectionWidget(),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UsbDeviceRegistrationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'USB 기기 등록',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BluetoothDeviceRegistrationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '블루투스 기기 관리',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TextManagementScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '텍스트 관리',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ContentUpdateScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '컨텐츠 업데이트',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KioskIdSettingScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '키오스크 ID 설정',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminPasswordChangeScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '관리자 비밀번호 변경',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AppStartDelayScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '앱 시작 동기화 시간',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RebootScheduleScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '재부팅 관리',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ShutdownScheduleScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(context, 40),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _getResponsiveSize(context, 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '종료 관리',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.bodyFontFamily,
                                    fontSize: cardFontSize,
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 600),
                                    ],
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: _getResponsiveSize(context, 40),
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        Container(
                          width: double.infinity,
                          height: cardHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(context, 40),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              _getResponsiveSize(context, 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '앱 잠금',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: cardFontSize,
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                  color: Color(0xFF111111),
                                ),
                              ),
                              Transform.scale(
                                scale: _getResponsiveSize(context, 1.6) / 1.6,
                                child: Switch(
                                  value: ref.watch(appLockProvider),
                                  onChanged: (value) {
                                    ref
                                        .read(appLockProvider.notifier)
                                        .setLocked(value);
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: Color(0xFF227EFF),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Color(0xFFCCCCCC),
                                  trackOutlineColor:
                                      WidgetStateProperty.all(Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 40)),
                        Container(
                          width: double.infinity,
                          height: cardHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(context, 40),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              _getResponsiveSize(context, 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '디버그 모드',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: cardFontSize,
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                  color: Color(0xFF111111),
                                ),
                              ),
                              Transform.scale(
                                scale: _getResponsiveSize(context, 1.6) / 1.6,
                                child: Switch(
                                  value: _isDebugMode,
                                  onChanged: _toggleDebugMode,
                                  activeColor: Colors.white,
                                  activeTrackColor: Color(0xFF227EFF),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Color(0xFFCCCCCC),
                                  trackOutlineColor:
                                      WidgetStateProperty.all(Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: topPadding,
              right: horizontalPadding,
              child: Text(
                AppVersion.displayVersion,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 28),
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 500),
                  ],
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
