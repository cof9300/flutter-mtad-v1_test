import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/utils/height_weight_calculator.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class BmiChart extends StatelessWidget {
  final double bmi;

  const BmiChart({super.key, required this.bmi});

  static const List<Color> _segmentColors = [
    Color(0xFFDECD5A),
    Color(0xFF7EBA68),
    Color(0xFF7FB5D5),
    Color(0xFFECB150),
    Color(0xFFC2503D),
    Color(0xFFA52648),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final markerX = _markerPosition(width, context);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildBar(),
              Positioned(
                left: markerX - 20,
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

  Widget _buildBar() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        height: 30,
        child: Row(
          children: [
            _buildSegment(0, isFirst: true),
            _buildSegment(1),
            _buildSegment(2),
            _buildSegment(3),
            _buildSegment(4),
            _buildSegment(5, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(int index, {bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _segmentColors[index],
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(15) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(15) : Radius.zero,
            topRight: isLast ? const Radius.circular(15) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(15) : Radius.zero,
          ),
        ),
      ),
    );
  }

  double _markerPosition(double width, BuildContext context) {
    final segmentWidth = width / 6;
    final l10n = AppLocalizations.of(context)!;
    final status = HeightWeightCalculator.getBmiStatus(bmi, context);

    if (status == l10n.bmiStatusUnderweight) return segmentWidth * 0.5;
    if (status == l10n.bmiStatusNormal) return segmentWidth * 1.5;
    if (status == l10n.bmiStatusPreObese) return segmentWidth * 2.5;
    if (status == l10n.bmiStatusObese1) return segmentWidth * 3.5;
    if (status == l10n.bmiStatusObese2) return segmentWidth * 4.5;
    return segmentWidth * 5.5;
  }
}
