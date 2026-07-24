import 'package:flutter/material.dart';
import 'package:flutter_template/config/alco_bluetooth_constants.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class AlcoMeasurementStatusWidget extends StatelessWidget {
  final int stateCode;
  final Color? color;

  const AlcoMeasurementStatusWidget({
    super.key,
    required this.stateCode,
    this.color,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize).clamp(
      baseSize * 0.5,
      baseSize * 1.5,
    );
  }

  _StateInfo _resolveState() {
    switch (stateCode) {
      case AlcoBluetoothConstants.stateWarmUp:
        return _StateInfo(Icons.thermostat, '기기 워밍업 중...');
      case AlcoBluetoothConstants.stateWaitBlowing:
        return _StateInfo(Icons.air, '숨을 불어넣으세요');
      case AlcoBluetoothConstants.stateBlowing:
        return _StateInfo(Icons.mic, '측정 중...');
      case AlcoBluetoothConstants.stateAnalyzing:
        return _StateInfo(Icons.analytics, '분석 중...');
      default:
        return _StateInfo(Icons.hourglass_top, '측정 준비 중...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _resolveState();
    final iconSize = _getResponsiveSize(context, 120);
    final textSize = _getResponsiveSize(context, 56);
    final spacing = _getResponsiveSize(context, 32);
    final resolvedColor = color ?? const Color(0xFF227EFF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(info.icon, size: iconSize, color: resolvedColor),
        SizedBox(height: spacing),
        Text(
          info.label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: textSize,
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            color: color ?? const Color(0xFF111111),
            letterSpacing: -1.4,
          ),
        ),
      ],
    );
  }
}

class _StateInfo {
  final IconData icon;
  final String label;
  const _StateInfo(this.icon, this.label);
}
