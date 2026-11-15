import 'package:flutter/material.dart'; // สำหรับสร้าง UI ด้วยองค์ประกอบ Material Design
import 'package:flutter/services.dart'; // TextInput.finishAutofillContext ให้เบราว์เซอร์บันทึกรหัสผ่าน
import 'package:google_fonts/google_fonts.dart'; // สำหรับใช้ฟอนต์สวยงามจาก Google Fonts
import 'package:shared_preferences/shared_preferences.dart'; // สำหรับบันทึกอีเมลล่าสุดไว้ในเครื่อง (Remember Me)
import '../../theme/app_theme.dart'; // เรียกใช้ชุดสีและดีไซน์หลักของแอป
import '../../services/auth_service.dart'; // เชื่อมต่อระบบล็อกอิน (Supabase, Google Sign-In)
import '../../models/user.dart'; // รูปแบบโครงสร้างข้อมูลผู้ใช้งาน
import '../main_navigation.dart'; // สำหรับเปลี่ยนหน้าไปยังหน้าหลักหลังเข้าระบบสำเร็จ
import 'register_screen.dart'; // สำหรับเปิดหน้าจอสมัครสมาชิกใหม่เมื่อคลิกสมัคร
import '../../widgets/app_page.dart';
import '../../utils/password_validator.dart'; // ตรวจรูปแบบอีเมล

