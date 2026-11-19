import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// แผนที่สมองจากเซนเซอร์ Muse 4 จุดที่วัดได้จริง (TP9, AF7, AF8, TP10)
///
/// แต่ละจุดแสดงค่าที่วัดได้ของตัวเอง สีระหว่างจุดประมาณด้วย Inverse Distance Weighting
/// ถ้ารายงานไม่มีค่าแยกจุด ([values] เป็น null) จะลงสีทั้งหัวด้วยค่าเฉลี่ย [average]
/// และบอกตรง ๆ ว่าไม่มีข้อมูลแยกจุด แทนการแต่งค่าขึ้นมาเอง
class EegTopographicMap extends StatelessWidget {
  final String title;
  final String subtitle;

  /// ค่าแยกตามเซนเซอร์ เช่น {'AF7': 23.5} หน่วยเป็น % ของพลังรวม
  final Map<String, double>? values;

  /// ค่าเฉลี่ยทุกจุด ใช้เมื่อไม่มีค่าแยกจุด
  final double average;

  /// ค่าบนสุดของแถบสี (ค่าที่เกินจะแสดงเป็นสีสุดท้าย) ใช้ค่าเดียวกันทุกแผนที่เพื่อให้เทียบสีกันได้
  final double maxValue;

  const EegTopographicMap({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.average,
    this.maxValue = 50,
  });

  /// ตำแหน่งเซนเซอร์ Muse เทียบกับรัศมีหัว (มองจากด้านบน จมูกอยู่ด้านบน)
  static const sensorPositions = {
    'AF7': Offset(-0.42, -0.62),
    'AF8': Offset(0.42, -0.62),
    'TP9': Offset(-0.82, 0.30),
    'TP10': Offset(0.82, 0.30),
  };

  /// แถบสีไล่ระดับแบบ viridis อ่านง่ายบนพื้นมืด และคนตาบอดสีแยกได้
  static const palette = [
    Color(0xFF3B1E6E),
    Color(0xFF3B528B),
    Color(0xFF21918C),
    Color(0xFF5EC962),
    Color(0xFFFDE725),
  ];

  static Color colorFor(double t) {
    t = t.clamp(0.0, 1.0) * (palette.length - 1);
    final i = t.floor().clamp(0, palette.length - 2);
    return Color.lerp(palette[i], palette[i + 1], t - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final measured = values != null && values!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansThai(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansThai(fontSize: 11.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: Semantics(
            label: _semanticLabel(measured),
            child: CustomPaint(
              painter: _TopoPainter(
                values: measured ? values! : const {},
                average: average,
                maxValue: maxValue,
              ),
            ),
          ),
        ),
        if (measured && values!.length < sensorPositions.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${sensorPositions.keys.where((k) => !values!.containsKey(k)).join(', ')} ไม่มีสัญญาณระหว่างบันทึก',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansThai(fontSize: 11, color: AppColors.inkFaint),
            ),
          ),
        if (!measured)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'ค่าเฉลี่ยทุกจุด ${average.toStringAsFixed(0)}% (รายงานนี้ไม่มีค่าแยกจุด)',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansThai(fontSize: 11, color: AppColors.inkFaint),
            ),
          ),
        const SizedBox(height: 10),
        _legend(),
      ],
    );
  }

  String _semanticLabel(bool measured) {
    if (!measured) return '$title ค่าเฉลี่ยทุกจุด ${average.toStringAsFixed(0)} เปอร์เซ็นต์';
    final parts = [
      for (final ch in sensorPositions.keys)
        if (values!.containsKey(ch)) '$ch ${values![ch]!.toStringAsFixed(0)} เปอร์เซ็นต์',
    ];
    return '$title ${parts.join(', ')}';
  }

  Widget _legend() {
    final style = GoogleFonts.ibmPlexSansThai(fontSize: 11, color: AppColors.inkSoft);
    return Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(colors: palette),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: style),
            Text('${(maxValue / 2).round()}%', style: style),
            Text('${maxValue.round()}%+', style: style),
          ],
        ),
      ],
    );
  }
}

class _TopoPainter extends CustomPainter {
  final Map<String, double> values;
  final double average;
  final double maxValue;

