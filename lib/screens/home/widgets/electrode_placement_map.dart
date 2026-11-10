import 'dart:math' as math;

import 'package:flutter/material.dart';

class ElectrodePlacementMap extends StatelessWidget {
  final bool isConnected;

  const ElectrodePlacementMap({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 85),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1.0),
      ),
      child: Row(
        children: [
          // ภาพวาดจำลองศีรษะคนเชิงเวกเตอร์ (Stylized Head Vector Paint)
          SizedBox(
            width: 65,
            height: 65,
            child: CustomPaint(
              painter: _HeadPlacementPainter(isConnected: isConnected),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'การสัมผัสของขั้วอิเล็กโทรด (Electrode Contact Quality)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildContactStatusNode('TP9', isConnected),
                    const SizedBox(width: 8),
                    _buildContactStatusNode('AF7', isConnected),
                    const SizedBox(width: 8),
                    _buildContactStatusNode('AF8', isConnected),
                    const SizedBox(width: 8),
                    _buildContactStatusNode('TP10', isConnected),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  isConnected 
                      ? 'ความต้านทานสัมผัสต่ำ < 10 kΩ (สัญญาณสมบูรณ์)' 
                      : 'รอการเชื่อมต่อเซนเซอร์ตรวจจับประจุไฟฟ้า',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: isConnected ? AppColors.primaryGreen : AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStatusNode(String label, bool active) {
    final color = active ? AppColors.primaryGreen : Colors.grey[400]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: active ? [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ] : null,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? AppColors.textDark : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _HeadPlacementPainter extends CustomPainter {
  final bool isConnected;

  _HeadPlacementPainter({required this.isConnected});

  @override
  void paint(Canvas canvas, Size size) {
    final headPaint = Paint()
      ..color = Colors.grey[400]!.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final headCenter = Offset(size.width / 2, size.height / 2 + 1);
    
    // วาดรูปวงรีศีรษะ (Head Oval)
    canvas.drawOval(
      Rect.fromCenter(center: headCenter, width: 34, height: 42),
      headPaint,
    );

    // วาดรูปจมูกอย่างง่ายชี้ขึ้นด้านบน (Draw simple nose pointing up)
    final nosePath = Path()
      ..moveTo(headCenter.dx, headCenter.dy - 21)
      ..lineTo(headCenter.dx - 4, headCenter.dy - 25)
      ..lineTo(headCenter.dx + 4, headCenter.dy - 25)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = Colors.grey[400]!..style = PaintingStyle.fill);

    // วาดใบหูซ้ายขวา (Ears)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(headCenter.dx - 17, headCenter.dy), width: 6, height: 12),
      math.pi / 2,
      math.pi,
      false,
      headPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(headCenter.dx + 17, headCenter.dy), width: 6, height: 12),
      -math.pi / 2,
      math.pi,
      false,
      headPaint,
    );

    // วาดเส้นแนวเชื่อมต่อสัญญาณประสาท (Connecting signal routes)
    final routePaint = Paint()
      ..color = isConnected ? AppColors.primaryGreen.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(headCenter.dx - 15, headCenter.dy), Offset(headCenter.dx - 9, headCenter.dy - 15), routePaint);
    canvas.drawLine(Offset(headCenter.dx - 9, headCenter.dy - 15), Offset(headCenter.dx + 9, headCenter.dy - 15), routePaint);
    canvas.drawLine(Offset(headCenter.dx + 9, headCenter.dy - 15), Offset(headCenter.dx + 15, headCenter.dy), routePaint);

    // วาดจุดอิเล็กโทรดบนศีรษะ (Draw electrodes node values)
    void drawNode(Offset pos, bool good) {
      final nodeColor = good ? AppColors.primaryGreen : Colors.grey[500]!;
      
      // เส้นวงกลมเรืองแสงวงนอก (Outer glow boundary)
      final borderPaint = Paint()
        ..color = nodeColor.withValues(alpha: 0.35)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 4.5, borderPaint);

      // แกนวงกลมทึบด้านใน (Solid inner core)
      final fillPaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2.5, fillPaint);
    }

    // จุดรับสัญญาณตำแหน่ง TP9 (หูด้านซ้าย)
    drawNode(Offset(headCenter.dx - 15, headCenter.dy), isConnected);
    // จุดรับสัญญาณตำแหน่ง AF7 (หน้าผากด้านซ้าย)
    drawNode(Offset(headCenter.dx - 9, headCenter.dy - 15), isConnected);
    // จุดรับสัญญาณตำแหน่ง AF8 (หน้าผากด้านขวา)
    drawNode(Offset(headCenter.dx + 9, headCenter.dy - 15), isConnected);
    // จุดรับสัญญาณตำแหน่ง TP10 (หูด้านขวา)
    drawNode(Offset(headCenter.dx + 15, headCenter.dy), isConnected);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
