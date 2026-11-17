
/// User คือโมเดลแทนผู้ใช้งานระบบหลัก (บัญชีผู้ใช้งาน)
/// เก็บข้อมูลโปรไฟล์ขั้นพื้นฐาน เช่น ชื่อล็อกอิน อีเมล ชื่อนามสกุล บทบาทหน้าที่ (Role) และวันลงทะเบียน
class User {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final String? phone;
  final bool isActive;
  final String? birthDate;
  final String role;
  final DateTime? createdAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.phone,
    this.isActive = true,
    this.birthDate,
    this.role = 'user',
    this.createdAt,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      birthDate: json['birth_date']?.toString(),
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'is_active': isActive,
      'birth_date': birthDate,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return username;
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    bool? isActive,
    String? birthDate,
    String? role,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
