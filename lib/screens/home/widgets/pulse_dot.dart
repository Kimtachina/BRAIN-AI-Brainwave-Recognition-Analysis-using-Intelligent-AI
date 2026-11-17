import 'package:flutter/material.dart';

/// จุดวงกลมกะพริบแสดงสถานะการทำงาน (Pulsing status dot)
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulseDot({super.key, required this.color, required this.size});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // จองพื้นที่เท่าวงแหวนตอนขยายสุด (2.5 เท่า) ไว้ตลอด
    // ไม่อย่างนั้นขนาดวิดเจ็ตจะเปลี่ยนทุกเฟรม แล้วดันข้อความ/ป้ายข้าง ๆ ให้เลื่อนไปมา (กระตุก)
    final box = widget.size * 2.5;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * (1.0 + _controller.value * 1.5),
                height: widget.size * (1.0 + _controller.value * 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(
                      alpha: (1.0 - _controller.value) * 0.6,
                    ),
                    width: 1.2,
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
