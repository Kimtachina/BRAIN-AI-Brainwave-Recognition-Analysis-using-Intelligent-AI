import 'package:flutter/material.dart';

/// คลาสวาดตารางลายเส้นกริดพื้นหลังแบบจาง (Grid Background Painter)
/// เพื่อใช้ตกแต่งหน้าบัตร Eeg Session Card ให้ดูสวยงามพรีเมียม สไตล์เครื่องมือทางการแพทย์ระดับสูง
class GridPatternPainter extends CustomPainter {
  final Color color;
  GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 15.0;
    // ลากเส้นตามแนวตั้ง
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // ลากเส้นตามแนวนอน
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
