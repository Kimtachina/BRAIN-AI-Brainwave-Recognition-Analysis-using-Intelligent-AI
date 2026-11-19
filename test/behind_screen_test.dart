import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_wave_flutter/screens/behind/behind_screen.dart';

void main() {
  testWidgets('shows the preprocessing pipeline and a connect prompt when Muse is off', (tester) async {
    var connectTapped = false;
    await tester.pumpWidget(MaterialApp(
      home: BehindScreen(active: true, onConnect: () => connectTapped = true),
    ));

    expect(find.text('เบื้องหลัง'), findsOneWidget);
    expect(find.textContaining('EEG Preprocessing Pipeline'), findsOneWidget);

    await tester.tap(find.text('ไปเชื่อมต่อ'));
    expect(connectTapped, isTrue);
  });
}
