import 'package:flutter/material.dart'; // สำหรับสร้าง UI ด้วยองค์ประกอบ Material Design
import 'package:flutter/services.dart'; // TextInput.finishAutofillContext ให้เบราว์เซอร์บันทึกรหัสผ่าน
import 'package:shared_preferences/shared_preferences.dart'; // สำหรับบันทึกอีเมลล่าสุดไว้ในเครื่อง (Remember Me)
import '../../theme/app_theme.dart'; // เรียกใช้ชุดสีและดีไซน์หลักของแอป
import '../../services/auth_service.dart'; // เชื่อมต่อระบบล็อกอิน (Supabase Auth)
import '../../models/user.dart'; // รูปแบบโครงสร้างข้อมูลผู้ใช้งาน
import '../main_navigation.dart'; // สำหรับเปลี่ยนหน้าไปยังหน้าหลักหลังเข้าระบบสำเร็จ
import 'register_screen.dart'; // สำหรับเปิดหน้าจอสมัครสมาชิกใหม่เมื่อคลิกสมัคร
import '../../widgets/app_page.dart';
import '../../widgets/brainwave_scene.dart';
import '../../utils/password_validator.dart'; // ตรวจรูปแบบอีเมล

/// LoginScreen เป็นหน้าจอล็อกอินสำหรับการเข้าสู่ระบบผู้ใช้งาน
/// เข้าสู่ระบบด้วย Email + Password (ผ่าน Supabase Auth)
/// มีระบบจดจำ Email ผ่าน SharedPreferences
///
/// แนวทางของฟอร์ม (web.dev Sign-in form best practices, OWASP Authentication Cheat Sheet):
///   - ฟอร์มหน้าเดียว มี autofill hints ให้ตัวจัดการรหัสผ่านกรอกและบันทึกได้
///   - ตรวจข้อมูลใต้ช่องกรอก กด Enter เพื่อส่ง ปุ่มทั้งหมดปิดระหว่างรอ
///   - ล็อกอินไม่ผ่านแจ้งข้อความเดียวกันเสมอ ไม่บอกว่าอีเมลมีบัญชีหรือไม่
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // คอนโทรลเลอร์สำหรับเก็บค่าข้อมูลการกรอกฟอร์มล็อกอิน
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true; // ควบคุมสถานะการซ่อน/แสดงรหัสผ่าน
  bool _isLoading = false; // ใช้แสดงโหลดดิ้งขณะเชื่อมต่อ API
  bool _isResending = false; // กำลังส่งอีเมลยืนยันซ้ำ
  bool _rememberMe = false; // ติ๊กบันทึก email ในเครื่องหรือไม่
  bool _submitted = false; // กดเข้าสู่ระบบแล้วอย่างน้อยหนึ่งครั้ง: หลังจากนี้ตรวจช่องกรอกทันทีที่พิมพ์

  // ข้อความแจ้งผลที่แสดงค้างไว้เหนือฟอร์ม (ไม่ใช้ SnackBar เพราะหายเองและอยู่ไกลจากช่องกรอก)
  String? _bannerMessage;
  bool _bannerIsError = true;
  bool _canResendVerification = false;

  bool get _busy => _isLoading;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// โหลดข้อมูลล็อกอินที่เคยบันทึกไว้จาก SharedPreferences
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && savedEmail != null && mounted) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = rememberMe;
      });
    }
  }

  /// บันทึกหรือลบข้อมูล email ใน SharedPreferences ตามสถานะ Remember Me
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showBanner(String message, {bool isError = true, bool canResend = false}) {
    setState(() {
      _bannerMessage = message;
      _bannerIsError = isError;
      _canResendVerification = canResend;
    });
  }

  /// ผู้ใช้เริ่มแก้ข้อมูลแล้ว ข้อความแจ้งผลครั้งก่อนไม่ตรงกับสิ่งที่กรอกอยู่ จึงซ่อน
  void _clearBanner() {
    if (_bannerMessage != null) {
      setState(() {
        _bannerMessage = null;
        _canResendVerification = false;
      });
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'กรุณากรอกอีเมล';
    if (!PasswordValidator.isValidEmail(email)) return 'รูปแบบอีเมลไม่ถูกต้อง เช่น yourname@gmail.com';
    return null;
  }

  void _goToApp(Map<String, dynamic> result) {
    final user = User.fromJson(result['user']);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation(user: user)),
      (route) => false,
    );
  }

  /// เข้าสู่ระบบด้วย Email + Password ผ่าน Supabase Auth
  Future<void> _loginWithEmail() async {
    if (_busy) return; // กันการกดซ้ำ
    setState(() {
      _submitted = true;
      _bannerMessage = null;
      _canResendVerification = false;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // บอกเบราว์เซอร์/ตัวจัดการรหัสผ่านว่าล็อกอินสำเร็จ เพื่อเสนอบันทึกรหัสผ่าน
      TextInput.finishAutofillContext();
      await _saveCredentials();
      if (mounted) _goToApp(result);
    } else {
      // ล็อกอินไม่ผ่าน: ล้างเฉพาะรหัสผ่านแล้วพาเคอร์เซอร์กลับไปที่ช่องนั้น อีเมลคงไว้
      _passwordController.clear();
      _passwordFocus.requestFocus();
      _showBanner(
        result['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่',
        canResend: result['code'] == 'email_not_confirmed',
      );
    }
  }

  /// ส่งอีเมลยืนยันบัญชีอีกครั้ง (แสดงเมื่อล็อกอินไม่ได้เพราะยังไม่ยืนยันอีเมล)
  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (_isResending || _validateEmail(email) != null) return;

    setState(() => _isResending = true);
    final result = await AuthService.resendVerificationEmail(email);
    if (!mounted) return;
    setState(() => _isResending = false);
    _showBanner(result['message'] ?? '', isError: result['success'] != true);
  }

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
              child: Form(
                key: _formKey,
                // ยังไม่เตือนระหว่างพิมพ์ครั้งแรก เตือนเมื่อกดส่ง แล้วหลังจากนั้นตรวจทันทีที่แก้
                autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                // AutofillGroup ให้เบราว์เซอร์และตัวจัดการรหัสผ่านเห็นอีเมลกับรหัสผ่านเป็นชุดเดียวกัน
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เข้าสู่ระบบ', style: AppTextStyles.title.copyWith(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text('ใช้อีเมลและรหัสผ่านที่สมัครไว้', style: AppTextStyles.body),
                      const SizedBox(height: 28),

                      // ข้อความแจ้งผล (ล็อกอินไม่ผ่าน / ส่งอีเมลยืนยันแล้ว) แสดงค้างไว้เหนือฟอร์ม
                      if (_bannerMessage != null) ...[
                        AuthMessageBanner(
                          message: _bannerMessage!,
                          isError: _bannerIsError,
                          actionLabel: _canResendVerification
                              ? (_isResending ? 'กำลังส่ง...' : 'ส่งอีเมลยืนยันอีกครั้ง')
                              : null,
                          onAction: _isResending ? null : _resendVerification,
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildLabel('อีเมล'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'yourname@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        autofocus: AppLayout.isWide(context),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),

                      _buildLabel('รหัสผ่าน'),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        hintText: 'รหัสผ่านของคุณ',
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        // กด Enter ในช่องรหัสผ่าน = กดปุ่มเข้าสู่ระบบ
                        onSubmitted: (_) => _loginWithEmail(),
                        validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // จดจำอีเมล: กดได้ทั้งแถว
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        onTap: _busy ? null : () => setState(() => _rememberMe = !_rememberMe),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: _busy ? null : (value) => setState(() => _rememberMe = value ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('จดจำอีเมลในเครื่องนี้', style: AppTextStyles.small),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _loginWithEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: AppColors.night, strokeWidth: 2.2),
                                )
                              : const Text('เข้าสู่ระบบ'),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),

                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('ยังไม่มีบัญชี', style: AppTextStyles.small),
                          const SizedBox(width: 4),
                          // TextButton ให้กด Tab มาถึงและกด Enter ได้
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  ),
                            child: const Text('สร้างบัญชีใหม่'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ป้ายชื่อเหนือช่องกรอก
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );
  }

  /// ช่องกรอกข้อมูล ข้อความตรวจสอบแสดงใต้ช่อง หน้าตามาจากธีมกลาง
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    bool autofocus = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: !_busy,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      // อีเมลและรหัสผ่านไม่ควรถูกแก้คำอัตโนมัติ
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      onChanged: (_) => _clearBanner(),
      onFieldSubmitted: onSubmitted,
      style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16),
      decoration: InputDecoration(hintText: hintText, suffixIcon: suffixIcon),
    );
  }
}
