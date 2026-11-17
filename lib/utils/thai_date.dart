/// ตัวช่วยแสดงวันที่แบบไทย (พ.ศ.)
class ThaiDate {
  ThaiDate._();

  static const months = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// เช่น 12 ม.ค. 2540
  static String short(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year + 543}';

  /// เช่น ม.ค. 2568
  static String monthYear(DateTime d) => '${months[d.month - 1]} ${d.year + 543}';

  /// แปลงข้อความวันที่จากฐานข้อมูล ถ้าอ่านไม่ได้คืนข้อความเดิม
  static String? fromText(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null ? text : short(parsed);
  }
}

/// ข้อมูลแอปที่แสดงในหน้าตั้งค่าและหน้าบัญชี (ตรงกับ version ใน pubspec.yaml)
class AppInfo {
  AppInfo._();

  static const name = 'Smart Brain';
  static const version = '1.1.0';
}
