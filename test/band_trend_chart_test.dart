import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_wave_flutter/screens/home/widgets/band_trend_chart.dart';
import 'package:brain_wave_flutter/services/muse/muse_service.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(width: 600, child: child)));

void main() {
  testWidgets('shows a waiting message before any Muse data', (tester) async {
    await tester.pumpWidget(_host(const BandTrendChart(history: [])));
    expect(find.text('กราฟจะแสดงเมื่อเริ่มรับสัญญาณจาก Muse'), findsOneWidget);
  });

  testWidgets('draws one line per band as percentages of total power', (tester) async {
    final now = DateTime(2026, 1, 1, 12);
    final history = [
      for (var i = 0; i < 10; i++)
        BrainwaveData(
          delta: 1, theta: 1, alpha: 2, beta: 1, gamma: 0,
          timestamp: now.subtract(Duration(seconds: 10 - i)),
        ),
    ];
    await tester.pumpWidget(_host(BandTrendChart(history: history)));

    expect(find.text('กราฟจะแสดงเมื่อเริ่มรับสัญญาณจาก Muse'), findsNothing);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final bars = chart.data.lineBarsData;
    expect(bars, hasLength(5));
    expect(bars[2].spots.last.y, closeTo(40, 0.001)); // alpha = 2 / 5
    expect(bars[2].spots.last.x, 0);
  });
}
