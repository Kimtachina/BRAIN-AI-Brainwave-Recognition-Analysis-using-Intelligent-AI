import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import 'supabase_service.dart';

/// AuthService จัดการระบบยืนยันตัวตน (Authentication) ทั้งหมดของแอปพลิเคชัน
/// เข้าสู่ระบบด้วย Email + Password ที่ผู้ใช้สมัครเอง (ผ่าน Supabase Auth พร้อม bcrypt hash อัตโนมัติ)
///
/// หลังล็อกอินสำเร็จจะซิงค์ข้อมูลกับตาราง users ในฐานข้อมูล
/// เพื่อให้ userId ใช้งานได้ทั่วทั้งแอป
class AuthService {
  // ═══════════════════════════════════════════
  //  การลงทะเบียนด้วย Email + Password
  // ═══════════════════════════════════════════

  /// สมัครสมาชิกใหม่ด้วย email และ password
  /// Supabase Auth จะ:
  ///   - Hash password ด้วย bcrypt อัตโนมัติ
  ///   - ส่ง email ยืนยันตัวตนไปยังอีเมลที่ระบุ
  ///   - สร้างบัญชีใน auth.users
  ///
  /// หลังจากนั้นจะสร้าง row ในตาราง users เพื่อเชื่อมกับระบบ
  static Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String? birthDate,
  }) async {
    try {
      final client = SupabaseService.client;

      // ขั้นตอนที่ 1: สร้างบัญชีผ่าน Supabase Auth
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        // trigger ฝั่ง Supabase (migration 015) ใช้ข้อมูลนี้สร้างแถวในตาราง users ให้
        data: {
          'full_name': fullName,
          'phone': phone,
          'birth_date': birthDate,
        },
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'ไม่สามารถสร้างบัญชีได้ กรุณาลองใหม่'};
      }

      // ยังไม่มี session (ต้องยืนยันอีเมลก่อน): RLS ไม่ให้แอปเขียนตาราง users ตอนนี้
      // แถวถูกสร้างโดย trigger แล้ว และจะซิงค์อีกครั้งตอนล็อกอินครั้งแรก
      if (authResponse.session == null) {
        return {
          'success': true,
          'message': 'สมัครสมาชิกสำเร็จ กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี',
          'needs_verification': true,
        };
      }

      // ขั้นตอนที่ 2: สร้าง row ในตาราง users เพื่อเชื่อมกับระบบแอป
      final syncResult = await _syncUserToDatabase(
        authUserId: authResponse.user!.id,
        email: email,
        fullName: fullName,
        phone: phone,
        birthDate: birthDate,
        authProvider: 'email',
      );

      if (syncResult['success'] != true) {
        return syncResult;
      }

      return {
        'success': true,
        'message': 'สมัครสมาชิกสำเร็จ กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี',
        'user': syncResult['user'],
        'needs_verification': true,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': _translateAuthError(e.message)};
    } catch (e) {
      debugPrint('❌ SignUp Error: $e');
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการสมัครสมาชิก: $e'};
    }
  }

  // ═══════════════════════════════════════════
  //  การเข้าสู่ระบบด้วย Email + Password
  // ═══════════════════════════════════════════

  /// เข้าสู่ระบบด้วย email และ password
  /// Supabase Auth จะตรวจสอบ email/password กับ bcrypt hash ที่เก็บไว้
  static Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final client = SupabaseService.client;

      // เข้าสู่ระบบผ่าน Supabase Auth
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'ไม่สามารถเข้าสู่ระบบได้'};
      }

      // ดึงข้อมูลจากตาราง users โดยใช้ auth_user_id
      final syncResult = await _getOrCreateUserProfile(authResponse.user!);

      if (syncResult['success'] != true) {
        return syncResult;
      }

      return {
        'success': true,
        'message': 'เข้าสู่ระบบสำเร็จ',
        'user': syncResult['user'],
      };
    } on AuthException catch (e) {
      // code ให้หน้าล็อกอินรู้ว่าควรเสนอปุ่ม "ส่งอีเมลยืนยันอีกครั้ง" หรือไม่
      final notConfirmed = e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('email not confirmed');
      return {
        'success': false,
        'message': _translateAuthError(e.message),
        if (notConfirmed) 'code': 'email_not_confirmed',
      };
    } catch (e) {
      debugPrint('❌ SignIn Error: $e');
      return {'success': false, 'message': 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่'};
    }
  }

  // ═══════════════════════════════════════════
  //  การรีเซ็ตรหัสผ่าน (Forgot Password)
  // ═══════════════════════════════════════════

  /// ส่งอีเมลลิงก์สำหรับรีเซ็ตรหัสผ่าน
  /// ข้อความที่ตอบกลับเหมือนกันไม่ว่าอีเมลนี้จะมีบัญชีหรือไม่ เพื่อไม่ให้ใครใช้ฟอร์มนี้ตรวจว่าอีเมลใดสมัครไว้
  /// (แนวทาง OWASP Authentication / Forgot Password Cheat Sheet)
  static Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    const sentMessage =
        'ถ้าอีเมลนี้มีบัญชีอยู่ เราได้ส่งลิงก์ตั้งรหัสผ่านใหม่ไปให้แล้ว กรุณาตรวจกล่องจดหมายและโฟลเดอร์สแปม';
    try {
      final client = SupabaseService.client;
      await client.auth.resetPasswordForEmail(
        email,
        // เว็บ: ให้ลิงก์ในอีเมลพากลับมาที่เว็บนี้ แล้ว WelcomeScreen จะเปิดหน้าตั้งรหัสผ่านใหม่
        // ต้องมี URL นี้ใน Supabase → Authentication → URL Configuration → Redirect URLs
        redirectTo: kIsWeb ? Uri.base.origin + Uri.base.path : null,
      );
      return {'success': true, 'message': sentMessage};
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') || msg.contains('seconds') || msg.contains('too many')) {
        return {'success': false, 'message': _translateAuthError(e.message)};
      }
      debugPrint('❌ Reset Password Error: ${e.message}');
      return {'success': true, 'message': sentMessage};
    } catch (e) {
      debugPrint('❌ Reset Password Error: $e');
      return {'success': false, 'message': 'ส่งอีเมลไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่'};
    }
  }

  /// ตั้งรหัสผ่านใหม่หลังเปิดลิงก์รีเซ็ตจากอีเมล (ต้องมี session จากลิงก์นั้นอยู่)
  /// สำเร็จแล้วคืนข้อมูลผู้ใช้เพื่อเข้าแอปต่อได้เลย
  static Future<Map<String, dynamic>> setNewPassword(String newPassword) async {
    try {
      final client = SupabaseService.client;
      final response = await client.auth.updateUser(UserAttributes(password: newPassword));
      SupabaseService.passwordRecoveryPending = false;
      final authUser = response.user ?? client.auth.currentUser;
      if (authUser == null) {
        return {'success': false, 'message': 'ลิงก์หมดอายุแล้ว กรุณาขอลิงก์ตั้งรหัสผ่านใหม่อีกครั้ง'};
      }
      return await _getOrCreateUserProfile(authUser);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('different from the old') || e.code == 'same_password') {
        return {'success': false, 'message': 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม'};
      }
      if (msg.contains('session') || msg.contains('expired') || msg.contains('jwt')) {
        return {'success': false, 'message': 'ลิงก์หมดอายุแล้ว กรุณาขอลิงก์ตั้งรหัสผ่านใหม่อีกครั้ง'};
      }
      return {'success': false, 'message': _translateAuthError(e.message)};
    } catch (e) {
      debugPrint('❌ Set New Password Error: $e');
      return {'success': false, 'message': 'ตั้งรหัสผ่านใหม่ไม่สำเร็จ กรุณาลองใหม่'};
    }
  }

  // ═══════════════════════════════════════════
  //  การส่งอีเมลยืนยันซ้ำ
  // ═══════════════════════════════════════════

  /// ส่งอีเมลยืนยันบัญชีอีกครั้ง สำหรับผู้ที่สมัครแล้วแต่ยังไม่ได้กดลิงก์ยืนยัน
  static Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: kIsWeb ? Uri.base.origin + Uri.base.path : null,
      );
      return {'success': true, 'message': 'ส่งอีเมลยืนยันไปที่ $email แล้ว กรุณาตรวจกล่องจดหมายและโฟลเดอร์สแปม'};
    } on AuthException catch (e) {
      return {'success': false, 'message': _translateAuthError(e.message)};
    } catch (e) {
      debugPrint('❌ Resend Verification Error: $e');
      return {'success': false, 'message': 'ส่งอีเมลไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่'};
    }
  }

  // ═══════════════════════════════════════════
  //  การออกจากระบบ
  // ═══════════════════════════════════════════

  /// ออกจากระบบ Supabase Auth
  static Future<void> signOut() async {
    try {
      final client = SupabaseService.client;
      SupabaseService.passwordRecoveryPending = false;
      await client.auth.signOut();
    } catch (e) {
      debugPrint('❌ SignOut Error: $e');
    }
  }

  // ═══════════════════════════════════════════
  //  ตรวจสอบสถานะ Session
  // ═══════════════════════════════════════════

  /// ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่ (มี session ที่ยังใช้ได้)
  static bool get isLoggedIn {
    try {
      final client = SupabaseService.client;
      return client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// ดึงข้อมูล Auth User ปัจจุบัน (จาก Supabase Auth)
  static User? get currentAuthUser {
    try {
      final client = SupabaseService.client;
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// ดึงข้อมูลผู้ใช้จากตาราง users โดยใช้ session ที่มีอยู่
  /// ใช้สำหรับ auto-login เมื่อเปิดแอปซ้ำ
  static Future<Map<String, dynamic>> restoreSession() async {
    try {
      final authUser = currentAuthUser;
      if (authUser == null) {
        return {'success': false, 'message': 'ไม่มี session ที่ใช้ได้'};
      }

      final syncResult = await _getOrCreateUserProfile(authUser);
      return syncResult;
    } catch (e) {
      debugPrint('❌ Restore Session Error: $e');
      return {'success': false, 'message': 'ไม่สามารถกู้คืน session ได้'};
    }
  }

  // ═══════════════════════════════════════════
  //  ฟังก์ชันภายใน — ซิงค์ข้อมูลกับตาราง users
  // ═══════════════════════════════════════════

  /// สร้าง row ใหม่ในตาราง users สำหรับผู้ใช้ที่เพิ่งสมัครสมาชิก
  static Future<Map<String, dynamic>> _syncUserToDatabase({
    required String authUserId,
    required String email,
    String? fullName,
    String? phone,
    String? birthDate,
    String authProvider = 'email',
  }) async {
    try {
      final client = SupabaseService.client;

      // ตรวจสอบว่ามี row ในตาราง users ที่ผูกกับ auth_user_id นี้แล้วหรือไม่
      final existing = await client
          .from('users')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (existing != null) {
        // มี row อยู่แล้ว — ดึงข้อมูลมาใช้เลย
        return {
          'success': true,
          'user': existing,
        };
      }

      // ตรวจซ้ำด้วย email (กรณีผู้ใช้เก่าที่ยังไม่มี auth_user_id)
      final existingByEmail = await client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingByEmail != null) {
        // พบผู้ใช้เดิมด้วย email — อัปเดต auth_user_id
        await client
            .from('users')
            .update({
              'auth_user_id': authUserId,
              'auth_provider': authProvider,
              'email_verified': false,
            })
            .eq('id', existingByEmail['id']);

        final updated = await client
            .from('users')
            .select()
            .eq('id', existingByEmail['id'])
            .single();

        return {
          'success': true,
          'user': updated,
        };
      }

      // สร้าง row ใหม่ในตาราง users
      // ใช้ email เป็น username (ตัดส่วน @domain ออก)
      final username = email.split('@').first;

      final response = await client
          .from('users')
          .insert({
            'username': username,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'birth_date': birthDate,
            'auth_user_id': authUserId,
            'auth_provider': authProvider,
            'email_verified': false,
          })
          .select()
          .single();

      // สร้าง user_settings สำหรับผู้ใช้ใหม่
      await client.from('user_settings').insert({
        'user_id': response['id'],
      });

      return {
        'success': true,
        'user': response,
      };
    } catch (e) {
      debugPrint('❌ Sync User Error: $e');
      return {'success': false, 'message': 'ไม่สามารถบันทึกข้อมูลผู้ใช้ได้: $e'};
    }
  }

  /// ดึงหรือสร้าง profile ในตาราง users สำหรับ Auth User ที่ล็อกอินแล้ว
  static Future<Map<String, dynamic>> _getOrCreateUserProfile(
    User authUser, {
    String authProvider = 'email',
  }) async {
    try {
      final client = SupabaseService.client;

      // ค้นหา user จาก auth_user_id
      var userRow = await client
          .from('users')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      // ถ้าไม่พบ ลองค้นจาก email
      if (userRow == null && authUser.email != null) {
        userRow = await client
            .from('users')
            .select()
            .eq('email', authUser.email!)
            .maybeSingle();

        if (userRow != null) {
          // พบผู้ใช้เดิม — อัปเดต auth_user_id
          await client
              .from('users')
              .update({
                'auth_user_id': authUser.id,
                'auth_provider': authProvider,
                'email_verified': true,
              })
              .eq('id', userRow['id']);

          userRow = await client
              .from('users')
              .select()
              .eq('id', userRow['id'])
              .single();
        }
      }

      // ถ้ายังไม่พบ สร้างใหม่ (เช่น ยืนยันอีเมลแล้วล็อกอินครั้งแรก)
      if (userRow == null) {
        final result = await _syncUserToDatabase(
          authUserId: authUser.id,
          email: authUser.email ?? '',
          fullName: authUser.userMetadata?['full_name'],
          authProvider: authProvider,
        );

        if (result['success'] != true) return result;
        userRow = result['user'];
      }

      // แปลงเป็น app_models.User
      final appUser = app_models.User.fromJson(userRow!);

      return {
        'success': true,
        'user': userRow,
        'app_user': appUser,
      };
    } catch (e) {
      debugPrint('❌ Get/Create User Profile Error: $e');
      return {'success': false, 'message': 'ไม่สามารถดึงข้อมูลผู้ใช้ได้: $e'};
    }
  }

  // ═══════════════════════════════════════════
  //  แปลข้อผิดพลาด Supabase Auth เป็นภาษาไทย
  // ═══════════════════════════════════════════

  /// แปลข้อความ error จาก Supabase Auth ให้เป็นภาษาไทยที่เข้าใจง่าย
  static String _translateAuthError(String errorMessage) {
    final msg = errorMessage.toLowerCase();

    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    if (msg.contains('email not confirmed')) {
      return 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
    }
    if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'อีเมลนี้ถูกใช้สมัครสมาชิกแล้ว';
    }
    if (msg.contains('password')) {
      return 'รหัสผ่านไม่ถูกต้องตามเกณฑ์ กรุณาตั้งรหัสผ่านใหม่';
    }
    if (msg.contains('rate limit') || 
        msg.contains('too many requests') || 
        msg.contains('security purposes') || 
        msg.contains('after 30 seconds') || 
        msg.contains('seconds')) {
      return 'เพื่อความปลอดภัยในการส่งคำขอ กรุณารอสักครู่ (ประมาณ 30 วินาที) แล้วลองใหม่อีกครั้ง';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    }

    return 'เกิดข้อผิดพลาด: $errorMessage';
  }
}
