import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class AuthRightPanel extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onClearAll;
  final VoidCallback onDelete;
  final double? scale;

  const AuthRightPanel({
    super.key,
    required this.onNumberPressed,
    required this.onClearAll,
    required this.onDelete,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        
        final verticalPadding = (availableHeight * 0.05).clamp(10.0, 25.0);
        final horizontalPadding = (availableWidth * 0.05).clamp(10.0, 30.0);
        
        final contentHeight = availableHeight - (verticalPadding * 2);
        
        final totalRows = 4;
        final totalGaps = 3;
        final gapSize = (contentHeight * 0.04).clamp(8.0, 16.0);
        final totalGapHeight = gapSize * totalGaps;
        
        final buttonSize = ((contentHeight - totalGapHeight) / totalRows).clamp(55.0, 95.0);
        final horizontalSpacing = (buttonSize * 0.18).clamp(10.0, 18.0);
        final fontSize = (buttonSize * 0.36).clamp(20.0, 34.0);
        final clearAllFontSize = (buttonSize * 0.22).clamp(12.0, 21.0);
        final iconSize = (buttonSize * 0.42).clamp(23.0, 40.0);

        final scaleFactor = scale ?? 1.0;
        
        return Transform.scale(
          scale: scaleFactor,
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow(['1', '2', '3'], buttonSize, horizontalSpacing, fontSize),
                SizedBox(height: gapSize),
                _buildRow(['4', '5', '6'], buttonSize, horizontalSpacing, fontSize),
                SizedBox(height: gapSize),
                _buildRow(['7', '8', '9'], buttonSize, horizontalSpacing, fontSize),
                SizedBox(height: gapSize),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AuthRightPanelKeypadButton(
                      buttonSize: buttonSize,
                      onTap: onClearAll,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            l10n.authClearAll,
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: clearAllFontSize,
                              fontVariations: <FontVariation>[
                                FontVariation('wght', 700),
                              ],
                              color: Color(0xFF111111),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: horizontalSpacing),
                    _AuthRightPanelKeypadButton(
                      buttonSize: buttonSize,
                      onTap: () => onNumberPressed('0'),
                      child: Text(
                        '0',
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
                    SizedBox(width: horizontalSpacing),
                    _AuthRightPanelKeypadButton(
                      buttonSize: buttonSize,
                      onTap: onDelete,
                      child: SvgPicture.asset(
                        'assets/icons/keypad-back.svg',
                        width: iconSize,
                        height: iconSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(List<String> numbers, double buttonSize, double spacing, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AuthRightPanelKeypadButton(
          buttonSize: buttonSize,
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
        _AuthRightPanelKeypadButton(
          buttonSize: buttonSize,
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
        _AuthRightPanelKeypadButton(
          buttonSize: buttonSize,
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
  }
}

class _AuthRightPanelKeypadButton extends StatefulWidget {
  final double buttonSize;
  final VoidCallback onTap;
  final Widget child;

  const _AuthRightPanelKeypadButton({
    required this.buttonSize,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AuthRightPanelKeypadButton> createState() =>
      _AuthRightPanelKeypadButtonState();
}

class _AuthRightPanelKeypadButtonState extends State<_AuthRightPanelKeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
        width: widget.buttonSize,
        height: widget.buttonSize,
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

