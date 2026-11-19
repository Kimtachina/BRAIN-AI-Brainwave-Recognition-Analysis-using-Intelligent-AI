import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════
// ตัววาดกราฟคลื่นสมอง EEG เกรดงานวิจัยที่มีตารางกริด สเกลวัด และสีแยกแยะสำหรับแต่ละช่องสัญญาณประสาท
// ออกแบบขึ้นให้สอดคล้องตามเกณฑ์มาตรฐานสากล (clinical/research EEG viewer conventions)
// ═══════════════════════════════════════════════════════════════════
class EegResearchTracePainter extends CustomPainter {
  final Map<String, List<double>> channels;
  final Map<String, Color> channelColors;
  final List<String> channelNames = const ['TP9', 'AF7', 'AF8', 'TP10'];

  EegResearchTracePainter({
    required this.channels,
    required this.channelColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final double channelHeight = size.height / channelNames.length;
    const double labelWidth = 52.0;
    const double rightPadding = 8.0;
    final double plotWidth = size.width - labelWidth - rightPadding;

    final gridPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    final gridPaintMajor = Paint()
      ..color = AppColors.line
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final baselinePaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // ฟังก์ชันย่อยสำหรับวาดเส้นฐานแนวนอนแบบประ (Dashed baseline helper)
    void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final totalLength = math.sqrt(dx * dx + dy * dy);
      final dirX = dx / totalLength;
      final dirY = dy / totalLength;
      double drawn = 0;
      while (drawn < totalLength) {
        final segEnd = (drawn + dashWidth).clamp(0.0, totalLength);
        canvas.drawLine(
          Offset(start.dx + dirX * drawn, start.dy + dirY * drawn),
          Offset(start.dx + dirX * segEnd, start.dy + dirY * segEnd),
          paint,
        );
        drawn += dashWidth + dashSpace;
      }
    }

    for (int i = 0; i < channelNames.length; i++) {
      final name = channelNames[i];
      final yOffset = i * channelHeight;
      final yCenter = yOffset + channelHeight / 2;
      final chColor = channelColors[name] ?? AppColors.primaryDeep;

      // วาดพื้นหลังสลับสีเพื่อแยกบรรทัดแต่ละแชลแนล (Alternating background)
      if (i % 2 == 1) {
        canvas.drawRect(
          Rect.fromLTWH(0, yOffset, size.width, channelHeight),
          Paint()..color = AppColors.paper,
        );
      }

      // เส้นกริดแนวนอนย่อย 3 เส้นต่อแชลแนล (Grid lines - 3 minor lines per channel)
      for (int g = 1; g <= 3; g++) {
        final gy = yOffset + channelHeight * g / 4;
        canvas.drawLine(
          Offset(labelWidth, gy),
          Offset(size.width - rightPadding, gy),
          gridPaint,
        );
      }

      // เส้นกริดแนวตั้งแบ่งสเกลเวลาออกเป็น 8 ส่วน (Vertical grid lines - 8 segments)
      for (int v = 1; v < 8; v++) {
        final vx = labelWidth + plotWidth * v / 8;
        canvas.drawLine(
          Offset(vx, yOffset),
          Offset(vx, yOffset + channelHeight),
          v == 4 ? gridPaintMajor : gridPaint,
        );
      }

      // เส้นอ้างอิงตรงกลางสมดุลศูนย์ประ (Zero baseline - dashed)
      drawDashedLine(
        canvas,
        Offset(labelWidth, yCenter),
        Offset(size.width - rightPadding, yCenter),
        baselinePaint,
      );

      // เส้นขอบใต้แชลแนลช่องสัญญาณ (Channel border)
      canvas.drawLine(
        Offset(0, yOffset + channelHeight),
        Offset(size.width, yOffset + channelHeight),
        Paint()
          ..color = AppColors.inkFaint
          ..strokeWidth = 0.8,
      );

      // เส้นคั่นแนวตั้งระหว่างชื่อแชลแนลและพื้นที่สัญญาณ (Vertical divider)
      canvas.drawLine(
        Offset(labelWidth, yOffset),
        Offset(labelWidth, yOffset + channelHeight),
        Paint()
          ..color = AppColors.inkFaint
          ..strokeWidth = 0.8,
      );

      // ── Channel Label ──
      canvas.save();
      canvas.translate(labelWidth / 2, yCenter);
      canvas.rotate(-math.pi / 2);
      final labelSpan = TextSpan(
        text: name,
        style: TextStyle(
          color: chColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(-labelPainter.width / 2, -labelPainter.height / 2));
      canvas.restore();

      // ── Electrode position sub-label ──
      final posMap = {
        'TP9': 'L-Temporal',
        'AF7': 'L-Frontal',
        'AF8': 'R-Frontal',
        'TP10': 'R-Temporal',
      };
      final posSpan = TextSpan(
        text: posMap[name] ?? '',
        style: TextStyle(
          color: AppColors.inkFaint,
          fontSize: 7,
          fontStyle: FontStyle.italic,
        ),
      );
      final posPainter = TextPainter(
        text: posSpan,
        textDirection: TextDirection.ltr,
      );
      posPainter.layout();
      posPainter.paint(
        canvas,
        Offset(
          (labelWidth - posPainter.width) / 2,
          yCenter + 9,
        ),
      );

      // ── Plot data ──
      final data = channels[name] ?? [];
      if (data.isEmpty) {
        final noDataSpan = TextSpan(
          text: 'Waiting for signal…',
          style: TextStyle(
            color: AppColors.inkFaint,
            fontSize: 9,
            fontStyle: FontStyle.italic,
          ),
        );
        final noDataPainter = TextPainter(
          text: noDataSpan,
          textDirection: TextDirection.ltr,
        );
        noDataPainter.layout();
        noDataPainter.paint(
          canvas,
          Offset(
            labelWidth + (plotWidth - noDataPainter.width) / 2,
            yCenter - noDataPainter.height / 2,
          ),
        );
        continue;
      }

      // การขจัดแนวโน้มเส้นกราฟเอียง (Detrend: ลบค่าเฉลี่ยออก)
      double sum = 0;
      for (final val in data) {
        sum += val;
      }
      final mean = sum / data.length;

      // ปรับขนาดความกว้างสเกลอัตโนมัติ (Auto-scale: หาค่าเบี่ยงเบนสัมบูรณ์สูงสุด)
      double maxDev = 5.0;
      for (final val in data) {
        final dev = (val - mean).abs();
        if (dev > maxDev) maxDev = dev;
      }
      maxDev *= 1.15;

      // วาดรูปเส้นคลื่นคลื่นสมอง (Draw waveform)
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = chColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final double xStep = plotWidth / (data.length <= 1 ? 1 : data.length - 1);

      for (int k = 0; k < data.length; k++) {
        final double x = labelWidth + k * xStep;
        final double normalizedVal = (data[k] - mean) / maxDev;
        final double y = yCenter - (normalizedVal * (channelHeight / 2) * 0.82);

        if (k == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);

      // ── แถบสเกลบอกแรงดันไฟฟ้าในหน่วยไมโครโวลต์ด้านขวา (µV scale indicator) ──
      final scaleBarHeight = channelHeight * 0.3;
      final scaleX = size.width - 5;
      final scaleTop = yCenter - scaleBarHeight / 2;
      final scaleBottom = yCenter + scaleBarHeight / 2;
      final scalePaint = Paint()
        ..color = AppColors.inkFaint
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(scaleX, scaleTop), Offset(scaleX, scaleBottom), scalePaint);
      canvas.drawLine(Offset(scaleX - 2, scaleTop), Offset(scaleX + 2, scaleTop), scalePaint);
      canvas.drawLine(Offset(scaleX - 2, scaleBottom), Offset(scaleX + 2, scaleBottom), scalePaint);
    }

    // วาดเส้นขอบด้านบนสุด (Top border)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      Paint()
        ..color = AppColors.inkFaint
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant EegResearchTracePainter oldDelegate) => true;
}

// ── หัวตารางและช่องค่าสถิติของแต่ละช่องสัญญาณ (Stat table cells) ──
class EegStatHeader extends StatelessWidget {
  final String text;
  const EegStatHeader(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class EegStatCell extends StatelessWidget {
  final double? value;
  const EegStatCell(this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        value != null ? value!.toStringAsFixed(2) : '—',
        style: const TextStyle(
          fontSize: 9,
          fontFamily: 'Courier',
          color: AppColors.ink,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
