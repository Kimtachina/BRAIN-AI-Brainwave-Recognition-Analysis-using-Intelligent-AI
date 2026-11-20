import 'package:brain_wave_flutter/screens/auth/app_preview_section.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// แกลเลอรีมือถือหน้าแรก: ลอยขึ้นมาเมื่อเลื่อนถึง และเครื่องที่เมาส์ชี้อยู่เด่นกว่าเครื่องอื่น
void main() {
  late ScrollController scroll;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          child: const Column(
            children: [
              SizedBox(height: 1600), // ฉากหลักด้านบน
              AppPreviewSection(gutter: 32, wide: true),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  /// ความทึบของมือถือแต่ละเครื่อง เรียงตามลำดับบนจอ
  List<double> opacities(WidgetTester tester) => tester
      .widgetList<Opacity>(find.descendant(of: find.byType(AppPreviewSection), matching: find.byType(Opacity)))
      .map((o) => o.opacity)
      .toList();

  testWidgets('phones stay hidden until the section scrolls into view, then rise in', (tester) async {
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(opacities(tester), everyElement(0.0));

    scroll.jumpTo(1300);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final early = opacities(tester);
    expect(early.first, greaterThan(0)); // first phone already rising
    expect(early.last, lessThan(early.first)); // later phones follow one by one

    await tester.pump(const Duration(seconds: 2));
    expect(opacities(tester), everyElement(closeTo(1.0, 0.001)));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pointing at a phone keeps it bright and dims the others', (tester) async {
    await pumpPage(tester);
    scroll.jumpTo(1300);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(Image).at(1)));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final o = opacities(tester);
    expect(o[1], closeTo(1.0, 0.01));
    expect(o[0], lessThan(0.7));
    expect(o[2], lessThan(0.7));

    await tester.pumpWidget(const SizedBox());
  });
}
