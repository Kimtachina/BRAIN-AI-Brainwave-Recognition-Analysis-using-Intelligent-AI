import 'package:brain_wave_flutter/widgets/smooth_scroll.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SmoothScrollController controller;

  Future<void> pumpList(WidgetTester tester, {bool reduce = false}) async {
    controller = SmoothScrollController(reduceMotion: () => reduce);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        controller: controller,
        child: const SizedBox(height: 5000, width: 400),
      ),
    ));
  }

  Future<void> wheel(WidgetTester tester, double dy) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(const Offset(200, 300));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  }

  testWidgets('a wheel notch glides to the target instead of jumping', (tester) async {
    await pumpList(tester);
    await wheel(tester, 100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(100)); // still on the way, not jumped

    await tester.pumpAndSettle();
    expect(controller.offset, 100);
  });

  testWidgets('notches in a row add up from the running target', (tester) async {
    await pumpList(tester);
    await wheel(tester, 100);
    await tester.pump(const Duration(milliseconds: 50));
    await wheel(tester, 100);
    await tester.pumpAndSettle();

    expect(controller.offset, 200);
  });

  testWidgets('small trackpad deltas scroll directly', (tester) async {
    await pumpList(tester);
    await wheel(tester, 12);
    await tester.pump();
    expect(controller.offset, 12);
  });

  testWidgets('reduced motion scrolls directly', (tester) async {
    await pumpList(tester, reduce: true);
    await wheel(tester, 100);
    await tester.pump();
    expect(controller.offset, 100);
  });
}
