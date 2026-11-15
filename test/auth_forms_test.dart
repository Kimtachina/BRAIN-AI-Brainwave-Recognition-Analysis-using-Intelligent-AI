import 'package:brain_wave_flutter/screens/auth/login_screen.dart';
import 'package:brain_wave_flutter/screens/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ทดสอบการตรวจข้อมูลในฟอร์มล็อกอินและฟอร์มตั้งรหัสผ่านใหม่
/// ครอบคลุมเฉพาะส่วนที่ทำงานในเครื่อง ไม่เรียก Supabase
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
  }

  Finder field(int index) => find.byType(TextFormField).at(index);

  group('LoginScreen', () {
    testWidgets('ช่องว่าง: แจ้งใต้ช่องทั้งสองช่องเมื่อกดเข้าสู่ระบบ', (tester) async {
      await pump(tester, const LoginScreen());
      expect(find.text('กรุณากรอกอีเมล'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'));
      await tester.pump();

      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('อีเมลผิดรูปแบบ: แจ้งใต้ช่อง และหายเมื่อแก้ให้ถูก', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.enterText(field(0), 'not-an-email');
      await tester.enterText(field(1), 'secret');
      await tester.tap(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'));
      await tester.pump();

      expect(find.textContaining('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);

      await tester.enterText(field(0), 'name@example.com');
      await tester.pump();
      expect(find.textContaining('รูปแบบอีเมลไม่ถูกต้อง'), findsNothing);
    });

    testWidgets('ยังไม่กดส่ง: ไม่เตือนระหว่างพิมพ์', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.enterText(field(0), 'abc');
      await tester.pump();
      expect(find.textContaining('รูปแบบอีเมลไม่ถูกต้อง'), findsNothing);
    });

    testWidgets('จดจำอีเมล: เติมอีเมลที่บันทึกไว้', (tester) async {
      SharedPreferences.setMockInitialValues({'saved_email': 'me@example.com', 'remember_me': true});
      await pump(tester, const LoginScreen());
      await tester.pump();
      expect(find.text('me@example.com'), findsOneWidget);
    });

    testWidgets('ลืมรหัสผ่าน: ไม่ปิดหน้าต่างถ้าอีเมลผิดรูปแบบ', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.tap(find.text('ลืมรหัสผ่าน?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      await tester.tap(find.text('ส่งลิงก์'));
      await tester.pump();

      expect(find.textContaining('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
      expect(find.text('ส่งลิงก์'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('รหัสผ่านอ่อนหรือไม่ตรงกัน: แจ้งใต้ช่อง', (tester) async {
      await pump(tester, const ResetPasswordScreen());
      await tester.enterText(field(0), 'abc');
      await tester.enterText(field(1), 'abd');
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pump();

      expect(find.text('รหัสผ่านยังไม่ผ่านเกณฑ์ด้านล่าง'), findsOneWidget);
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
    });
  });
}
