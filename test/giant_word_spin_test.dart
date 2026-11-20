import 'package:brain_wave_flutter/widgets/brainwave_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ตัวอักษร "Brain" หมุนพร้อมเบลอเป็นช่วง ๆ และในโหมดลดการเคลื่อนไหวจะไม่หมุน
void main() {
  Future<void> pumpWord(WidgetTester tester, {required bool reduceMotion}) async {
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const MaterialApp(home: Center(child: GiantWord(text: 'Brain', fontSize: 120))),
    ));
  }

  Finder spinning() => find.descendant(of: find.byType(GiantWord), matching: find.byType(Transform));
  Finder blurred() => find.descendant(of: find.byType(GiantWord), matching: find.byType(ImageFiltered));

  testWidgets('letters spin with motion blur, then rest sharp until the next cycle', (tester) async {
    await pumpWord(tester, reduceMotion: false);

    await tester.pump(const Duration(milliseconds: 600)); // first letters mid-spin
    expect(spinning(), findsWidgets);
    expect(blurred(), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2400)); // 3 s: all letters at rest
    expect(spinning(), findsNothing);
    expect(blurred(), findsNothing);

    await tester.pump(const Duration(milliseconds: 4600)); // 7.6 s: next cycle
    expect(spinning(), findsWidgets);

    await tester.pumpWidget(const SizedBox()); // stop the repeating animation
  });

  testWidgets('reduced motion: no spin, only a one-time blur to sharp', (tester) async {
    await pumpWord(tester, reduceMotion: true);

    await tester.pump(const Duration(milliseconds: 100));
    expect(spinning(), findsNothing);
    expect(blurred(), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(spinning(), findsNothing);
    expect(blurred(), findsNothing);
  });
}
