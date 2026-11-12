import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../supabase_service.dart';

/// ผลลัพธ์จาก AiProxy: [data] คือ JSON ที่ OpenAI ส่งกลับมา ถ้าสำเร็จ
class AiProxyResult {
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const AiProxyResult(this.statusCode, this.data, this.errorMessage);

  bool get ok => statusCode == 200 && data != null;
}

/// เรียก OpenAI ผ่าน Supabase Edge Function `openai-proxy`
/// แอปไม่ถือ API key เอง จึงใช้ได้ทั้งมือถือและเว็บอย่างปลอดภัย
/// ต้องล็อกอินก่อน เพราะ function ตรวจ access token ของ Supabase Auth
class AiProxy {
  static const String _functionName = 'openai-proxy';

  static Uri get _endpoint =>
      Uri.parse('${SupabaseService.supabaseUrl}/functions/v1/$_functionName');

  static Map<String, String>? _authHeaders() {
    final token = SupabaseService.client.auth.currentSession?.accessToken;
    if (token == null) return null;
    return {
      'Authorization': 'Bearer $token',
      'apikey': SupabaseService.supabaseAnonKey,
    };
  }

  static const _notLoggedIn =
      AiProxyResult(401, null, 'กรุณาเข้าสู่ระบบก่อนใช้งานผู้ช่วย AI');

  static Future<AiProxyResult> chat({
    required List<Map<String, dynamic>> messages,
    int maxTokens = 800,
    double temperature = 0.7,
  }) {
    return _postJson({
      'action': 'chat',
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });
  }

  static Future<AiProxyResult> embedding(String input) {
    return _postJson({'action': 'embedding', 'input': input});
  }

  static Future<AiProxyResult> transcribe(
    Uint8List audioBytes, {
    String filename = 'audio.m4a',
    String language = 'th',
  }) async {
    final headers = _authHeaders();
    if (headers == null) return _notLoggedIn;

    final request = http.MultipartRequest('POST', _endpoint)
      ..headers.addAll(headers)
      ..fields['language'] = language
      ..files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: filename));

    final response = await request.send();
    return _parse(response.statusCode, await response.stream.bytesToString());
  }

  static Future<AiProxyResult> _postJson(Map<String, dynamic> body) async {
    final headers = _authHeaders();
    if (headers == null) return _notLoggedIn;

    final response = await http.post(
      _endpoint,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _parse(response.statusCode, utf8.decode(response.bodyBytes));
  }

  static AiProxyResult _parse(int statusCode, String body) {
    Map<String, dynamic>? data;
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (statusCode == 200) return AiProxyResult(statusCode, data, null);

    final message = (data?['error'] is Map ? data!['error']['message'] : null) ??
        'HTTP $statusCode';
    return AiProxyResult(statusCode, null, message.toString());
  }
}
