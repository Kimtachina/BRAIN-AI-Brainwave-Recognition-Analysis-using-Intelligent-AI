import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ภาพเคลื่อนไหวกลางจอ HUD: วงคลื่นแผ่ออกจากแกนกลางและเส้นคลื่นสมองไหลผ่าน
/// เมื่อ [isActive] เป็นจริง (เชื่อมต่ออุปกรณ์แล้ว) คลื่นจะแรงและสว่างขึ้น
class NeuralCore extends StatefulWidget {
  final Color color;
  final bool isActive;

  const NeuralCore({super.key, required this.color, this.isActive = false});

  @override
  State<NeuralCore> createState() => _NeuralCoreState();
}

class _NeuralCoreState extends State<NeuralCore> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _NeuralCorePainter(
              color: widget.color,
              progress: _controller.value,
              isActive: widget.isActive,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.10),
              border: Border.all(color: widget.color.withValues(alpha: 0.45), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.psychology_rounded, color: widget.color, size: 42),
          ),
        ),
      ),
    );
  }
}

class _NeuralCorePainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isActive;

  _NeuralCorePainter({required this.color, required this.progress, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height * 1.6) * 0.5;

    // แสงเรืองรอบแกนกลาง
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius)),
    );

    // วงคลื่น 3 วงแผ่ออกจากแกนกลาง
    for (int i = 0; i < 3; i++) {
      final t = (progress * 2 + i / 3) % 1.0;
      final radius = 38 + (maxRadius - 38) * t;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: (1 - t) * 0.35),
      );
    }

    // เส้นคลื่นสมองไหลผ่านจอ 3 เส้น (เว้นช่องตรงกลางไว้ให้ไอคอน)
    final amplitude = isActive ? 16.0 : 8.0;
    final phase = progress * 2 * math.pi;
    for (int line = 0; line < 3; line++) {
      final path = Path();
      final speed = line + 1;
      final freq = 2.0 + line * 1.5;
      for (double x = 0; x <= size.width; x += 3) {
        final nx = x / size.width;
        // ลดความสูงคลื่นที่ขอบซ้ายขวาและตรงกลาง
        final envelope = math.sin(nx * math.pi) * (0.25 + 0.75 * (2 * nx - 1).abs());
        final y = center.dy +
            math.sin(nx * freq * 2 * math.pi + phase * speed) * amplitude * envelope +
            math.sin(nx * freq * 5 * math.pi - phase * speed) * amplitude * 0.25 * envelope;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = line == 0 ? 1.6 : 1.0
          ..color = color.withValues(alpha: (isActive ? 0.55 : 0.30) - line * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralCorePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isActive != isActive || oldDelegate.color != color;
}
