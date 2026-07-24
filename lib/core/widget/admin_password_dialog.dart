import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/config/device_config.dart';

class AdminPasswordDialog {
  static OverlayEntry? _overlayEntry;
  static Function(String)? _onSuccess;
  static bool _showConfirmButton = false;
  static final GlobalKey<_AdminPasswordDialogWidgetState> _dialogKey =
      GlobalKey();

  static void show(
    BuildContext context, {
    required Function(String) onSuccess,
    bool showConfirmButton = false,
  }) {
    if (_overlayEntry != null) return;

    _onSuccess = onSuccess;
    _showConfirmButton = showConfirmButton;
    _overlayEntry = OverlayEntry(
      builder: (context) => _AdminPasswordDialogWidget(key: _dialogKey),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _onSuccess = null;
    _showConfirmButton = false;
  }

  static void _handleSuccess(String password) {
    _onSuccess?.call(password);
  }

  static void showError() {
    _dialogKey.currentState?.showError();
  }
}

class _AdminPasswordDialogWidget extends StatefulWidget {
  const _AdminPasswordDialogWidget({super.key});

  @override
  State<_AdminPasswordDialogWidget> createState() =>
      _AdminPasswordDialogWidgetState();
}

class _AdminPasswordDialogWidgetState
    extends State<_AdminPasswordDialogWidget> {
  String _inputValue = '';
  bool _isError = false;
  String? _errorMessage;

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _onNumberPressed(String number) {
    if (_inputValue.length >= 4) return;

    setState(() {
      _inputValue += number;
      _isError = false;
      _errorMessage = null;
    });

    // 확인 버튼이 없는 경우(원래 동작): 4자리 입력 시 자동 완료
    if (!AdminPasswordDialog._showConfirmButton && _inputValue.length == 4) {
      final password = _inputValue;
      Future.microtask(() {
        AdminPasswordDialog._handleSuccess(password);
      });
    }
  }

  void _onConfirm() {
    if (_inputValue.length != 4) {
      setState(() {
        _isError = true;
        _errorMessage = '4자리 비밀번호를 입력해주세요.';
      });
      return;
    }

    AdminPasswordDialog._handleSuccess(_inputValue);
    AdminPasswordDialog.hide();
  }

  void _onClearAll() {
    setState(() {
      _inputValue = '';
      _isError = false;
      _errorMessage = null;
    });
  }

  void _onDelete() {
    if (_inputValue.isEmpty) return;

    setState(() {
      _inputValue = _inputValue.substring(0, _inputValue.length - 1);
      _isError = false;
      _errorMessage = null;
    });
  }

  void showError() {
    setState(() {
      _inputValue = '';
      _isError = true;
      _errorMessage = '관리자 비밀번호가 잘못되었습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = !DeviceConfig().isLargeKiosk(context) &&
        !DeviceConfig().isTabletSized(context);

    final modalWidth = isMobile
        ? (screenWidth * 0.85)
        : (screenWidth * 0.9).clamp(400.0, 700.0);
    final padding = isMobile
        ? _getResponsiveSize(context, 30)
        : _getResponsiveSize(context, 60);
    final verticalPadding = isMobile
        ? _getResponsiveSize(context, 45)
        : _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 36);
    final inputFontSize = _getResponsiveSize(context, 48);
    final errorFontSize = _getResponsiveSize(context, 28);
    final borderRadius = _getResponsiveSize(context, 50);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: modalWidth,
          padding: EdgeInsets.symmetric(
              vertical: verticalPadding, horizontal: padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.09),
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adminPasswordTitle,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: titleFontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: isMobile ? 16 : _getResponsiveSize(context, 40)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : _getResponsiveSize(context, 30),
                    horizontal: _getResponsiveSize(context, 40)),
                decoration: BoxDecoration(
                  color: _isError ? Color(0xFFFFEBEE) : Color(0xFFF5F5F5),
                  borderRadius:
                      BorderRadius.circular(_getResponsiveSize(context, 16)),
                  border:
                      _isError ? Border.all(color: Colors.red, width: 2) : null,
                ),
                child: Text(
                  _inputValue.padRight(4, '○'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: inputFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    color: _isError ? Colors.red : AppColors.primary,
                    letterSpacing: 20,
                  ),
                ),
              ),
              if (_isError && _errorMessage != null) ...[
                SizedBox(height: isMobile ? 8 : _getResponsiveSize(context, 16)),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: errorFontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    color: Colors.red,
                  ),
                ),
              ],
              SizedBox(height: isMobile ? 16 : _getResponsiveSize(context, 40)),
              SizedBox(
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final paddingValue = isMobile ? 10.0 : 40.0;
                    final availableWidth = constraints.maxWidth - paddingValue;
                    final buttonWidth = isMobile
                        ? (availableWidth - 16) / 3
                        : ((availableWidth - 40) / 3).clamp(80.0, 150.0);
                    final buttonSpacing = isMobile
                        ? 8.0
                        : ((availableWidth - (buttonWidth * 3) - 40) / 2)
                            .clamp(10.0, 20.0);

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 20),
                      child: Column(
                        children: [
                          _buildKeypadRow(
                              ['1', '2', '3'], buttonWidth, buttonSpacing),
                          SizedBox(height: isMobile ? 8 : 16),
                          _buildKeypadRow(
                              ['4', '5', '6'], buttonWidth, buttonSpacing),
                          SizedBox(height: isMobile ? 8 : 16),
                          _buildKeypadRow(
                              ['7', '8', '9'], buttonWidth, buttonSpacing),
                          SizedBox(height: isMobile ? 8 : 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildClearAllButton(
                                  l10n.authClearAll, buttonWidth, _onClearAll),
                              SizedBox(width: buttonSpacing),
                              _buildKeypadButton('0', buttonWidth,
                                  () => _onNumberPressed('0')),
                              SizedBox(width: buttonSpacing),
                              _buildKeypadDeleteButton(buttonWidth),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 20)),
              AdminPasswordDialog._showConfirmButton
                  ? Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => AdminPasswordDialog.hide(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: _getResponsiveSize(context, 20)),
                              decoration: BoxDecoration(
                                color: Color(0xFF999999),
                                borderRadius: BorderRadius.circular(
                                    _getResponsiveSize(context, 16)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.cancel,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: _getResponsiveSize(context, 36),
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSize(context, 16)),
                        Expanded(
                          child: GestureDetector(
                            onTap: _onConfirm,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: _getResponsiveSize(context, 20)),
                              decoration: BoxDecoration(
                                color: AppColors.headerBackground,
                                borderRadius: BorderRadius.circular(
                                    _getResponsiveSize(context, 16)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.confirm,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.bodyFontFamily,
                                  fontSize: _getResponsiveSize(context, 36),
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => AdminPasswordDialog.hide(),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: _getResponsiveSize(context, 20)),
                        decoration: BoxDecoration(
                          color: Color(0xFF999999),
                          borderRadius: BorderRadius.circular(
                              _getResponsiveSize(context, 16)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: AppTextStyles.bodyFontFamily,
                            fontSize: _getResponsiveSize(context, 36),
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 600),
                            ],
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(
      List<String> numbers, double buttonWidth, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKeypadButton(
            numbers[0], buttonWidth, () => _onNumberPressed(numbers[0])),
        SizedBox(width: spacing),
        _buildKeypadButton(
            numbers[1], buttonWidth, () => _onNumberPressed(numbers[1])),
        SizedBox(width: spacing),
        _buildKeypadButton(
            numbers[2], buttonWidth, () => _onNumberPressed(numbers[2])),
      ],
    );
  }

  Widget _buildKeypadButton(
      String text, double buttonWidth, VoidCallback onTap) {
    final fontSize = buttonWidth * 0.3;

    return _AdminKeypadButton(
      buttonWidth: buttonWidth,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontSize: fontSize,
          fontVariations: <FontVariation>[FontVariation('wght', 700)],
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildClearAllButton(
      String text, double buttonWidth, VoidCallback onTap) {
    final fontSize = buttonWidth * 0.2;

    return _AdminKeypadButton(
      buttonWidth: buttonWidth,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontSize: fontSize,
          fontVariations: <FontVariation>[FontVariation('wght', 700)],
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildKeypadDeleteButton(double buttonWidth) {
    final iconSize = buttonWidth * 0.4;

    return _AdminKeypadButton(
      buttonWidth: buttonWidth,
      onTap: _onDelete,
      child: SvgPicture.asset(
        'assets/icons/keypad-back.svg',
        width: iconSize,
        height: iconSize,
      ),
    );
  }
}

class _AdminKeypadButton extends StatefulWidget {
  final double buttonWidth;
  final VoidCallback onTap;
  final Widget child;

  const _AdminKeypadButton({
    required this.buttonWidth,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AdminKeypadButton> createState() => _AdminKeypadButtonState();
}

class _AdminKeypadButtonState extends State<_AdminKeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final buttonHeight = widget.buttonWidth * (isMobile ? 0.55 : 0.7);

    return Listener(
      onPointerDown: (_) {
        if (mounted) {
          setState(() => _isPressed = true);
          widget.onTap();
        }
      },
      onPointerUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      child: Container(
        width: widget.buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.black.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
