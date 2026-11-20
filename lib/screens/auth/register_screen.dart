import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/password_validator.dart';
import 'login_screen.dart';
import '../../widgets/app_page.dart';
import '../../widgets/brainwave_scene.dart';
import '../../widgets/policy_content.dart';

part 'register_sections/form_fields.dart';
part 'register_sections/password_strength.dart';
part 'register_sections/terms_and_privacy.dart';

/// RegisterScreen เป็นหน้าจอกรอกข้อมูลสมัครสมาชิกใหม่สำหรับแอปพลิเคชัน
/// สมัครด้วย Email + Password (ผ่าน Supabase Auth) พร้อม Password Strength Indicator
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
  bool _obscurePassword = true; // เปิด/ปิด การซ่อนรหัสผ่านในกล่องข้อความ
  bool _obscureConfirmPassword = true; // เปิด/ปิด การซ่อนช่องยืนยันรหัสผ่าน
  bool _isLoading = false; // บอกสถานะการโหลดระหว่างส่งข้อมูล API
  bool _agreeToTerms = false; // เช็คว่ายอมรับข้อตกลงการใช้งานหรือยัง
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
            colorScheme: const ColorScheme.dark(
              primary: AppColors.alphaWave,
              onPrimary: AppColors.night,
              surface: AppColors.nightSurface,
              onSurface: AppColors.ink,
            ),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.alphaWave)),
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
      _showError('กรุณากรอกอีเมลให้ถูกต้อง เช่น name@example.com');
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
            content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบเพื่อใช้งาน', style: GoogleFonts.ibmPlexSansThai()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      _showError(result['message'] ?? 'เกิดข้อผิดพลาด');
    }
  }

  /// แสดง Snackbar แจ้งข้อผิดพลาด
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  /// ให้โค้ด UI ในไฟล์ part เรียกรีเฟรชหน้าจอได้
  /// (extension เรียก setState ตรง ๆ ไม่ได้ เพราะเป็นเมธอดแบบ protected)
  void _refresh(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'ย้อนกลับ',
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สร้างบัญชีใหม่', style: AppTextStyles.title.copyWith(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text('ใช้เวลาไม่ถึงนาที ข้อมูลส่วนตัวใช้ในรายงานผลของคุณเท่านั้น', style: AppTextStyles.body),

                  const SectionLabel('บัญชี'),
                  _buildLabel('อีเมล'),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('รหัสผ่าน'),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'อย่างน้อย 8 ตัวอักษร',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  // แถบความแข็งแรงของรหัสผ่าน
                  if (_passwordController.text.isNotEmpty && _passwordResult != null) _buildPasswordStrengthIndicator(),
                  const SizedBox(height: 16),
                  _buildLabel('ยืนยันรหัสผ่าน'),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'พิมพ์รหัสผ่านอีกครั้ง',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),

                  const SectionLabel('ข้อมูลส่วนตัว'),
                  _buildLabel('ชื่อ-นามสกุล'),
                  _buildTextField(controller: _fullNameController, hintText: 'ชื่อและนามสกุลจริง'),
                  const SizedBox(height: 16),
                  // จอกว้าง: เบอร์โทรกับวันเกิดอยู่แถวเดียวกัน
                  LayoutBuilder(
                    builder: (context, c) {
                      final phone = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('เบอร์โทรศัพท์'),
                          _buildTextField(
                            controller: _phoneController,
                            hintText: '10 หลัก',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                          ),
                        ],
                      );
                      final birth = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('วันเกิด'),
                          _buildTextField(
                            controller: _birthDateController,
                            hintText: 'เลือกวันที่',
                            readOnly: true,
                            onTap: _selectDate,
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                        ],
                      );
                      if (c.maxWidth < 380) {
                        return Column(children: [phone, const SizedBox(height: 16), birth]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: phone),
                          const SizedBox(width: 12),
                          Expanded(child: birth),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  // ข้อตกลงการใช้งาน: กดได้ทั้งแถว ลิงก์ในข้อความเปิดเนื้อหาเต็ม
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.small,
                                children: [
                                  const TextSpan(text: 'ฉันยอมรับ'),
                                  TextSpan(
                                    text: 'เงื่อนไขการใช้งาน',
                                    style: const TextStyle(color: AppColors.alphaWave, fontWeight: FontWeight.w600),
                                    recognizer: _termsRecognizer,
                                  ),
                                  const TextSpan(text: 'และ'),
                                  TextSpan(
                                    text: 'นโยบายความเป็นส่วนตัว',
                                    style: const TextStyle(color: AppColors.alphaWave, fontWeight: FontWeight.w600),
                                    recognizer: _privacyRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: AppColors.night, strokeWidth: 2.2),
                            )
                          : const Text('สร้างบัญชี'),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('มีบัญชีอยู่แล้ว', style: AppTextStyles.small),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                    ],
                  ),
                ],
              ),
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
