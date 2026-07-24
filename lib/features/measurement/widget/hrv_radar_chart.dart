import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 자율신경계(HRV) 결과화면의 레이더(스파이더) 차트.
///
/// Figma 디자인의 색상 존(zone) 배경(5단계: 매우나쁨~매우좋음, 또는 3단계: 나쁨~좋음)
/// 위에 실제 측정값 폴리곤을 겹쳐 그린다. 축 개수(axisCount)와 존 색상(zoneColors,
/// 안쪽→바깥쪽 순서)만 다르면 재사용 가능한 범용 위젯이다.
class HrvRadarChart extends StatelessWidget {
  /// 안쪽(가장 나쁨) → 바깥쪽(가장 좋음) 순서의 존 색상.
  final List<Color> zoneColors;

  /// 각 축의 값(0.0~1.0, 축 개수만큼). 12시 방향부터 시계방향으로 배치된다.
  final List<double> valueFractions;

  final double size;

  const HrvRadarChart({
    super.key,
    required this.zoneColors,
    required this.valueFractions,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HrvRadarChartPainter(
          zoneColors: zoneColors,
          valueFractions: valueFractions,
        ),
      ),
    );
  }
}

class _HrvRadarChartPainter extends CustomPainter {
  final List<Color> zoneColors;
  final List<double> valueFractions;

  _HrvRadarChartPainter({
    required this.zoneColors,
    required this.valueFractions,
  });

  static const Color _lineColor = Color(0xFF231815);

  List<Offset> _polygon(Offset center, double radius, int axisCount) {
    final double angleStep = 2 * math.pi / axisCount;
    return List<Offset>.generate(axisCount, (i) {
      final double angle = -math.pi / 2 + angleStep * i;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int axisCount = valueFractions.length;
    if (axisCount < 3) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.shortestSide / 2 * 0.86;
    final int bandCount = zoneColors.length;

    // 1) 컬러 존 배경 (안쪽→바깥쪽 순서로 각 단계를 고리 형태로 채운다)
    for (int band = 0; band < bandCount; band++) {
      final double outerFrac = (band + 1) / bandCount;
      final double innerFrac = band / bandCount;
      final List<Offset> outerPts =
          _polygon(center, maxRadius * outerFrac, axisCount);

      final Path path = Path()..fillType = PathFillType.evenOdd;
      path.addPolygon(outerPts, true);

      if (innerFrac > 0) {
        final List<Offset> innerPts =
            _polygon(center, maxRadius * innerFrac, axisCount);
        path.addPolygon(innerPts, true);
      }

      final Paint fillPaint = Paint()
        ..color = zoneColors[band].withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      final Paint strokePaint = Paint()
        ..color = _lineColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.0028;
      canvas.drawPath(path, strokePaint);
    }

    // 2) 중심에서 각 꼭짓점으로 이어지는 축(스포크) 선
    final List<Offset> outerVertices = _polygon(center, maxRadius, axisCount);
    final Paint spokePaint = Paint()
      ..color = _lineColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.0028;
    for (final Offset vertex in outerVertices) {
      canvas.drawLine(center, vertex, spokePaint);
    }

    // 3) 실제 측정값 폴리곤 (진한 선 + 꼭짓점 도트)
    final List<Offset> valuePoints = List<Offset>.generate(axisCount, (i) {
      final double frac = valueFractions[i].clamp(0.0, 1.0);
      final double angle = -math.pi / 2 + (2 * math.pi / axisCount) * i;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * (maxRadius * frac);
    });

    final Path valuePath = Path()..addPolygon(valuePoints, true);
    final Paint valueStrokePaint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.014
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(valuePath, valueStrokePaint);

    final Paint dotPaint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.fill;
    final double dotRadius = size.shortestSide * 0.019;
    for (final Offset point in valuePoints) {
      canvas.drawCircle(point, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HrvRadarChartPainter oldDelegate) {
    return oldDelegate.zoneColors != zoneColors ||
        oldDelegate.valueFractions != valueFractions;
  }
}
