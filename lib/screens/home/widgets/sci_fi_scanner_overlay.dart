import 'package:flutter/material.dart';

class SciFiScannerOverlay extends StatefulWidget {
  final Color color;

  const SciFiScannerOverlay({super.key, required this.color});

  @override
  State<SciFiScannerOverlay> createState() => _SciFiScannerOverlayState();
}

class _SciFiScannerOverlayState extends State<SciFiScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
        final position = _controller.value;
        return CustomPaint(
          painter: _ScannerLinePainter(
            color: widget.color,
            progress: position,
          ),
        );
      },
    );
  }
}

class _ScannerLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  _ScannerLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * progress;

    // เส้นเลเซอร์เรืองแสงที่วิ่งสแกน (Glowing laser scan line)
    final paintLine = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 1.0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, y - 10, size.width, y + 10))
      ..strokeWidth = 2.5;

    // ลำแสงเลเซอร์เรืองแสงฟุ้งที่ลากเป็นเงาตามหลังมา (Glowing laser trail trailing behind)
    final paintTrail = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTRB(0, y - 40, size.width, y))
      ..style = PaintingStyle.fill;
    
    if (y > 40) {
      canvas.drawRect(Rect.fromLTRB(8, y - 40, size.width - 8, y), paintTrail);
    }

    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paintLine);

    final paintGrid = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const int numRows = 8;
    const int numCols = 12;

    for (int i = 1; i < numRows; i++) {
      final double gridY = size.height * (i / numRows);
      canvas.drawLine(Offset(8, gridY), Offset(size.width - 8, gridY), paintGrid);
    }
    for (int i = 1; i < numCols; i++) {
      final double gridX = size.width * (i / numCols);
      canvas.drawLine(Offset(gridX, 8), Offset(gridX, size.height - 8), paintGrid);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
