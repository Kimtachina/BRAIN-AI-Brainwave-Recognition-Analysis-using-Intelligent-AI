import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseService จัดการข้อมูลแบ็คเอนด์ (Backend) และคลาวด์ดาต้าเบสทั้งหมดของแอปพลิเคชัน
/// ทำหน้าที่เชื่อมต่อ จัดเก็บ ดึงข้อมูลผู้ใช้งาน สถิติคลื่นสมอง รายงานประเมินสุขภาพจิต
/// ประวัติแชท AI ตารางกำหนดการ และระบบแจ้งเตือนผู้ติดต่อฉุกเฉิน
class SupabaseService {
  // ไคลเอนต์หลักสำหรับเชื่อมโยงฐานข้อมูล Supabase
  static SupabaseClient? _client;

  // URL และ Anon Key ของโครงการ Supabase ส่งเข้ามาตอน build ด้วย
  // --dart-define-from-file=env/supabase.json (ดู env/supabase.example.json และ README)
  // ไม่เก็บ key ไว้ในซอร์สโค้ด
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// เริ่มต้นการตั้งค่าและเตรียมเชื่อมต่อกับฐานข้อมูล Supabase (เรียกที่ main.dart ตอนเปิดแอป)
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'ไม่พบ SUPABASE_URL / SUPABASE_ANON_KEY: '
        'รันหรือ build ด้วย --dart-define-from-file=env/supabase.json',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;

  }

  /// ดึงอ้างอิงของไคลเอนต์ Supabase เพื่อเริ่มดึงข้อมูล (จะแจ้งเตือนข้อผิดพลาดหากยังไม่ได้รับการตั้งค่า)
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return {
        'success': true,
        'profile': response,
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถโหลดโปรไฟล์ได้'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? fullName,
    String? phone,
    String? email,
    String? birthDate,
    String? avatarUrl,
    String? role,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (email != null) updateData['email'] = email;
      if (birthDate != null) updateData['birth_date'] = birthDate;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (role != null) updateData['role'] = role;

      await client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      return {'success': true, 'message': 'อัปเดตโปรไฟล์สำเร็จ'};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถอัปเดตโปรไฟล์ได้'};
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar({
    required int userId,
    required XFile imageFile,
  }) async {
    try {

      // ใช้ name แทน path เพราะบนเว็บ path เป็น blob URL ที่ไม่มีนามสกุลไฟล์
      final fileExt = imageFile.name.contains('.')
          ? imageFile.name.split('.').last.toLowerCase()
          : 'jpg';
      final fileName = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profiles/$fileName';

      const mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
      };
      final contentType = mimeTypes[fileExt] ?? 'image/jpeg';

      final fileBytes = await imageFile.readAsBytes();

      await client.storage.from('avatars').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from('avatars').getPublicUrl(filePath);

      await client
          .from('users')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      debugPrint('Avatar uploaded successfully: $publicUrl');

      return {
        'success': true,
        'message': 'อัปโหลดรูปโปรไฟล์สำเร็จ',
        'avatar_url': publicUrl,
      };
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return {'success': false, 'message': 'ไม่สามารถอัปโหลดรูปได้: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    String? currentPassword,
    required String newPassword,
  }) async {
    // รหัสผ่านอยู่ใน Supabase Auth (เก็บแบบ hash) ไม่ได้อยู่ในตาราง users
    final email = client.auth.currentUser?.email;
    if (email == null) {
      return {'success': false, 'message': 'กรุณาเข้าสู่ระบบใหม่ก่อนเปลี่ยนรหัสผ่าน'};
    }

    if (currentPassword == null || currentPassword.isEmpty) {
      return {'success': false, 'message': 'กรุณากรอกรหัสผ่านปัจจุบัน'};
    }

    try {
      await client.auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException {
      return {'success': false, 'message': 'รหัสผ่านปัจจุบันไม่ถูกต้อง'};
    }

    try {
      // ส่งรหัสผ่านปัจจุบันไปด้วย: โปรเจกต์ Supabase เปิดให้ต้องยืนยันรหัสเดิมทุกครั้งที่เปลี่ยนรหัสผ่าน
      await client.auth.updateUser(UserAttributes(password: newPassword, currentPassword: currentPassword));
      return {'success': true, 'message': 'เปลี่ยนรหัสผ่านสำเร็จ'};
    } on AuthException catch (e) {
      return {'success': false, 'message': _passwordChangeError(e)};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถเปลี่ยนรหัสผ่านได้'};
    }
  }

  /// แปลงข้อผิดพลาดจาก Supabase Auth ตอนเปลี่ยนรหัสผ่านเป็นข้อความภาษาไทยที่บอกว่าต้องแก้อะไร
  static String _passwordChangeError(AuthException e) {
    switch (e.code) {
      case 'current_password_mismatch':
        return 'รหัสผ่านปัจจุบันไม่ถูกต้อง';
      case 'current_password_required':
        return 'กรุณากรอกรหัสผ่านปัจจุบัน';
      case 'same_password':
        return 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม';
      case 'weak_password':
        return 'รหัสผ่านใหม่ยังไม่ปลอดภัยพอ ลองใช้รหัสที่ยาวขึ้นและผสมตัวเลขกับตัวอักษร';
      case 'reauthentication_needed':
        return 'กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่ ก่อนเปลี่ยนรหัสผ่าน';
      default:
        return 'ไม่สามารถเปลี่ยนรหัสผ่านได้: ${e.message}';
    }
  }

  static Future<Map<String, dynamic>> saveTestResult({
    required int userId,
    required int stressScore,
    required int depressionScore,
    required String stressLevel,
  }) async {
    try {
      final response = await client
          .from('test_results')
          .insert({
            'user_id': userId,
            'stress_score': stressScore,
            'depression_score': depressionScore,
            'stress_level': stressLevel,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'บันทึกผลทดสอบสำเร็จ',
        'id': response['id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถบันทึกผลทดสอบได้'};
    }
  }

  static Future<Map<String, dynamic>> getTestResults(int userId) async {
    try {
      final response = await client
          .from('test_results')
          .select()
          .eq('user_id', userId)
          .order('test_date', ascending: false);

      return {
        'success': true,
        'results': response,
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถโหลดผลทดสอบได้'};
    }
  }

  static Future<Map<String, dynamic>> saveActivity({
    required int userId,
    required String activityType,
    required String activityName,
    required int score,
    required int durationMinutes,
  }) async {
    try {
      final response = await client
          .from('activities')
          .insert({
            'user_id': userId,
            'activity_type': activityType,
            'activity_name': activityName,
            'score': score,
            'duration_minutes': durationMinutes,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'บันทึกกิจกรรมสำเร็จ',
        'id': response['id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถบันทึกกิจกรรมได้'};
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required int userId,
    required String message,
    bool isBot = false,
  }) async {
    try {
      final response = await client
          .from('chat_messages')
          .insert({
            'user_id': userId,
            'message': message,
            'is_bot': isBot,
          })
          .select()
          .single();

      return {
        'success': true,
        'message_id': response['id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถส่งข้อความได้'};
    }
  }

  static Future<void> saveRetrievalLogs({
    required int messageId,
    required List<Map<String, dynamic>> searchResults,
    required String queryText,
  }) async {
    try {
      final List<Map<String, dynamic>> logs = [];
      for (int i = 0; i < searchResults.length; i++) {
        final res = searchResults[i];
        logs.add({
          'message_id': messageId,
          'knowledge_id': res['id'],
          'query_text': queryText,
          'similarity_score': res['similarity'] ?? 1.0,
          'rank_order': i + 1,
          'was_used': true,
        });
      }
      if (logs.isNotEmpty) {
        await client.from('retrieval_logs').insert(logs);
        debugPrint('Saved ${logs.length} retrieval logs for message $messageId');
      }
    } catch (e) {
      debugPrint('Error saving retrieval logs: $e');
    }
  }

  static Future<Map<String, dynamic>> getChatHistory(int userId) async {
    try {
      final response = await client
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: true);

      return {
        'success': true,
        'messages': response,
      };
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถโหลดประวัติแชทได้'};
    }
  }

  static Future<Map<String, dynamic>> getSettings(int userId) async {
    try {
      final response = await client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {

        final newSettings = await client
            .from('user_settings')
            .insert({'user_id': userId})
            .select()
            .single();

        return {'success': true, 'settings': newSettings};
      }

      return {'success': true, 'settings': response};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถโหลดการตั้งค่าได้'};
    }
  }

  static Future<Map<String, dynamic>> updateSettings({
    required int userId,
    bool? dailyReminder,
    bool? weeklyReport,
    bool? stressAlert,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (dailyReminder != null) updateData['daily_reminder'] = dailyReminder;
      if (weeklyReport != null) updateData['weekly_report'] = weeklyReport;
      if (stressAlert != null) updateData['stress_alert'] = stressAlert;
      if (updateData.isEmpty) return {'success': true};

      await client
          .from('user_settings')
          .update(updateData)
          .eq('user_id', userId);

      return {'success': true, 'message': 'อัปเดตการตั้งค่าสำเร็จ'};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถอัปเดตการตั้งค่าได้'};
    }
  }

  /// ลบข้อมูลบัญชีในฐานข้อมูล ตารางลูกทุกตาราง (การตั้งค่า ผลประเมิน รายงานคลื่นสมอง แชต กิจกรรม)
  /// ผูก ON DELETE CASCADE กับ users อยู่แล้ว จึงลบแถว users แถวเดียวพอ
  static Future<Map<String, dynamic>> deleteAccount(int userId) async {
    try {
      await client.from('users').delete().eq('id', userId);

      return {'success': true, 'message': 'ลบบัญชีสำเร็จ'};
    } catch (e) {
      return {'success': false, 'message': 'ไม่สามารถลบบัญชีได้: $e'};
    }
  }

  static Future<Map<String, dynamic>> saveEegAssessmentReport({
    required int userId,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final eegIndex = (reportData['eegIndex'] as num?)?.toDouble() ?? 0.0;
      final riskLevel = reportData['riskLevel'] as String? ?? 'ไม่มีข้อมูล';
      final riskLevelEn = reportData['riskLevelEn'] as String? ?? 'No Data';
      final durationSeconds = (reportData['durationSeconds'] as num?)?.toInt() ?? 90;
      final samplesCollected = (reportData['samplesCollected'] as num?)?.toInt() ?? 0;

      // ล้างข้อมูลที่ไม่สามารถแปลงเป็นซีเรียลไลซ์ได้ เช่น วัตถุประเภท Color หรือข้อมูลเชิงภาพ
      final cleanReportData = Map<String, dynamic>.from(reportData);
      cleanReportData.remove('riskColor');

      final response = await client
          .from('eeg_assessment_reports')
          .insert({
            'user_id': userId,
            'eeg_index': eegIndex,
            'risk_level': riskLevel,
            'risk_level_en': riskLevelEn,
            'samples_collected': samplesCollected,
            'duration_seconds': durationSeconds,
            'report_data': cleanReportData,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'บันทึกใบสรุปสำเร็จ',
        'report': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'ไม่สามารถบันทึกใบสรุปได้: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getEegAssessmentReports(
    int userId, {
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('eeg_assessment_reports')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      final reports = (response as List).map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'eeg_index': row['eeg_index'],
          'risk_level': row['risk_level'],
          'risk_level_en': row['risk_level_en'],
          'samples_collected': row['samples_collected'],
          'duration_seconds': row['duration_seconds'],
          'recorded_at': row['recorded_at'],
          'report_data': row['report_data'],
        };
      }).toList();

      return {'success': true, 'reports': reports};
    } catch (e) {
      return {
        'success': false,
        'message': 'ไม่สามารถโหลดประวัติใบสรุปได้: $e',
      };
    }
  }
}
