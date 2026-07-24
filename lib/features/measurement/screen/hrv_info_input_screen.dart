import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/home_button.dart';
import 'package:flutter_template/core/widget/info_modal.dart';
import 'package:flutter_template/auth/widget/auth_input_field.dart';
import 'package:flutter_template/auth/widget/auth_birthday_gender_keypad.dart';
import 'package:flutter_template/core/utils/birthday_validator.dart';
import 'package:flutter_template/core/utils/auto_return_mixin.dart';
import 'package:flutter_template/features/measurement/screen/hrv_measurement_screen.dart';
import 'package:flutter_template/features/measurement/widget/hrv_gender_card.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/hrv_user_info_notifier.dart';
import 'package:flutter_template/providers/notifier/selected_device_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

/// 자율신경계(HRV) 측정 전 성별/생년월일 입력 화면.
/// Figma: 사용자정보 - 자율신경계 (node-id 851:20)
class HrvInfoInputScreen extends ConsumerStatefulWidget {
  const HrvInfoInputScreen({super.key});

  @override
  ConsumerState<HrvInfoInputScreen> createState() => _HrvInfoInputScreenState();
}

class _HrvInfoInputScreenState extends ConsumerState<HrvInfoInputScreen>
    with AutoReturnMixin, RouteAware {
  String _selectedGender = 'M';
  String _birthdayInputValue = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    FlutterErrorLogger.logInfo('[자율신경측정] 정보입력 화면 진입');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(headerTitleProvider.notifier).setTitle('자율신경측정 안내');
      final option = await ServiceLocator().kioskOptionStorage.getOption();
      if (mounted && option != null && option.certtime > 0) {
        startAutoReturnTimer(option.certtime);
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
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _onGenderSelected(String gender) {
    resetCurrentTimer();
    setState(() => _selectedGender = gender);
  }

  void _onNumberPressed(String number) {
    resetCurrentTimer();
    if (!BirthdayValidator.canAddDigit(_birthdayInputValue, number)) return;
    final newValue = _birthdayInputValue + number;
    final digits = BirthdayValidator.extractDigits(newValue);
    if (digits.length == 8 && !BirthdayValidator.isValid(newValue)) return;
    setState(() => _birthdayInputValue = newValue);
  }

  void _onClearAll() {
    resetCurrentTimer();
    setState(() => _birthdayInputValue = '');
  }

  void _onDelete() {
    resetCurrentTimer();
    if (_birthdayInputValue.isEmpty) return;
    setState(() {
      _birthdayInputValue =
          _birthdayInputValue.substring(0, _birthdayInputValue.length - 1);
    });
  }

  void _handleHomeButton() {
    FlutterErrorLogger.logInfo('[화면이동] 자율신경측정 정보입력 화면에서 홈 버튼 클릭');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleConfirm() {
    resetCurrentTimer();
    final l10n = AppLocalizations.of(context)!;
    final birthdayDigits = BirthdayValidator.extractDigits(_birthdayInputValue);

    if (birthdayDigits.length != 8 || !BirthdayValidator.isValid(_birthdayInputValue)) {
      InfoModal.show(
        context,
        title: l10n.invalidPhoneFormatTitle,
        message: l10n.enterCorrectBirthday,
      );
      return;
    }

    FlutterErrorLogger.logInfo(
      '[자율신경측정] 정보입력 완료 - Gender: $_selectedGender, Birthday: $birthdayDigits',
    );

    ref.read(hrvUserInfoProvider.notifier).setUserInfo(
          gender: _selectedGender,
          birthday: birthdayDigits,
        );
    ref.read(selectedDeviceProvider.notifier).selectDevice('ST');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HrvMeasurementScreen(),
      ),
    );
  }

  // 디자인 기준 캔버스 너비(Figma 1080 기준). 실제 화면 크기와 무관하게 이 캔버스로
  // 레이아웃을 구성한 뒤, FittedBox로 화면에 딱 맞게(스크롤 없이) 축소/확대한다.
  static const double _designWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = _getResponsiveSize(context, 20);

    return GestureDetector(
      onTapDown: (_) => resetCurrentTimer(),
      onPanDown: (_) => resetCurrentTimer(),
      behavior: HitTestBehavior.translucent,
      child: CommonLayout(
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(_designWidth, 1920),
                      ),
                      child: Builder(
                        builder: (context) => _buildContent(context, l10n),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topPadding,
                left: topPadding,
                child: HomeButton(
                  onTap: _handleHomeButton,
                  topPadding: 0,
                  leftPadding: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final horizontalPadding = _getResponsiveSize(context, 120);
    return SizedBox(
      width: _designWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: _getResponsiveSize(context, 76)),
          _buildTitle(context),
          SizedBox(height: _getResponsiveSize(context, 62)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HrvGenderCard(
                    label: l10n.female,
                    iconAsset: 'assets/icons/female.svg',
                    isSelected: _selectedGender == 'F',
                    onTap: () => _onGenderSelected('F'),
                    height: _getResponsiveSize(context, 350),
                  ),
                ),
                SizedBox(width: _getResponsiveSize(context, 40)),
                Expanded(
                  child: HrvGenderCard(
                    label: l10n.male,
                    iconAsset: 'assets/icons/male.svg',
                    isSelected: _selectedGender == 'M',
                    onTap: () => _onGenderSelected('M'),
                    height: _getResponsiveSize(context, 350),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 58)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.birthday,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 38),
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: const Color(0xFF111111),
                ),
              ),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 11)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: AuthInputField(
              hint: '1998.12.06',
              value: BirthdayValidator.format(_birthdayInputValue),
              onTap: () {},
              fontSize: _getResponsiveSize(context, 46),
              height: _getResponsiveSize(context, 125),
              shadowStyle: ShadowStyle.bottomRight,
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 76)),
          AuthBirthdayGenderKeypad(
            onNumberPressed: _onNumberPressed,
            onClearAll: _onClearAll,
            onDelete: _onDelete,
          ),
          SizedBox(height: _getResponsiveSize(context, 65)),
          Center(child: _buildConfirmButton(context, l10n)),
          SizedBox(height: _getResponsiveSize(context, 50)),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final fontSize = _getResponsiveSize(context, 56);
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '성별',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: const Color(0xFF111111),
              ),
            ),
            TextSpan(
              text: '과 ',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 400),
                ],
                color: const Color(0xFF4B4948),
              ),
            ),
            TextSpan(
              text: '나이',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: const Color(0xFF111111),
              ),
            ),
            TextSpan(
              text: '를 입력해주세요.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: fontSize,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 400),
                ],
                color: const Color(0xFF4B4948),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _handleConfirm,
      child: Container(
        width: _getResponsiveSize(context, 780),
        height: _getResponsiveSize(context, 150),
        decoration: BoxDecoration(
          color: const Color(0xFF227EFF),
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.confirm,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 55),
            fontVariations: const <FontVariation>[
              FontVariation('wght', 700),
            ],
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
