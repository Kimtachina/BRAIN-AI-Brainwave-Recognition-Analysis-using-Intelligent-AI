import 'package:flutter/material.dart';

/// ยกการ์ดขึ้นเล็กน้อยและเปลี่ยนเคอร์เซอร์เป็นรูปมือเมื่อเมาส์ชี้ (ใช้บนเว็บ/เดสก์ท็อป)
/// บนจอสัมผัสไม่มีผลใด ๆ
class HoverLift extends StatefulWidget {
  final Widget child;

  const HoverLift({super.key, required this.child});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: Offset(0, _hovered ? -0.025 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _hovered ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
