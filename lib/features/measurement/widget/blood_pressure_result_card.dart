import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

class BloodPressureResultCard extends StatelessWidget {
  final BloodPressureResult result;

  const BloodPressureResultCard({
    super.key,
    required this.result,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _getResponsiveSize(context, 700),
      padding: EdgeInsets.all(_getResponsiveSize(context, 50)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '측정 시간',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          Text(
            _formatDateTime(result.measuredAt),
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 40)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildValueColumn(
                context,
                '수축기',
                result.systolic,
                'mmHg',
                Colors.red,
              ),
              Text(
                '/',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 60),
                  fontVariations: <FontVariation>[FontVariation('wght', 700)],
                  color: Colors.grey,
                ),
              ),
              _buildValueColumn(
                context,
                '이완기',
                result.diastolic,
                'mmHg',
                Colors.blue,
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 40)),
          _buildValueColumn(
            context,
            '맥박',
            result.pulse,
            'bpm',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(
    BuildContext context,
    String label,
    int value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 28),
            color: Colors.grey,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 12)),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 64),
            fontVariations: <FontVariation>[
              FontVariation('wght', 900),
            ],
            color: color,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 8)),
        Text(
          unit,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 24),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}