/// LoginScreen เป็นหน้าจอล็อกอินสำหรับการเข้าสู่ระบบผู้ใช้งาน
/// รองรับ 2 ช่องทาง:
///   1. Email + Password (ผ่าน Supabase Auth)
///   2. Google Sign-In (OAuth 2.0)
/// มีระบบจดจำ Email ผ่าน SharedPreferences และฟังก์ชันลืมรหัสผ่าน
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
  bool _isLoading = false;      // ใช้แสดงโหลดดิ้งขณะเชื่อมต่อ API
  bool _isGoogleLoading = false; // ใช้แสดงโหลดดิ้งขณะ Google Sign-In
  bool _isResending = false;    // กำลังส่งอีเมลยืนยันซ้ำ
  bool _rememberMe = false;     // ติ๊กบันทึก email ในเครื่องหรือไม่
  bool _submitted = false;      // กดเข้าสู่ระบบแล้วอย่างน้อยหนึ่งครั้ง: หลังจากนี้ตรวจช่องกรอกทันทีที่พิมพ์

  // ข้อความแจ้งผลที่แสดงค้างไว้เหนือฟอร์ม (ไม่ใช้ SnackBar เพราะหายเองและอยู่ไกลจากช่องกรอก)
  String? _bannerMessage;
  bool _bannerIsError = true;
  bool _canResendVerification = false;

  bool get _busy => _isLoading || _isGoogleLoading;

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
    if (!PasswordValidator.isValidEmail(email)) return 'รูปแบบอีเมลไม่ถูกต้อง เช่น name@example.com';
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

  /// เข้าสู่ระบบด้วย Google Sign-In
  Future<void> _loginWithGoogle() async {
    if (_busy) return;
    setState(() {
      _isGoogleLoading = true;
      _bannerMessage = null;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    // เว็บ: กำลังออกไปหน้า Google ให้ปุ่มหมุนค้างไว้จนเปลี่ยนหน้า
    if (result['redirecting'] == true) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      _goToApp(result);
    } else if (result['message'] != 'ยกเลิกการเข้าสู่ระบบด้วย Google') {
      // ถ้าผู้ใช้กดยกเลิกเอง ไม่ต้องแสดง error
      _showBanner(result['message'] ?? 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
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

  /// แสดง Dialog สำหรับกรอก email เพื่อรีเซ็ตรหัสผ่าน
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        void submit() {
          if (dialogFormKey.currentState!.validate()) {
            Navigator.pop(context, emailController.text.trim());
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'ลืมรหัสผ่าน',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'กรอกอีเมลที่ใช้สมัครสมาชิก เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ไปให้',
                    style: GoogleFonts.prompt(fontSize: 13, color: AppColors.textGray, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => submit(),
                    validator: _validateEmail,
                    style: GoogleFonts.prompt(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintStyle: GoogleFonts.prompt(color: AppColors.textLight),
                      errorStyle: GoogleFonts.prompt(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: GoogleFonts.prompt(color: AppColors.textGray)),
            ),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ส่งลิงก์', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // รอให้ dialog ปิดสนิทก่อนค่อยทิ้ง controller
    WidgetsBinding.instance.addPostFrameCallback((_) => emailController.dispose());

    if (email == null || !mounted) return;
    final result = await AuthService.sendPasswordResetEmail(email);
    if (mounted) {
      _showBanner(result['message'] ?? '', isError: result['success'] != true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
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
            'เข้าสู่ระบบ',
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
          child: AuthCard(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppLayout.isWide(context) ? 16 : 0),
          child: Form(
            key: _formKey,
            // ยังไม่เตือนระหว่างพิมพ์ครั้งแรก เตือนเมื่อกดส่ง แล้วหลังจากนั้นตรวจทันทีที่แก้
            autovalidateMode:
                _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            // AutofillGroup ให้เบราว์เซอร์และตัวจัดการรหัสผ่านเห็นอีเมลกับรหัสผ่านเป็นชุดเดียวกัน
            child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'ยินดีต้อนรับกลับมา',
                style: GoogleFonts.prompt(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาเข้าสู่ระบบเพื่อใช้งานฟีเจอร์ต่างๆ และเริ่มต้นตรวจสอบวิเคราะห์สถานะสมองของคุณ',
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // ข้อความแจ้งผล (ล็อกอินไม่ผ่าน / ส่งอีเมลแล้ว) แสดงค้างไว้เหนือฟอร์ม
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

              // ช่อง Email
              _buildLabel('อีเมล'),
              _buildTextField(
                controller: _emailController,
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                autofillHints: const [AutofillHints.username, AutofillHints.email],
                textInputAction: TextInputAction.next,
                autofocus: AppLayout.isWide(context),
                validator: _validateEmail,
              ),

              const SizedBox(height: 20),

              // ช่องรหัสผ่าน
              _buildLabel('รหัสผ่าน'),
              _buildTextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                hintText: 'ระบุรหัสผ่านของคุณ',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                // กด Enter ในช่องรหัสผ่าน = กดปุ่มเข้าสู่ระบบ
                onSubmitted: (_) => _loginWithEmail(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textGray,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // จดจำรหัสผ่าน + ลืมรหัสผ่าน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: _busy
                              ? null
                              : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
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
                      Text(
                        'จดจำอีเมล',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _busy ? null : _showForgotPasswordDialog,
                    child: Text(
                      'ลืมรหัสผ่าน?',
                      style: GoogleFonts.prompt(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ปุ่มเข้าสู่ระบบด้วย Email
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy ? null : _loginWithEmail,
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
                          'เข้าสู่ระบบ',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 24),

              // ปุ่มเข้าสู่ระบบด้วย Google
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _loginWithGoogle,
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
                    'เข้าสู่ระบบด้วย Google',
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

              const SizedBox(height: 28),

              // ลิงก์ไปหน้าสมัครสมาชิก
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ยังไม่มีบัญชีใช่ไหม? ',
                    style: GoogleFonts.prompt(color: AppColors.textGray, fontSize: 13.5),
                  ),
                  // InkWell ให้กด Tab มาถึงและกด Enter ได้ (GestureDetector รับโฟกัสคีย์บอร์ดไม่ได้)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _busy
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'สมัครสมาชิก',
                        style: GoogleFonts.prompt(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
            ),
          ),
          )),
        ),
      ),
    ),
  );
  }

  /// สร้างป้ายชื่อเหนือช่องกรอกข้อมูล
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.prompt(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  /// สร้างช่องกรอกข้อมูลพร้อมไอคอน ข้อความตรวจสอบแสดงใต้ช่อง
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    bool autofocus = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
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
      style: GoogleFonts.prompt(fontSize: 15, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        errorStyle: GoogleFonts.prompt(fontSize: 12),
      ),
    );
  }
}
