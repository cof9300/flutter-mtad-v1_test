import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class NumberKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;
  final double? scale;

  const NumberKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = scale ?? 1.0;
    
    final isMobile = screenWidth < 600;
    final paddingVal = isMobile ? 24.0 : 80.0;
    final rowSpacing = isMobile ? 12.0 : 24.0;
    
    final availableWidth = screenWidth - (paddingVal * 2);
    final buttonWidth = isMobile 
        ? ((availableWidth - 32) / 3).clamp(80.0, 96.0)
        : ((availableWidth - 80) / 3).clamp(150.0, 200.0);
    final buttonSpacing = isMobile 
        ? ((availableWidth - (buttonWidth * 3)) / 2).clamp(12.0, 18.0)
        : ((availableWidth - (buttonWidth * 3)) / 2).clamp(20.0, 40.0);

    return Transform.scale(
      scale: scaleFactor,
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: paddingVal),
        child: Column(
          children: [
            _buildRow(['1', '2', '3'], buttonWidth, buttonSpacing),
            SizedBox(height: rowSpacing),
            _buildRow(['4', '5', '6'], buttonWidth, buttonSpacing),
            SizedBox(height: rowSpacing),
            _buildRow(['7', '8', '9'], buttonWidth, buttonSpacing),
            SizedBox(height: rowSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _KeypadButton(
                  buttonWidth: buttonWidth,
                  onTap: onClearAll,
                  child: Text(
                    l10n.authClearAll,
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: buttonWidth * 0.16,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                SizedBox(width: buttonSpacing),
                _KeypadButton(
                  buttonWidth: buttonWidth,
                  onTap: () => onNumberPressed('0'),
                  child: Text(
                    '0',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: buttonWidth * 0.24,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                SizedBox(width: buttonSpacing),
                _KeypadButton(
                  buttonWidth: buttonWidth,
                  onTap: onDelete,
                  child: SvgPicture.asset(
                    'assets/icons/keypad-back.svg',
                    width: buttonWidth * 0.32,
                    height: buttonWidth * 0.32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> numbers, double buttonWidth, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _KeypadButton(
          buttonWidth: buttonWidth,
          onTap: () => onNumberPressed(numbers[0]),
          child: Text(
            numbers[0],
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: buttonWidth * 0.24,
              fontVariations: <FontVariation>[
                FontVariation('wght', 700),
              ],
              color: Color(0xFF111111),
            ),
          ),
        ),
        SizedBox(width: spacing),
        _KeypadButton(
          buttonWidth: buttonWidth,
          onTap: () => onNumberPressed(numbers[1]),
          child: Text(
            numbers[1],
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: buttonWidth * 0.24,
              fontVariations: <FontVariation>[
                FontVariation('wght', 700),
              ],
              color: Color(0xFF111111),
            ),
          ),
        ),
        SizedBox(width: spacing),
        _KeypadButton(
          buttonWidth: buttonWidth,
          onTap: () => onNumberPressed(numbers[2]),
          child: Text(
            numbers[2],
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: buttonWidth * 0.24,
              fontVariations: <FontVariation>[
                FontVariation('wght', 700),
              ],
              color: Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final double buttonWidth;
  final VoidCallback onTap;
  final Widget child;

  const _KeypadButton({
    required this.buttonWidth,
    required this.onTap,
    required this.child,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.buttonWidth * 0.6;

    return Listener(
      onPointerDown: (_) {
        if (mounted) {
          setState(() => _isPressed = true);
          widget.onTap();
        }
      },
      onPointerUp: (_) {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() => _isPressed = false);
        }
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
