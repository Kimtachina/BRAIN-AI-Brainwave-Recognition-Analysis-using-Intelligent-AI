import 'package:flutter/material.dart';
import '../../widgets/app_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../main_navigation.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import '../../services/supabase_service.dart';

/// WelcomeScreen คือหน้าจอแรกหลังจากเปิดแอปพลิเคชัน (Splash/Welcome Screen)
/// ทำหน้าที่ต้อนรับผู้ใช้งาน แนะนำฟีเจอร์หลักของระบบ และแสดงปุ่มเลือกสำหรับลงทะเบียนหรือเข้าสู่ระบบ
/// รองรับ Auto-login: ถ้ามี session Supabase Auth ที่ยังไม่หมดอายุ จะข้ามไปหน้า MainNavigation อัตโนมัติ
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  // สร้างและจัดการการแอนิเมชันสำหรับเอฟเฟกต์ค่อยๆ แสดงผล (Fade-In Animation) ตอนเปิดแอป
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isCheckingSession = true;  // บอกสถานะว่ากำลังเช็ค session อยู่หรือไม่

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // เริ่มเช็ค session ในเครื่อง
    _checkExistingSession();

    // ระบบจับเวลาสำรอง (Fallback Timer) ป้องกันหน้าจอค้าง
    // หากเช็คข้อมูลช้าเกิน 4 วินาที (เช่น ปัญหาระบบเครือข่าย) จะยกเลิกการรอและแสดงปุ่มเข้าสู่ระบบทันที
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isCheckingSession) {
        setState(() => _isCheckingSession = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ตรวจสอบว่าผู้ใช้มี Supabase Auth session ที่ยังใช้ได้อยู่หรือไม่
  /// ถ้ามี → ดึงข้อมูล User แล้วข้ามไปหน้า MainNavigation ทันที (Auto-login)
  Future<void> _checkExistingSession() async {
    // รอให้ Supabase initialize เสร็จก่อน (เผื่อยังไม่เสร็จ)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      // เปิดเว็บมาจากลิงก์รีเซ็ตรหัสผ่าน: ต้องตั้งรหัสผ่านใหม่ก่อน ไม่ล็อกอินอัตโนมัติ
      if (AuthService.isLoggedIn && SupabaseService.passwordRecoveryPending) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          (route) => false,
        );
        return;
      }
      if (AuthService.isLoggedIn) {
        final result = await AuthService.restoreSession();
        if (result['success'] == true && mounted) {
          final user = User.fromJson(result['user']);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainNavigation(user: user)),
            (route) => false,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Auto-login failed: $e');
    }

    if (mounted) {
      setState(() => _isCheckingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: AuthCard(
              maxHeight: 900,
              child: Column(
              children: [
                SizedBox(height: AppLayout.isWide(context) ? 20 : 60),

                // โลโก้แอปและหัวข้อหลัก
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15), width: 1.5),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        size: 52,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'SmartBrain Care',
                      style: AppTextStyles.heroTitle.copyWith(
                        color: AppColors.primaryBlue,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'ระบบติดตามและวิเคราะห์คลื่นสมองส่วนบุคคล',
                  style: GoogleFonts.prompt(
                    color: AppColors.textGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  flex: 3,
                  child: _isCheckingSession
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'กำลังตรวจสอบการเข้าสู่ระบบ...',
                                style: GoogleFonts.prompt(
                                  color: AppColors.textGray,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.analytics_rounded,
                                  size: 120,
                                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                ),
                              );
                            },
                          ),
                        ),
                ),

                const SizedBox(height: 12),

                if (!_isCheckingSession) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'แอปพลิเคชันช่วยเหลือการวิเคราะห์คลื่นสมองจริง (EEG Telemetry) และประเมินสภาวะทางอารมณ์รายบุคคลอย่างละเอียด เพื่อการมีสุขภาวะทางสมองที่ดีขึ้น',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(
                        color: AppColors.textGray,
                        fontSize: 12.5,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        // ปุ่มเข้าสู่ระบบ
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'เข้าสู่ระบบ',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ปุ่มสมัครบัญชี
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'สมัครบัญชีใช้งาน',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
