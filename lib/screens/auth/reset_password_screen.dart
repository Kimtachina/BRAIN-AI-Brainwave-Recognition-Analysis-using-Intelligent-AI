import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/password_validator.dart';
import '../../widgets/app_page.dart';
import '../main_navigation.dart';
import 'welcome_screen.dart';

/// หน้าตั้งรหัสผ่านใหม่ เปิดเมื่อผู้ใช้กดลิงก์รีเซ็ตรหัสผ่านจากอีเมล
/// ตั้งสำเร็จแล้วเข้าแอปต่อได้เลย ถ้ายกเลิกจะออกจากระบบ เพื่อไม่ให้ลิงก์ในอีเมลใช้ล็อกอินโดยไม่ตั้งรหัสผ่าน
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.setNewPassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // บอกเบราว์เซอร์/ตัวจัดการรหัสผ่านให้บันทึกรหัสผ่านใหม่
      TextInput.finishAutofillContext();
      final user = User.fromJson(result['user']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation(user: user)),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result['message'] ?? 'ตั้งรหัสผ่านใหม่ไม่สำเร็จ');
    }
  }

  Future<void> _cancel() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final checks = PasswordValidator.evaluate(_passwordController.text).checks;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SizedBox(
            height: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AuthCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.isWide(context) ? 16 : 0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode:
                        _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'ตั้งรหัสผ่านใหม่',
                            style: GoogleFonts.prompt(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ตั้งรหัสผ่านใหม่สำหรับบัญชีของคุณ แล้วใช้รหัสผ่านนี้เข้าสู่ระบบครั้งต่อไป',
                            style: GoogleFonts.prompt(fontSize: 13, color: AppColors.textGray, height: 1.5),
                          ),
                          const SizedBox(height: 28),

                          if (_errorMessage != null) ...[
                            AuthMessageBanner(message: _errorMessage!),
                            const SizedBox(height: 20),
                          ],

                          _label('รหัสผ่านใหม่'),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscure,
                            autofocus: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.prompt(fontSize: 15, color: AppColors.textDark),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่านใหม่';
                              if (!PasswordValidator.isAcceptable(value)) {
                                return 'รหัสผ่านยังไม่ผ่านเกณฑ์ด้านล่าง';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'อย่างน้อย $kMinPasswordLength ตัวอักษร',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              errorStyle: GoogleFonts.prompt(fontSize: 12),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textGray,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _check(checks.minLength, 'ยาวอย่างน้อย $kMinPasswordLength ตัวอักษร'),
                          _check(checks.hasUppercase, 'มีตัวพิมพ์ใหญ่ (A-Z)'),
                          _check(checks.hasLowercase, 'มีตัวพิมพ์เล็ก (a-z)'),
                          _check(checks.hasDigit, 'มีตัวเลข (0-9)'),
                          _check(checks.hasSpecialChar, 'มีอักขระพิเศษ เช่น ! @ # ?'),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Text(
                              'ต้องผ่านอย่างน้อย 4 จาก 5 ข้อ',
                              style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textLight),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _label('ยืนยันรหัสผ่านใหม่'),
                          TextFormField(
                            controller: _confirmController,
                            enabled: !_isLoading,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                            style: GoogleFonts.prompt(fontSize: 15, color: AppColors.textDark),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่านอีกครั้ง';
                              if (value != _passwordController.text) return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              errorStyle: GoogleFonts.prompt(fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'บันทึกรหัสผ่านใหม่',
                                      style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : _cancel,
                              child: Text(
                                'ยกเลิกและกลับหน้าแรก',
                                style: GoogleFonts.prompt(color: AppColors.textGray, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
    );
  }

  Widget _check(bool passed, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: passed ? AppColors.primaryGreen : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.prompt(fontSize: 12.5, color: passed ? AppColors.textDark : AppColors.textGray),
          ),
        ],
      ),
    );
  }
}
