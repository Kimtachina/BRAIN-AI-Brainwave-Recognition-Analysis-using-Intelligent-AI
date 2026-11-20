import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ฉากท้องฟ้าของหน้าด้านในแอป: ฟ้าไล่สีจากเข้มลงมาสว่าง แสงแดดอ่อน ๆ มุมขวาบน และกลุ่มเมฆจาง ๆ
/// เมฆวาดจางมากและอยู่ชิดขอบ ไม่ให้แย่งสายตาหรือทำให้ตัวหนังสือขาวอ่านยาก
class SkyBackdrop extends StatelessWidget {
  const SkyBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter())),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  /// กลุ่มเมฆ: ตำแหน่งกึ่งกลาง (สัดส่วนของจอ), ขนาด (สัดส่วนของด้านยาว), ความทึบ
  static const _clouds = [
    (Offset(0.88, 0.10), 0.20, 0.16),
    (Offset(0.08, 0.30), 0.16, 0.10),
    (Offset(0.95, 0.55), 0.18, 0.09),
    (Offset(0.12, 0.86), 0.22, 0.12),
    (Offset(0.70, 0.96), 0.20, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = AppGradients.glassBackgroundGradient.createShader(rect));

    final longSide = size.longestSide;

    // แสงแดดอุ่น ๆ มุมขวาบน
    final sun = Offset(size.width * 0.92, size.height * 0.02);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE7A8).withValues(alpha: 0.22),
            const Color(0xFFFFE7A8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: longSide * 0.45)),
    );

    for (final (center, scale, opacity) in _clouds) {
      _drawCloud(
        canvas,
        Offset(center.dx * size.width, center.dy * size.height),
        longSide * scale,
        opacity,
      );
    }
  }

  /// เมฆหนึ่งก้อน: วงกลมนุ่ม ๆ หลายวงซ้อนกันเป็นทรงพุ่ม ฐานแบน
  void _drawCloud(Canvas canvas, Offset c, double w, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12);
    final puffs = [
      (const Offset(-0.32, 0.06), 0.24),
      (const Offset(-0.08, -0.10), 0.32),
      (const Offset(0.22, -0.02), 0.27),
      (const Offset(0.42, 0.10), 0.18),
      (const Offset(0.02, 0.14), 0.26),
    ];
    final path = Path();
    for (final (o, r) in puffs) {
      path.addOval(Rect.fromCircle(center: c + o * w, radius: r * w));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}
