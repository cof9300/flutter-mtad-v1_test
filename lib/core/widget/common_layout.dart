import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/admin_password_dialog.dart';
import 'package:flutter_template/features/admin/screen/admin_settings_screen.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/header_logo_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonLayout extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onLogoTap;
  final bool disableClockAdminEntry;

  const CommonLayout({
    super.key,
    required this.child,
    this.onLogoTap,
    this.disableClockAdminEntry = false,
  });

  @override
  ConsumerState<CommonLayout> createState() => _CommonLayoutState();
}

class _CommonLayoutState extends ConsumerState<CommonLayout> {
  int _clickCount = 0;
  DateTime? _lastClickTime;
  int _logoClickCount = 0;
  DateTime? _lastLogoClickTime;

  // 태블릿 헤더 관련 치수를 최초 레이아웃 시 1회만 계산해 고정한다.
  // MediaQuery(키보드·SafeArea·화면 전환 등)가 변해도 헤더가 흔들리지 않는다.
  double? _tabletHeaderHeight;
  double? _tabletLogoWidth;
  double? _tabletClockWidth;
  double? _tabletHPadding;
  double? _tabletFontSize;

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;

    if (isLandscape) {
      return (screenWidth / baseWidth * baseSize * 0.6)
          .clamp(baseSize * 0.3, baseSize * 0.9);
    }
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  bool _isSmallScreen(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    return !isLandscape && screenSize.shortestSide < 480;
  }

  /// 태블릿 치수를 최초 1회 계산·캐싱한다.
  /// 이후 MediaQuery가 변해도(키보드·화면전환 등) 동일한 값을 반환한다.
  void _ensureTabletDimensionsCached(BuildContext context) {
    if (_tabletHeaderHeight != null) return;
    final shortSide = MediaQuery.of(context).size.shortestSide;
    const baseRef = 1080.0;
    double stable(double base, double min, double max) =>
        (shortSide / baseRef * base).clamp(min, max);

    _tabletHeaderHeight = stable(150.0, 95.0, 115.0);
    _tabletLogoWidth    = stable(180.0, 90.0, 200.0);
    _tabletClockWidth   = stable(200.0, 100.0, 220.0);
    _tabletHPadding     = stable(40.0,  20.0,  50.0);
    _tabletFontSize     = stable(52.0,  30.0,  45.0);
  }

