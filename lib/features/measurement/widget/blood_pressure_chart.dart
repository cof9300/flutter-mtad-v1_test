import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/utils/blood_pressure_calculator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class BloodPressureChart extends StatelessWidget {
  final int systolic;
  final int diastolic;

  const BloodPressureChart({
    super.key,
    required this.systolic,
    required this.diastolic,
  });

  static const List<Color> _chartColors = [
    Color(0xFF7EBA68),
    Color(0xFFDECD5A),
    Color(0xFFECB150),
    Color(0xFFC2503D),
    Color(0xFFA52648),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final markerPosition = _calculateMarkerPosition(systolic, diastolic, width, context);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _chartColors[0],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: _chartColors[1],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: _chartColors[2],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: _chartColors[3],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _chartColors[4],
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: markerPosition - 20,
                top: 20,
                child: SvgPicture.asset(
                  'assets/icons/marker.svg',
                  width: 40,
                  height: 52,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateMarkerPosition(int systolic, int diastolic, double width, BuildContext context) {
    final segmentWidth = width / 5;
    final status = BloodPressureCalculator.getStatus(systolic, diastolic, context);
    final l10n = AppLocalizations.of(context)!;

    // 각 단계의 중앙 위치에 화살표 배치
    if (status == l10n.bpStatusNormal) {
      // 정상: 0번째 세그먼트 중앙
      return segmentWidth * 0.5;
    } else if (status == l10n.bpStatusCaution) {
      // 주의혈압: 1번째 세그먼트 중앙
      return segmentWidth * 1.5;
    } else if (status == l10n.bpStatusPreHypertension) {
      // 전고혈압: 2번째 세그먼트 중앙
      return segmentWidth * 2.5;
    } else if (status == l10n.bpStatusHypertension1) {
      // 고혈압1기: 3번째 세그먼트 중앙
      return segmentWidth * 3.5;
    } else {
      // 고혈압2기: 4번째 세그먼트 중앙
      return segmentWidth * 4.5;
    }
  }
}









