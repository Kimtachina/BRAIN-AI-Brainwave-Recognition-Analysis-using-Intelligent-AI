import 'package:flutter/material.dart';

class CyberFramePainter extends CustomPainter {
  final Color color;
  final bool isConnected;

  CyberFramePainter({required this.color, required this.isConnected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double bracketSize = 18.0;

    // วาดสัญลักษณ์มุมกรอบ (Draw corner brackets)
    // บนซ้าย (Top-Left)
    canvas.drawPath(Path()..moveTo(bracketSize, 2)..lineTo(2, 2)..lineTo(2, bracketSize), paint);
    // บนขวา (Top-Right)
    canvas.drawPath(Path()..moveTo(size.width - bracketSize, 2)..lineTo(size.width - 2, 2)..lineTo(size.width - 2, bracketSize), paint);
    // ล่างซ้าย (Bottom-Left)
    canvas.drawPath(Path()..moveTo(bracketSize, size.height - 2)..lineTo(2, size.height - 2)..lineTo(2, size.height - bracketSize), paint);
    // ล่างขวา (Bottom-Right)
    canvas.drawPath(Path()..moveTo(size.width - bracketSize, size.height - 2)..lineTo(size.width - 2, size.height - 2)..lineTo(size.width - 2, size.height - bracketSize), paint);

    // เส้นโครงขอบด้านในจางๆ (Subtle inner boundary frame)
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), borderPaint);

    // เป้าเล็งวงกลมกึ่งกลางสไตล์กล้องสแกนคลินิก (Center Target Reticle)
    final center = Offset(size.width / 2, size.height / 2);
    final reticlePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 30, reticlePaint);
    canvas.drawCircle(center, 4, Paint()..color = color.withValues(alpha: 0.4)..style = PaintingStyle.fill);

    // วาดขีดไม้กางเขนเล็งเป้า (Draw reticle crosshair ticks)
    canvas.drawLine(Offset(center.dx - 45, center.dy), Offset(center.dx - 35, center.dy), reticlePaint);
    canvas.drawLine(Offset(center.dx + 35, center.dy), Offset(center.dx + 45, center.dy), reticlePaint);
    canvas.drawLine(Offset(center.dx, center.dy - 45), Offset(center.dx, center.dy - 35), reticlePaint);
    canvas.drawLine(Offset(center.dx, center.dy + 35), Offset(center.dx, center.dy + 45), reticlePaint);

    // ขีดสเกลด้านข้างสำหรับวัดระดับ (Side ticks - Rulers on left & right sides)
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    for (double i = 0.25; i <= 0.75; i += 0.125) {
      final y = size.height * i;
      canvas.drawLine(Offset(12, y), Offset(18, y), tickPaint);
      canvas.drawLine(Offset(size.width - 12, y), Offset(size.width - 18, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
