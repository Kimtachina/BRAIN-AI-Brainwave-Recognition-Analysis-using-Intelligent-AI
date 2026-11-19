import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brain_wave_flutter/services/eeg/eeg_assessment_service.dart';
import 'package:brain_wave_flutter/widgets/eeg/eeg_topographic_map.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))));

void main() {
  group('EegAssessmentService.channelAverages', () {
    test('averages each sensor separately and renormalises to 100%', () {
      final samples = [
        {'alpha': 30.0, 'AF7.delta': 20.0, 'AF7.theta': 20.0, 'AF7.alpha': 20.0, 'AF7.beta': 30.0, 'AF7.gamma': 10.0},
        {'alpha': 30.0, 'AF7.delta': 20.0, 'AF7.theta': 20.0, 'AF7.alpha': 40.0, 'AF7.beta': 10.0, 'AF7.gamma': 10.0},
      ];
      final channels = EegAssessmentService.channelAverages(samples);

      expect(channels.keys, ['AF7']); // sensors with no data are left out, not invented
      expect(channels['AF7']!['alpha'], closeTo(30, 0.001));
      expect(channels['AF7']!.values.reduce((a, b) => a + b), closeTo(100, 0.001));
    });

    test('summary from a recording keeps per-sensor data that survives a JSON round trip', () {
      final summary = EegAssessmentService.computeFromSamples([
        {'alpha': 30, 'beta': 20, 'theta': 20, 'delta': 20, 'gamma': 10, 'TP9.alpha': 50, 'TP9.beta': 50},
      ]);
      // report_data comes back from Supabase as plain JSON maps with num values
      final fromDb = {'channels': {'TP9': {'alpha': 50, 'beta': 50, 'theta': 0, 'delta': 0, 'gamma': 0}}};

      expect(EegAssessmentService.channelsFrom(summary)!['TP9']!['alpha'], closeTo(50, 0.001));
      expect(EegAssessmentService.channelsFrom(fromDb)!['TP9']!['alpha'], 50.0);
      expect(EegAssessmentService.channelsFrom({'avgAlpha': 1.0}), isNull);
    });
  });

  group('EegTopographicMap', () {
    testWidgets('labels each measured sensor with its own value', (tester) async {
      await tester.pumpWidget(_host(const EegTopographicMap(
        title: 'Alpha',
        subtitle: 'ผ่อนคลาย',
        values: {'AF7': 22, 'AF8': 18, 'TP9': 35, 'TP10': 31},
        average: 26,
      )));

      final label = tester.getSemantics(find.byType(CustomPaint).last).label;
      expect(label, contains('AF7 22'));
      expect(label, contains('TP10 31'));
      expect(find.textContaining('ไม่มีค่าแยกจุด'), findsNothing);
    });

    testWidgets('says so when a report has no per-sensor data', (tester) async {
      await tester.pumpWidget(_host(const EegTopographicMap(
        title: 'Alpha',
        subtitle: 'ผ่อนคลาย',
        values: null,
        average: 26,
      )));

      expect(find.text('ค่าเฉลี่ยทุกจุด 26% (รายงานนี้ไม่มีค่าแยกจุด)'), findsOneWidget);
    });
  });
}
