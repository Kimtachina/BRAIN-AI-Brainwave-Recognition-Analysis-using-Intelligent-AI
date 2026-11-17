import 'package:brain_wave_flutter/screens/home/widgets/pulse_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// จุดกะพริบต้องมีขนาดคงที่ตลอดแอนิเมชัน
/// ถ้าขนาดเปลี่ยน ป้ายสถานะบนหน้าหลักจะยืดหดและดันป้ายข้าง ๆ ให้กระตุก
void main() {
  testWidgets('PulseDot: ขนาดไม่เปลี่ยนระหว่างกะพริบ', (tester) async {
    final dotKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseDot(key: dotKey, color: Colors.green, size: 6),
              const Text('ระบบพร้อมทำงาน'),
            ],
          ),
        ),
      ),
    );

    final first = tester.getSize(find.byKey(dotKey));
    final textX = tester.getTopLeft(find.text('ระบบพร้อมทำงาน')).dx;

    for (final ms in [300, 600, 900, 1200, 1500]) {
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(find.byKey(dotKey)), first, reason: 'at ${ms}ms');
      expect(tester.getTopLeft(find.text('ระบบพร้อมทำงาน')).dx, textX, reason: 'at ${ms}ms');
    }
  });
}
