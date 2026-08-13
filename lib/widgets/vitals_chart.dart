import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class VitalPoint {
  final DateTime timestamp;
  final int heartRate;
  final int spO2;

  VitalPoint({
    required this.timestamp,
    required this.heartRate,
    required this.spO2,
  });
}

class VitalsHistoryChart extends StatefulWidget {
  final List<VitalPoint> vitalPoints;

  const VitalsHistoryChart({
    super.key,
    required this.vitalPoints,
  });

  @override
  State<VitalsHistoryChart> createState() => _VitalsHistoryChartState();
}

class _VitalsHistoryChartState extends State<VitalsHistoryChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.vitalPoints;

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vitals History Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Touch chart to view exact metrics',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('HR (BPM)', const Color(0xFFFF5252)),
                  const SizedBox(width: 12),
                  _buildLegendItem('SpO2 (%)', const Color(0xFF448AFF)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive Chart Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
                  onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
                  onTapDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
                  onTapUp: (_) => setState(() => _selectedIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _DualAxisChartPainter(
                      vitalPoints: points,
                      selectedIndex: _selectedIndex,
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

  void _handleTouch(Offset localPosition, double width) {
    if (widget.vitalPoints.isEmpty) return;
    final double stepX = widget.vitalPoints.length > 1
        ? (width - 60) / (widget.vitalPoints.length - 1)
        : width - 60;
    
    // Account for left margin (35px)
    final double touchX = localPosition.dx - 35;
    int index = (touchX / stepX).round().clamp(0, widget.vitalPoints.length - 1);
    
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _DualAxisChartPainter extends CustomPainter {
  final List<VitalPoint> vitalPoints;
  final int? selectedIndex;

  _DualAxisChartPainter({
    required this.vitalPoints,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 35.0;
    const double rightMargin = 30.0;
    const double bottomMargin = 22.0;

    final double chartWidth = size.width - leftMargin - rightMargin;
    final double chartHeight = size.height - bottomMargin;

    // Draw Grid & Axes Labels
    _drawAxesAndGrid(canvas, size, leftMargin, rightMargin, bottomMargin, chartWidth, chartHeight);

    if (vitalPoints.isEmpty) {
      _drawNoDataPlaceholder(canvas, size);
      return;
    }

    // HR Axis Range: 40 to 160 BPM
    // SpO2 Axis Range: 85 to 100 %
    final hrPoints = _calculateOffsets(
      vitalPoints.map((p) => p.heartRate.toDouble()).toList(),
      40.0,
      160.0,
      leftMargin,
      chartWidth,
      chartHeight,
    );

    final spO2Points = _calculateOffsets(
      vitalPoints.map((p) => p.spO2.toDouble()).toList(),
      85.0,
      100.0,
      leftMargin,
      chartWidth,
      chartHeight,
    );

    // Draw Curves
    _drawCurve(canvas, chartHeight, hrPoints, const Color(0xFFFF5252));
    _drawCurve(canvas, chartHeight, spO2Points, const Color(0xFF448AFF));

    // Draw X-Axis Timestamps
    _drawTimestamps(canvas, vitalPoints, leftMargin, chartWidth, chartHeight);

    // Draw Touch Highlight & Tooltip
    if (selectedIndex != null && selectedIndex! < vitalPoints.length) {
      final idx = selectedIndex!;
      final hrOffset = hrPoints[idx];
      final spO2Offset = spO2Points[idx];
      final point = vitalPoints[idx];

      final linePaint = Paint()
        ..color = Colors.white30
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Touch Vertical Line
      canvas.drawLine(
        Offset(hrOffset.dx, 0),
        Offset(hrOffset.dx, chartHeight),
        linePaint,
      );

      // Touch Point Rings
      canvas.drawCircle(hrOffset, 6, Paint()..color = const Color(0xFFFF5252));
      canvas.drawCircle(hrOffset, 3, Paint()..color = Colors.white);

      canvas.drawCircle(spO2Offset, 6, Paint()..color = const Color(0xFF448AFF));
      canvas.drawCircle(spO2Offset, 3, Paint()..color = Colors.white);

      // Tooltip Card
      _drawTooltip(canvas, size, hrOffset.dx, point);
    }
  }

  void _drawAxesAndGrid(
    Canvas canvas,
    Size size,
    double leftMargin,
    double rightMargin,
    double bottomMargin,
    double chartWidth,
    double chartHeight,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.grey.shade400,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Y Gridlines (4 rows)
    for (int i = 0; i <= 3; i++) {
      final double y = (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      // Left Y-Axis Label (HR: 160 -> 40)
      final int hrVal = 160 - (i * 40);
      final hrTp = TextPainter(
        text: TextSpan(text: '$hrVal', style: textStyle.copyWith(color: const Color(0xFFFF8A8A))),
        textDirection: TextDirection.ltr,
      )..layout();
      hrTp.paint(canvas, Offset(5, y - (hrTp.height / 2)));

      // Right Y-Axis Label (SpO2: 100 -> 85)
      final int spVal = 100 - (i * 5);
      final spTp = TextPainter(
        text: TextSpan(text: '$spVal%', style: textStyle.copyWith(color: const Color(0xFF82B1FF))),
        textDirection: TextDirection.ltr,
      )..layout();
      spTp.paint(canvas, Offset(size.width - rightMargin + 5, y - (spTp.height / 2)));
    }
  }

  List<Offset> _calculateOffsets(
    List<double> values,
    double minVal,
    double maxVal,
    double leftMargin,
    double chartWidth,
    double chartHeight,
  ) {
    final List<Offset> points = [];
    final double stepX = values.length > 1 ? chartWidth / (values.length - 1) : chartWidth;

    for (int i = 0; i < values.length; i++) {
      final val = values[i].clamp(minVal, maxVal);
      final ratioY = (val - minVal) / (maxVal - minVal);
      final y = chartHeight - (ratioY * chartHeight);
      final x = leftMargin + (stepX * i);
      points.add(Offset(x, y));
    }
    return points;
  }

  void _drawCurve(Canvas canvas, double chartHeight, List<Offset> points, Color color) {
    if (points.isEmpty) return;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()
      ..moveTo(points[0].dx, chartHeight)
      ..lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    // Gradient Fill
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, chartHeight),
        [color.withOpacity(0.22), color.withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line Paint
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2, Paint()..color = const Color(0xFF1E293B));
    }
  }

  void _drawTimestamps(
    Canvas canvas,
    List<VitalPoint> points,
    double leftMargin,
    double chartWidth,
    double chartHeight,
  ) {
    if (points.length < 2) return;
    final double stepX = chartWidth / (points.length - 1);
    final textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 9);

    // Draw first, middle, and last timestamp
    final indicesToDraw = [0, (points.length / 2).floor(), points.length - 1];
    for (final idx in indicesToDraw) {
      final point = points[idx];
      final timeStr =
          '${point.timestamp.hour.toString().padLeft(2, '0')}:${point.timestamp.minute.toString().padLeft(2, '0')}:${point.timestamp.second.toString().padLeft(2, '0')}';

      final tp = TextPainter(
        text: TextSpan(text: timeStr, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = (leftMargin + (stepX * idx)) - (tp.width / 2);
      tp.paint(canvas, Offset(x.clamp(leftMargin, chartWidth + leftMargin - tp.width), chartHeight + 6));
    }
  }

  void _drawTooltip(Canvas canvas, Size size, double touchX, VitalPoint point) {
    final timeStr =
        '${point.timestamp.hour.toString().padLeft(2, '0')}:${point.timestamp.minute.toString().padLeft(2, '0')}';
    final text = 'Time: $timeStr  |  HR: ${point.heartRate} BPM  |  SpO2: ${point.spO2}%';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardWidth = textPainter.width + 16;
    final cardHeight = textPainter.height + 10;
    double cardX = touchX - (cardWidth / 2);
    cardX = cardX.clamp(10, size.width - cardWidth - 10);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardX, 0, cardWidth, cardHeight),
      const Radius.circular(8),
    );

    final cardPaint = Paint()..color = const Color(0xFF0F172A).withOpacity(0.92);
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rect, cardPaint);
    canvas.drawRRect(rect, borderPaint);

    textPainter.paint(canvas, Offset(cardX + 8, 5));
  }

  void _drawNoDataPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Waiting for live health vitals...',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DualAxisChartPainter oldDelegate) {
    return oldDelegate.vitalPoints != vitalPoints || oldDelegate.selectedIndex != selectedIndex;
  }
}

