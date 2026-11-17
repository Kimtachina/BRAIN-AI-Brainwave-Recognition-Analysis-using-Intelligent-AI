import 'package:brain_wave_flutter/models/user.dart';
import 'package:brain_wave_flutter/screens/profile/settings_screen.dart';
import 'package:brain_wave_flutter/screens/search/app_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ทดสอบการค้นหาทั้งแอปและช่องค้นหาในหน้าตั้งค่า (ไม่เรียก Supabase จริง)
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final user = User(id: 7, username: 'tester', fullName: 'ผู้ทดสอบ', email: 'tester@example.test');

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
  }

  group('AppSearchScreen', () {
    testWidgets('ยังไม่พิมพ์: แสดงทางลัด', (tester) async {
      await pump(tester, AppSearchScreen(user: user, onSelectTab: (_) {}));
      expect(find.text('ทางลัด'), findsOneWidget);
      expect(find.text('แบบประเมิน PHQ-9'), findsOneWidget);
    });

    testWidgets('พิมพ์คำค้นเพิ่มเติม: เจอรายการที่ชื่อไม่ตรงคำ', (tester) async {
      await pump(tester, AppSearchScreen(user: user, onSelectTab: (_) {}));
      await tester.enterText(find.byType(TextField), 'password');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('เปลี่ยนรหัสผ่าน', findRichText: true), findsOneWidget);
      expect(find.text('ทางลัด'), findsNothing);
    });

    testWidgets('ไม่พบ: แสดงคำแนะนำ ไม่ปล่อยหน้าว่าง', (tester) async {
      await pump(tester, AppSearchScreen(user: user, onSelectTab: (_) {}));
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ไม่พบ "zzzz"'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'รายงาน'), findsOneWidget);
    });

    testWidgets('เลือกเมนูหลัก: ปิดหน้าค้นหาแล้วสลับแท็บ', (tester) async {
      int? selected;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppSearchScreen(user: user, onSelectTab: (i) => selected = i)),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'แบบประเมิน PHQ-9'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.byType(AppSearchScreen), findsNothing);
    });
  });

  group('SettingsScreen', () {
    testWidgets('มีกลุ่มหลักครบ และค้นหาแล้วกรองรายการ', (tester) async {
      await pump(tester, SettingsScreen(user: user));
      await tester.pump();
      expect(find.text('บัญชีและความปลอดภัย'), findsOneWidget);
      expect(find.textContaining('EEG-'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'privacy');
      await tester.pump();
      expect(find.text('นโยบายความเป็นส่วนตัว'), findsOneWidget);
      expect(find.text('เปลี่ยนรหัสผ่าน'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'zzzz');
      await tester.pump();
      expect(find.text('ไม่พบการตั้งค่า "zzzz"'), findsOneWidget);
    });
  });
}