  double _getHeaderHeight(BuildContext context) {
    final isLargeKiosk = DeviceConfig().isLargeKiosk(context);
    final isTablet = DeviceConfig().isTabletSized(context);
    final isSmall = _isSmallScreen(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    // 키오스크 > 태블릿 > 기본 > 소형 순으로 헤더 높이가 줄어든다.
    if (isLargeKiosk) return _getResponsiveSize(context, 173.0);
    if (isTablet) {
      _ensureTabletDimensionsCached(context);
      return _tabletHeaderHeight!;
    }
    if (isMobile || isSmall) return _getResponsiveSize(context, 160.0);
    return _getResponsiveSize(context, 120.0);
  }

  void _handleClockTap() {
    if (widget.disableClockAdminEntry) return;

    final now = DateTime.now();
    
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inSeconds > 2) {
      _clickCount = 0;
    }
    
    _lastClickTime = now;
    _clickCount++;
    
    if (_clickCount >= 4) {
      _clickCount = 0;
      _lastClickTime = null;
      
      AdminPasswordDialog.show(
        context,
        onSuccess: (password) async {
          final prefs = await SharedPreferences.getInstance();
          const defaultPassword = '0000';
          final storedPassword = prefs.getString('admin_password') ?? defaultPassword;
          
          if (password == storedPassword) {
            AdminPasswordDialog.hide();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminSettingsScreen(),
              ),
            );
          } else {
            AdminPasswordDialog.showError();
          }
        },
      );
    }
  }

  void _handleLogoTap() {
    if (widget.onLogoTap == null) return;
    
    final now = DateTime.now();
    
    if (_lastLogoClickTime != null &&
        now.difference(_lastLogoClickTime!).inSeconds > 2) {
      _logoClickCount = 0;
    }
    
    _lastLogoClickTime = now;
    _logoClickCount++;
    
    if (_logoClickCount >= 4) {
      _logoClickCount = 0;
      _lastLogoClickTime = null;
      widget.onLogoTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = DeviceConfig().isTabletSized(context);
    if (isTablet) _ensureTabletDimensionsCached(context);
    final headerHeight = _getHeaderHeight(context);
    final horizontalPadding = isTablet
        ? _tabletHPadding!
        : _getResponsiveSize(context, 40);
    final logoWidth = isTablet
        ? _tabletLogoWidth!
        : _getResponsiveSize(context, 180);
    final clockWidth = isTablet
        ? _tabletClockWidth!
        : _getResponsiveSize(context, 200);

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: headerHeight + topPadding,
      color: const Color(0xFF227EFF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _buildLogo(context),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: logoWidth,
                    right: clockWidth,
                  ),
                  child: _buildTitle(context),
                ),
              ),
              Positioned(
                right: 0,
                child: _buildClock(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final isTablet = DeviceConfig().isTabletSized(context);
    if (isTablet) _ensureTabletDimensionsCached(context);
    final headerHeight = _getHeaderHeight(context);
    final containerWidth = isTablet
        ? _tabletLogoWidth!
        : _getResponsiveSize(context, 180);
    final customLogo = ref.watch(headerLogoProvider);
    final logoUrl = customLogo != null && customLogo.isNotEmpty
        ? '${Config.baseUrl}/$customLogo'
        : null;

    return GestureDetector(
      onTap: _handleLogoTap,
      child: SizedBox(
        width: containerWidth,
        height: headerHeight,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: containerWidth,
              maxHeight: headerHeight,
            ),
            child: logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                    placeholder: (context, url) => const SizedBox.shrink(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final isLargeKiosk = DeviceConfig().isLargeKiosk(context);
    final isTablet = DeviceConfig().isTabletSized(context);
    final isSmall = _isSmallScreen(context);
    final customTitle = ref.watch(headerTitleProvider);
    final displayTitle = customTitle ?? '';

    // 태블릿은 캐시된 값을 사용해 orientation·MediaQuery 변화에 흔들리지 않게 한다.
    final double fontSize;
    final double letterSpacingBase;
    if (isTablet) {
      _ensureTabletDimensionsCached(context);
      fontSize = _tabletFontSize!;
      letterSpacingBase = _tabletFontSize! * (40.0 / 52.0);
    } else {
      final titleFontBase = isLargeKiosk ? 64.0 : 48.0;
      fontSize = _getResponsiveSize(context, titleFontBase);
      letterSpacingBase = _getResponsiveSize(context, 40.0);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        displayTitle,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          color: AppColors.textWhite,
          fontSize: fontSize,
          fontVariations: const <FontVariation>[
            FontVariation('wght', 900),
          ],
          letterSpacing: -letterSpacingBase * 0.025,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildClock(BuildContext context) {
    final isTablet = DeviceConfig().isTabletSized(context);
    if (isTablet) _ensureTabletDimensionsCached(context);
    final headerHeight = _getHeaderHeight(context);
    final clockWidth = isTablet
        ? _tabletClockWidth!
        : _getResponsiveSize(context, 200);
    final fontSize = isTablet
        ? (_tabletFontSize! * (32.0 / 52.0))
        : _getResponsiveSize(context, 32);
    final locale = ref.watch(localeProvider);

    return GestureDetector(
      onTap: _handleClockTap,
      child: Container(
        width: clockWidth,
        height: headerHeight,
        color: Colors.transparent,
        child: Center(
          child: StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              final dateString =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final period = locale.languageCode == 'ko' 
                  ? (now.hour < 12 ? '오전' : '오후')
                  : (now.hour < 12 ? 'AM' : 'PM');
              final hour =
                  now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
              final timeString =
                  '$period ${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateString,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: fontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 400),
                      ],
                      color: Colors.white,
                      letterSpacing: -fontSize * 0.025,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: fontSize,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 400),
                      ],
                      color: Colors.white,
                      letterSpacing: -fontSize * 0.025,
                      height: 1.3,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