  _TopoPainter({required this.values, required this.average, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final headR = size.width * 0.40;
    final center = Offset(size.width / 2, size.height * 0.53);
    Offset at(Offset rel) => center + rel * headR;

    _drawEarsAndNose(canvas, center, headR);

    // พื้นสีในหัว
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: headR)));
    if (values.isEmpty) {
      canvas.drawCircle(center, headR, Paint()..color = EegTopographicMap.colorFor(average / maxValue).withValues(alpha: 0.55));
    } else {
      final sensors = [
        for (final e in values.entries)
          if (EegTopographicMap.sensorPositions.containsKey(e.key)) (at(EegTopographicMap.sensorPositions[e.key]!), e.value),
      ];
      const cells = 64;
      final step = headR * 2 / cells;
      final paint = Paint();
      for (var y = 0; y < cells; y++) {
        for (var x = 0; x < cells; x++) {
          final p = Offset(center.dx - headR + (x + 0.5) * step, center.dy - headR + (y + 0.5) * step);
          var num = 0.0, den = 0.0;
          for (final (pos, v) in sensors) {
            final d = math.max((p - pos).distance / headR, 0.02);
            final w = 1 / (d * d);
            num += w * v;
            den += w;
          }
          paint.color = EegTopographicMap.colorFor(num / den / maxValue);
          canvas.drawRect(Rect.fromLTWH(p.dx - step / 2, p.dy - step / 2, step + 0.6, step + 0.6), paint);
        }
      }
    }
    canvas.restore();

    // เส้นขอบหัว
    canvas.drawCircle(
      center,
      headR,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.inkSoft
        ..strokeWidth = 2,
    );

    // เซนเซอร์และค่าที่วัดได้
    final dotR = math.max(5.0, headR * 0.07);
    final fontSize = (headR * 0.13).clamp(10.0, 14.0);
    for (final MapEntry(key: name, value: rel) in EegTopographicMap.sensorPositions.entries) {
      final p = at(rel);
      final v = values[name];
      final hasValue = v != null;
      canvas.drawCircle(p, dotR, Paint()..color = hasValue ? Colors.white : AppColors.surface);
      canvas.drawCircle(
        p,
        dotR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = hasValue ? AppColors.night : AppColors.inkFaint,
      );
      // หน้าผาก: ป้ายอยู่ใต้จุด / หลังหู: ป้ายอยู่เหนือจุดและเยื้องเข้าด้านใน ไม่ให้ล้นขอบ
      final align = rel.dx.abs() > 0.6 ? (rel.dx < 0 ? -1.0 : 1.0) : 0.0;
      _drawLabel(
        canvas,
        name,
        hasValue ? '${v.toStringAsFixed(0)}%' : '–',
        Offset(p.dx + align * dotR, p.dy + (rel.dy < 0 ? dotR + 4 : -(dotR + 4))),
        fontSize,
        above: rel.dy >= 0,
        align: align,
      );
    }
  }

  void _drawEarsAndNose(Canvas canvas, Offset center, double headR) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.inkSoft
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final nose = Path()
      ..moveTo(center.dx - headR * 0.12, center.dy - headR * 0.99)
      ..lineTo(center.dx, center.dy - headR * 1.14)
      ..lineTo(center.dx + headR * 0.12, center.dy - headR * 0.99);
    canvas.drawPath(nose, stroke);
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + side * headR, center.dy), width: headR * 0.2, height: headR * 0.4),
        side > 0 ? -math.pi / 2 : math.pi / 2,
        math.pi,
        false,
        stroke,
      );
    }
  }

  /// ป้ายชื่อเซนเซอร์ (บรรทัดบน) กับค่าที่วัดได้ (บรรทัดล่าง) บนพื้นทึบ อ่านออกไม่ว่าสีแผนที่ข้างหลังจะเป็นสีอะไร
  /// [align] -1 = ป้ายยื่นไปทางขวาของจุดยึด, 0 = กึ่งกลาง, 1 = ยื่นไปทางซ้าย
  void _drawLabel(Canvas canvas, String name, String value, Offset anchor, double fontSize,
      {required bool above, required double align}) {
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(
          text: '$name\n',
          style: GoogleFonts.ibmPlexSansThai(fontSize: fontSize * 0.8, fontWeight: FontWeight.w600, color: AppColors.inkSoft, height: 1.1),
        ),
        TextSpan(
          text: value,
          style: GoogleFonts.ibmPlexSansThai(fontSize: fontSize, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.1),
        ),
      ]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = EdgeInsets.symmetric(horizontal: 5, vertical: 2);
    final w = tp.width + pad.horizontal;
    final h = tp.height + pad.vertical;
    final left = anchor.dx - w / 2 - align * w / 2;
    final top = above ? anchor.dy - h : anchor.dy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(6)),
      Paint()..color = AppColors.night.withValues(alpha: 0.82),
    );
    tp.paint(canvas, Offset(left + pad.left, top + pad.top));
  }

  @override
  bool shouldRepaint(covariant _TopoPainter old) =>
      old.average != average || old.maxValue != maxValue || old.values.toString() != values.toString();
}
