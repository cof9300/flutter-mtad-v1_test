import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class AuthBirthdayGenderKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;

  const AuthBirthdayGenderKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 80.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final buttonSpacing = (availableWidth * 0.07).clamp(50.0, 85.0);
    final totalSpacing = buttonSpacing * 2;
    final buttonWidth =
        ((availableWidth - totalSpacing) / 3).clamp(140.0, 240.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3'], buttonWidth, buttonSpacing),
          SizedBox(height: 20),
          _buildRow(['4', '5', '6'], buttonWidth, buttonSpacing),
          SizedBox(height: 20),
          _buildRow(['7', '8', '9'], buttonWidth, buttonSpacing),
          SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final calculatedWidth =
                  ((maxWidth - (buttonSpacing * 2)) / 3).clamp(140.0, 240.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _KeypadButton(
                    buttonWidth: calculatedWidth,
                    onTap: onClearAll,
                    child: Text(
                      l10n.authClearAll,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: (calculatedWidth * 0.18).clamp(24.0, 34.0),
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  _KeypadButton(
                    buttonWidth: calculatedWidth,
                    onTap: () => onNumberPressed('0'),
                    child: Text(
                      '0',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: (calculatedWidth * 0.28).clamp(36.0, 52.0),
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  _KeypadButton(
                    buttonWidth: calculatedWidth,
                    onTap: onDelete,
                    child: SvgPicture.asset(
                      'assets/icons/keypad-back.svg',
                      width: (calculatedWidth * 0.35).clamp(50.0, 75.0),
                      height: (calculatedWidth * 0.35).clamp(50.0, 75.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers, double buttonWidth, double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final calculatedWidth =
            ((maxWidth - (spacing * 2)) / 3).clamp(140.0, 240.0);
        final fontSize = (calculatedWidth * 0.28).clamp(36.0, 52.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeypadButton(
              buttonWidth: calculatedWidth,
              onTap: () => onNumberPressed(numbers[0]),
              child: Text(
                numbers[0],
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: fontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Color(0xFF111111),
                ),
              ),
            ),
            SizedBox(width: spacing),
            _KeypadButton(
              buttonWidth: calculatedWidth,
              onTap: () => onNumberPressed(numbers[1]),
              child: Text(
                numbers[1],
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: fontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Color(0xFF111111),
                ),
              ),
            ),
            SizedBox(width: spacing),
            _KeypadButton(
              buttonWidth: calculatedWidth,
              onTap: () => onNumberPressed(numbers[2]),
              child: Text(
                numbers[2],
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: fontSize,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ],
        );
      },
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
    final buttonHeight = (widget.buttonWidth * 0.5).clamp(80.0, 120.0);

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
