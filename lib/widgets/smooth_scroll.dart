import 'package:flutter/material.dart';

/// ScrollController ที่ทำให้ล้อเมาส์เลื่อนนุ่ม (ค่อย ๆ ไหลไปแทนการกระโดดทีละขั้น)
///
/// Flutter บนเว็บเลื่อนตามล้อเมาส์แบบกระโดดทันทีทีละ ~100 px จึงดูกระตุก
/// ตัวนี้เปลี่ยนเฉพาะการเลื่อนด้วยล้อเมาส์ให้เป็นแอนิเมชันสั้น ๆ การลากด้วยนิ้วยังทำงานเหมือนเดิม
/// trackpad ส่งระยะเลื่อนทีละน้อยและถี่อยู่แล้ว จึงปล่อยให้เลื่อนตรง ๆ ไม่หน่วง
class SmoothScrollController extends ScrollController {
  /// ปิดแอนิเมชัน (เช่นผู้ใช้ตั้งเครื่องให้ลดการเคลื่อนไหว) จะเลื่อนแบบปกติ
  bool Function()? reduceMotion;

  SmoothScrollController({this.reduceMotion});

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SmoothScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
      reduceMotion: () => reduceMotion?.call() ?? false,
    );
  }
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    required this.reduceMotion,
  });

  final bool Function() reduceMotion;

  /// จุดหมายของแอนิเมชันที่กำลังเลื่อนอยู่ หมุนล้อซ้ำระหว่างทางจะต่อจากจุดนี้ ไม่ใช่จากตำแหน่งปัจจุบัน
  double? _target;

  static const _duration = Duration(milliseconds: 420);

  /// ระยะต่อครั้งที่น้อยกว่านี้ถือว่ามาจาก trackpad ซึ่งไหลลื่นอยู่แล้ว
  static const _trackpadDelta = 40.0;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return;
    if (reduceMotion() || delta.abs() < _trackpadDelta) {
      _target = null;
      super.pointerScroll(delta);
      return;
    }
    final from = (_target != null && isScrollingNotifier.value)
        ? _target!
        : pixels;
    final to = (from + delta).clamp(minScrollExtent, maxScrollExtent);
    if (to == pixels) return;
    _target = to;
    animateTo(to, duration: _duration, curve: Curves.easeOutCubic);
  }
}
