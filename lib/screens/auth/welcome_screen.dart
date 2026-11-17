import 'package:flutter/material.dart';
import '../../widgets/app_page.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../main_navigation.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// หน้าแรกของแอป: บอกว่าแอปทำอะไรในประโยคเดียว เส้นคลื่นสมองลากผ่านกลางจอ แล้วให้เลือกเข้าสู่ระบบหรือสร้างบัญชี
/// รองรับ Auto-login: ถ้ามี session Supabase Auth ที่ยังไม่หมดอายุ จะข้ามไปหน้า MainNavigation อัตโนมัติ
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isCheckingSession = true; // กำลังเช็ก session ที่ค้างอยู่ในเครื่อง

  @override
  void initState() {
    super.initState();

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

  /// ตรวจสอบว่าผู้ใช้มี Supabase Auth session ที่ยังใช้ได้อยู่หรือไม่
  /// ถ้ามี → ดึงข้อมูล User แล้วข้ามไปหน้า MainNavigation ทันที (Auto-login)
  Future<void> _checkExistingSession() async {
    // รอให้ Supabase initialize เสร็จก่อน (เผื่อยังไม่เสร็จ)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
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

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, wide ? 48 : 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Text('Smart Brain', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(height: wide ? 56 : 32),
                          Text(
                            'ฟังสมองของคุณ\nวันละ 90 วินาที',
                            style: AppTextStyles.display.copyWith(fontSize: wide ? 44 : 34),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Text(
                              'ต่ออุปกรณ์ Muse วัดคลื่นสมอง แล้วดูผลคู่กับแบบประเมิน PHQ-9 ได้ในที่เดียว',
                              style: AppTextStyles.body.copyWith(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 36),
                          BrainLine(height: wide ? 120 : 96, animate: true, strokeWidth: 1.8),
                          const SizedBox(height: 8),
                          const _BandScale(),
                          const Spacer(),
                          SizedBox(height: wide ? 56 : 40),
                          if (_isCheckingSession)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text('กำลังตรวจสอบการเข้าสู่ระบบ', style: AppTextStyles.small),
                              ],
                            )
                          else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _open(const LoginScreen()),
                                child: const Text('เข้าสู่ระบบ'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _open(const RegisterScreen()),
                                child: const Text('สร้างบัญชีใหม่'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'ผลจากแอปเป็นข้อมูลประกอบ ไม่ใช่การวินิจฉัยโรค',
                            style: AppTextStyles.caption,
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
}

/// ชื่อย่านคลื่นใต้เส้น เรียงจากช้าไปเร็ว ตรงกับส่วนผสมที่ใช้วาดเส้น
class _BandScale extends StatelessWidget {
  const _BandScale();

  @override
  Widget build(BuildContext context) {
    const bands = ['Delta', 'Theta', 'Alpha', 'Beta'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final b in bands)
          Text(
            b,
            style: AppTextStyles.caption.copyWith(
              color: b == 'Alpha' ? AppColors.primary : AppColors.inkFaint,
              fontWeight: b == 'Alpha' ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
      ],
    );
  }
}
