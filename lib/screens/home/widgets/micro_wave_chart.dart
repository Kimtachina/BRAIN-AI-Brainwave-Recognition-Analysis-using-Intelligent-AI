import 'dart:math' as math;

import 'package:flutter/material.dart';

class MicroWaveChart extends StatefulWidget {
  final Color color;
  final double frequency;
  final bool isActive;

  const MicroWaveChart({
    super.key,
    required this.color,
    required this.frequency,
    required this.isActive,
  });

  @override
  State<MicroWaveChart> createState() => _MicroWaveChartState();
}

class _MicroWaveChartState extends State<MicroWaveChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 18),
          painter: _WaveLinePainter(
            color: widget.color,
            phase: _controller.value * 2 * math.pi,
            frequency: widget.frequency,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  final Color color;
  final double phase;
  final double frequency;
  final bool isActive;

  _WaveLinePainter({
    required this.color,
    required this.phase,
    required this.frequency,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? color : Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    final width = size.width;

    path.moveTo(0, midY);
    for (double x = 0; x <= width; x += 1.5) {
      final double amp = isActive 
          ? (frequency < 2.0 ? 7.0 : (frequency > 8.0 ? 3.0 : 5.0)) 
          : 1.0;
      final double y = midY + amp * math.sin((x / width * 2 * math.pi * frequency) - phase);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveLinePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.isActive != isActive;
  }
}
