import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/password_validator.dart';
import 'login_screen.dart';

part 'register_sections/form_fields.dart';
part 'register_sections/password_strength.dart';
part 'register_sections/terms_and_privacy.dart';

/// RegisterScreen เป็นหน้าจอกรอกข้อมูลสมัครสมาชิกใหม่สำหรับแอปพลิเคชัน
/// รองรับ:
///   1. สมัครด้วย Email + Password (ผ่าน Supabase Auth) พร้อม Password Strength Indicator
///   2. สมัครด้วย Google Sign-In
/// ประกอบด้วย Bottom Sheet กฎเงื่อนไขการใช้บริการ (Terms) และนโยบายความเป็นส่วนตัว (Privacy Policy)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // คอนโทรลเลอร์ควบคุมช่องกรอกข้อมูลฟอร์มลงทะเบียน
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _obscurePassword = true;        // เปิด/ปิด การซ่อนรหัสผ่านในกล่องข้อความ
  bool _obscureConfirmPassword = true;  // เปิด/ปิด การซ่อนช่องยืนยันรหัสผ่าน
  bool _isLoading = false;             // บอกสถานะการโหลดระหว่างส่งข้อมูล API
  bool _isGoogleLoading = false;       // บอกสถานะการโหลด Google Sign-In
  bool _agreeToTerms = false;          // เช็คว่ายอมรับข้อตกลงการใช้งานหรือยัง
  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  // ผลลัพธ์การตรวจสอบรหัสผ่าน — อัปเดตเมื่อผู้ใช้พิมพ์
  PasswordResult? _passwordResult;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showTermsAndPrivacyBottomSheet(context, initialTab: 0);
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showTermsAndPrivacyBottomSheet(context, initialTab: 1);
      };

    // ติดตามการพิมพ์รหัสผ่านเพื่ออัปเดตแถบความแข็งแรงแบบเรียลไทม์
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  /// เรียกเมื่อรหัสผ่านเปลี่ยน เพื่ออัปเดตแถบความแข็งแรงแบบเรียลไทม์
  void _onPasswordChanged() {
    setState(() {
      _passwordResult = PasswordValidator.evaluate(_passwordController.text);
    });
  }

  /// เปิด Date Picker เลือกวันเกิด
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1970),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// สมัครสมาชิกด้วย Email + Password ผ่าน Supabase Auth
  Future<void> _register() async {
    if (!_agreeToTerms) {
      _showError('กรุณายอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัวก่อนสมัครสมาชิก');
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    // ตรวจสอบรูปแบบอีเมล
    if (!PasswordValidator.isValidEmail(_emailController.text.trim())) {
      _showError('กรุณากรอกอีเมลให้ถูกต้อง เช่น example@gmail.com');
      return;
    }

    // ตรวจสอบความแข็งแรงของรหัสผ่าน
    if (!PasswordValidator.isAcceptable(_passwordController.text)) {
      _showError('รหัสผ่านไม่ผ่านเกณฑ์ความปลอดภัย กรุณาตรวจสอบเงื่อนไขรหัสผ่าน');
      return;
    }

    // ตรวจสอบรหัสผ่านยืนยัน
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('รหัสผ่านและรหัสผ่านยืนยันไม่ตรงกัน');
      return;
    }

    // ตรวจสอบเบอร์โทรศัพท์ (ถ้ากรอก)
    if (_phoneController.text.isNotEmpty) {
      if (_phoneController.text.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text)) {
        _showError('เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลักเท่านั้น');
        return;
      }
    }

    setState(() => _isLoading = true);

    // แปลงวันเกิดเป็นรูปแบบ YYYY-MM-DD
    String? birthDate;
    if (_birthDateController.text.isNotEmpty) {
      final parts = _birthDateController.text.split('/');
      if (parts.length == 3) {
        birthDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    final result = await AuthService.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      birthDate: birthDate,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบเพื่อใช้งาน', style: GoogleFonts.prompt()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      _showError(result['message'] ?? 'เกิดข้อผิดพลาด');
    }
  }

  /// สมัครด้วย Google Sign-In
  Future<void> _registerWithGoogle() async {
    if (!_agreeToTerms) {
      _showError('กรุณายอมรับเงื่อนไขการใช้งานก่อนสมัครด้วย Google');
      return;
    }

    setState(() => _isGoogleLoading = true);

    final result = await AuthService.signInWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกด้วย Google สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      if (result['message'] != 'ยกเลิกการเข้าสู่ระบบด้วย Google') {
        _showError(result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    }
  }

  /// แสดง Snackbar แจ้งข้อผิดพลาด
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// ให้โค้ด UI ในไฟล์ part เรียกรีเฟรชหน้าจอได้
  /// (extension เรียก setState ตรง ๆ ไม่ได้ เพราะเป็นเมธอดแบบ protected)
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.glassBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'สร้างบัญชีใหม่',
            style: GoogleFonts.prompt(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SizedBox(
          height: double.infinity,
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // อีเมล
              _buildLabel('อีเมล'),
              _buildTextField(
                controller: _emailController,
                hintText: 'ระบุอีเมลของคุณ เช่น example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),

              const SizedBox(height: 16),

              // รหัสผ่าน
              _buildLabel('รหัสผ่าน'),
              _buildTextField(
                controller: _passwordController,
                hintText: 'ตั้งรหัสผ่านอย่างน้อย 8 ตัวอักษร',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textGray,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              // แถบความแข็งแรงของรหัสผ่าน
              if (_passwordController.text.isNotEmpty && _passwordResult != null)
                _buildPasswordStrengthIndicator(),

              const SizedBox(height: 16),

              // ยืนยันรหัสผ่าน
              _buildLabel('ยืนยันรหัสผ่าน'),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textGray,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ชื่อ-นามสกุล
              _buildLabel('ชื่อ-นามสกุล'),
              _buildTextField(
                controller: _fullNameController,
                hintText: 'ระบุชื่อและนามสกุลจริง',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),

              const SizedBox(height: 16),

              // เบอร์โทรศัพท์
              _buildLabel('เบอร์โทรศัพท์'),
              _buildTextField(
                controller: _phoneController,
                hintText: 'ระบุเบอร์โทรศัพท์ 10 หลัก',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),

              const SizedBox(height: 16),

              // วันเกิด
              _buildLabel('วัน/เดือน/ปีเกิด'),
              _buildTextField(
                controller: _birthDateController,
                hintText: 'เลือกวัน/เดือน/ปีเกิดของคุณ',
                readOnly: true,
                onTap: _selectDate,
                prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),

              const SizedBox(height: 16),

              // ข้อตกลงการใช้งาน
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.textLight, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textGray,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'ฉันยอมรับ '),
                          TextSpan(
                            text: 'เงื่อนไขการใช้งาน',
                            style: GoogleFonts.prompt(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _termsRecognizer,
                          ),
                          const TextSpan(text: ' และ '),
                          TextSpan(
                            text: 'นโยบายความเป็นส่วนตัว',
                            style: GoogleFonts.prompt(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _privacyRecognizer,
                          ),
                          const TextSpan(text: ' ของแอปพลิเคชัน'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'สมัครบัญชีใช้งาน',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // เส้นคั่น "หรือ"
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'หรือ',
                      style: GoogleFonts.prompt(color: AppColors.textGray, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.5))),
                ],
              ),

              const SizedBox(height: 20),

              // ปุ่มสมัครด้วย Google
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _registerWithGoogle,
                  icon: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 22,
                          width: 22,
                          errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata_rounded, size: 28),
                        ),
                  label: Text(
                    'สมัครด้วย Google',
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ลิงก์ไปหน้าเข้าสู่ระบบ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'มีบัญชีอยู่แล้วใช่ไหม? ',
                    style: GoogleFonts.prompt(color: AppColors.textGray, fontSize: 13.5),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: GoogleFonts.prompt(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // ═══════════════════════════════════════════
  //  Widget ย่อย — Password Strength Indicator
  // ═══════════════════════════════════════════

  // ═══════════════════════════════════════════
  //  Widget ย่อย — Build Helper
  // ═══════════════════════════════════════════

  // ═══════════════════════════════════════════
  //  Bottom Sheet — เงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว
  // ═══════════════════════════════════════════
}
