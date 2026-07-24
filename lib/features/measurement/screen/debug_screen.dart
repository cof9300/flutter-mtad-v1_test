import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  String? _rawData;
  BloodPressureResult? _latestResult;

  @override
  void initState() {
    super.initState();
    
    MeasurementListener().logStream.listen((logMessage) {
      if (mounted) {
        setState(() {
          final timestamp = DateTime.now().toString().substring(11, 19);
          _logs.insert(0, '[$timestamp] $logMessage');
          if (_logs.length > 200) {
            _logs.removeRange(200, _logs.length);
          }
        });
      }
    });

    MeasurementListener().rawDataStream.listen((rawData) {
      if (mounted) {
        setState(() {
          _rawData = rawData;
        });
      }
    });

    MeasurementListener().bloodPressureStream.listen((result) {
      if (mounted) {
        setState(() {
          _latestResult = result;
        });
      }
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
    return CommonLayout(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: _getResponsiveSize(context, 20),
                top: _getResponsiveSize(context, 20),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: _getResponsiveSize(context, 60),
                    height: _getResponsiveSize(context, 60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSize(context, 8),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: _getResponsiveSize(context, 30),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: _getResponsiveSize(context, 20)),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, 40),
              ),
              child: Text(
                'USB 데이터 디버그',
                style: TextStyle(
                  fontFamily: AppTextStyles.titleFontFamily,
                  fontSize: _getResponsiveSize(context, 48),
                  fontVariations: <FontVariation>[FontVariation('wght', 900)],
                  color: Color(0xFF111111),
                ),
              ),
            ),

            SizedBox(height: _getResponsiveSize(context, 20)),

            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
                child: _buildResultCard(),
              ),
            ),

            if (_rawData != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_getResponsiveSize(context, 8)),
                margin: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 12),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          size: _getResponsiveSize(context, 14),
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: _getResponsiveSize(context, 4)),
                        Text(
                          'Raw Data',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 11),
                            fontVariations: <FontVariation>[FontVariation('wght', 700)],
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveSize(context, 4)),
                    SelectableText(
                      _rawData!,
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 10),
                        fontFamily: 'monospace',
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: _getResponsiveSize(context, 10)),

            Expanded(
              flex: 3,
              child: _buildLogConsole(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_latestResult == null) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: _getResponsiveSize(context, 48),
                color: Colors.grey[400],
              ),
              SizedBox(height: _getResponsiveSize(context, 12)),
              Text(
                '측정 데이터 대기 중...',
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 24),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final result = _latestResult!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '측정 시간: ${_formatDateTime(result.measuredAt)}',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildValue('수축기', result.systolic, 'mmHg', Colors.red),
                Text(
                  '/',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 32),
                    fontVariations: <FontVariation>[FontVariation('wght', 700)],
                  ),
                ),
                _buildValue('이완기', result.diastolic, 'mmHg', Colors.blue),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            _buildValue('맥박', result.pulse, 'bpm', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildValue(String label, int value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: AppTextStyles.titleFontFamily,
            fontSize: _getResponsiveSize(context, 36),
            fontVariations: <FontVariation>[FontVariation('wght', 700)],
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 10),
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildLogConsole() {
    return Card(
      margin: EdgeInsets.all(_getResponsiveSize(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_getResponsiveSize(context, 8)),
            child: Row(
              children: [
                Icon(Icons.terminal, size: _getResponsiveSize(context, 16)),
                SizedBox(width: _getResponsiveSize(context, 4)),
                Text(
                  '로그',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontVariations: <FontVariation>[FontVariation('wght', 700)],
                    fontSize: _getResponsiveSize(context, 12),
                  ),
                ),
                Spacer(),
                if (_logs.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: Text(
                      '지우기',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      '로그가 없습니다',
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: _getResponsiveSize(context, 14),
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(context, 8),
                          vertical: _getResponsiveSize(context, 2),
                        ),
                        child: Text(
                          _logs[index],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: _getResponsiveSize(context, 10),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

