import 'package:image_picker/image_picker.dart' show XFile;
import 'supabase_service.dart';
import 'ai/chatgpt_service.dart';
import 'auth_service.dart';

/// ApiService เป็น Facade Class สำหรับรวบรวมฟังก์ชันการเรียกใช้งาน API ทั้งหมดในจุดเดียว
/// ทำหน้าที่เป็นทางผ่านเชื่อมโยงไปยัง SupabaseService, ChatGPTService, และ AuthService
/// ช่วยให้ส่วนควบคุมการทำงานด้าน UI เรียกใช้การจัดการข้อมูลหลังบ้านและโมเดลปัญญาประดิษฐ์ได้สะดวกยิ่งขึ้น
class ApiService {
  // ═══════════════════════════════════════════
  //  Authentication — ระบบยืนยันตัวตน
  // ═══════════════════════════════════════════

  /// ออกจากระบบ
  static Future<void> signOut() async {
    return AuthService.signOut();
  }

  // ═══════════════════════════════════════════
  //  Legacy Login — ล็อกอินแบบเดิม (username/password)
  // ═══════════════════════════════════════════

  /// ดึงข้อมูลโปรไฟล์ของผู้ใช้งานด้วยรหัสไอดีผู้ใช้
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    return SupabaseService.getProfile(userId);
  }

  /// อัปเดตข้อมูลรายละเอียดโปรไฟล์ของผู้ใช้
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? fullName,
    String? phone,
    String? email,
    String? birthDate,
  }) async {
    return SupabaseService.updateProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
      email: email,
      birthDate: birthDate,
    );
  }

  /// อัปโหลดรูปภาพโปรไฟล์ (Avatar) ไปยัง Supabase Storage
  static Future<Map<String, dynamic>> uploadAvatar({
    required int userId,
    required XFile imageFile,
  }) async {
    return SupabaseService.uploadAvatar(
      userId: userId,
      imageFile: imageFile,
    );
  }

  /// เปลี่ยนรหัสผ่านของผู้ใช้งาน
  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    String? currentPassword,
    required String newPassword,
  }) async {
    return SupabaseService.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// บันทึกผลลัพธ์การทำแบบทดสอบคัดกรองสุขภาพจิต (PHQ-9)
  static Future<Map<String, dynamic>> saveTestResult({
    required int userId,
    required int stressScore,
    required int depressionScore,
    required String stressLevel,
  }) async {
    return SupabaseService.saveTestResult(
      userId: userId,
      stressScore: stressScore,
      depressionScore: depressionScore,
      stressLevel: stressLevel,
    );
  }

  /// ดึงข้อมูลประวัติการทำแบบทดสอบทั้งหมดของผู้ใช้
  static Future<Map<String, dynamic>> getTestResults(int userId) async {
    return SupabaseService.getTestResults(userId);
  }

  /// บันทึกประวัติการทำกิจกรรมหรือเล่นเกม
  static Future<Map<String, dynamic>> saveActivity({
    required int userId,
    required String activityType,
    required String activityName,
    required int score,
    required int durationMinutes,
  }) async {
    return SupabaseService.saveActivity(
      userId: userId,
      activityType: activityType,
      activityName: activityName,
      score: score,
      durationMinutes: durationMinutes,
    );
  }

  /// ดึงข้อมูลประวัติการสนทนาทั้งหมดของผู้ใช้
  static Future<Map<String, dynamic>> getChatHistory(int userId) async {
    return SupabaseService.getChatHistory(userId);
  }

  /// ส่งข้อความหาบอทปัญญาประดิษฐ์ (ChatGPT) พร้อมดึง RAG Context และบันทึกคำตอบอัตโนมัติ
  static Future<Map<String, dynamic>> sendChatGPTMessage({
    required int userId,
    required String message,
    List<Map<String, dynamic>>? chatHistory,
  }) async {

    final userMessageResult = await SupabaseService.sendChatMessage(
      userId: userId,
      message: message,
      isBot: false,
    );

    final int? userMessageId = userMessageResult['success'] == true
        ? userMessageResult['message_id'] as int?
        : null;

    ChatGPTService.setUserId(userId);

    final result = await ChatGPTService.sendMessageWithRAG(
      message: message,
      chatHistory: chatHistory,
      userId: userId,
      userMessageId: userMessageId,
    );

    if (result['success'] == true && result['bot_response'] != null) {

      await SupabaseService.sendChatMessage(
        userId: userId,
        message: result['bot_response'],
        isBot: true,
      );
    }

    return result;
  }

  /// ดึงการตั้งค่าแอปพลิเคชันของผู้ใช้
  static Future<Map<String, dynamic>> getSettings(int userId) async {
    return SupabaseService.getSettings(userId);
  }

  /// ปรับปรุงบันทึกการตั้งค่าภายในแอป
  static Future<Map<String, dynamic>> updateSettings({
    required int userId,
    required bool pushNotifications,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    return SupabaseService.updateSettings(
      userId: userId,
      dailyReminder: pushNotifications,
      stressAlert: vibrationEnabled,
    );
  }

  /// บันทึกสรุปรายงานผลวิเคราะห์ qEEG
  static Future<Map<String, dynamic>> saveEegAssessmentReport({
    required int userId,
    required Map<String, dynamic> reportData,
  }) async {
    return SupabaseService.saveEegAssessmentReport(
      userId: userId,
      reportData: reportData,
    );
  }

  /// ดึงรายการประวัติรายงานสรุป qEEG ทั้งหมด
  static Future<Map<String, dynamic>> getEegAssessmentReports(
    int userId, {
    int limit = 50,
  }) async {
    return SupabaseService.getEegAssessmentReports(userId, limit: limit);
  }
}
