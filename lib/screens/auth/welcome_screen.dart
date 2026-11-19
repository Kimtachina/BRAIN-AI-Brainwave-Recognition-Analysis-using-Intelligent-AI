import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../main_navigation.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../widgets/brainwave_scene.dart';

/// หน้าแรกของแอป: ฉากมืดเต็มจอ คำ "Brain" ใหญ่จมอยู่หลังเส้นคลื่นสมองที่ซ้อนกันเป็นชั้น
/// หัวเรื่องซ้ายล่าง คำอธิบายกับปุ่มสร้างบัญชีขวาล่าง ปุ่มเข้าสู่ระบบอยู่แถบบน
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
    return Scaffold(
      backgroundColor: HeroPalette.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final wide = w >= 900;
          // จอเตี้ยเกินไปให้เลื่อนดูได้ ฉากไม่บีบจนตัวหนังสือทับกัน
          final height = math.max(constraints.maxHeight, wide ? 660.0 : 780.0);
          final horizon = wide ? 0.44 : 0.36;
          final wordSize = math.min(w * 0.31, height * (wide ? 0.42 : 0.3));
          final gutter = wide ? (w * 0.07).clamp(32.0, 112.0) : 20.0;

          return SingleChildScrollView(
            child: SizedBox(
              width: w,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(child: HeroBackdrop(horizon: horizon)),
                  // เส้นฐานของคำอยู่ต่ำกว่าขอบฟ้าเล็กน้อย เส้นคลื่นด้านหน้าจึงบังท้ายตัวอักษร
                  Positioned(
                    left: 0,
                    right: 0,
                    top: height * horizon - wordSize * 0.77,
                    child: Center(child: GiantWord(text: 'Brain', fontSize: wordSize)),
                  ),
                  Positioned.fill(child: BrainwaveField(horizon: horizon)),
                  const Positioned.fill(child: HeroShade()),
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        children: [
                          _NavBar(
                            gutter: gutter,
                            wide: wide,
                            checking: _isCheckingSession,
                            onLogin: () => _open(const LoginScreen()),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, wide ? 56 : 28),
                            child: wide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: _Headline(fontSize: (w * 0.052).clamp(40.0, 76.0))),
                                      const SizedBox(width: 48),
                                      SizedBox(width: 400, child: _Pitch(checking: _isCheckingSession, onRegister: _register)),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Headline(fontSize: (w * 0.1).clamp(32.0, 44.0)),
                                      const SizedBox(height: 20),
                                      _Pitch(checking: _isCheckingSession, onRegister: _register),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _register() => _open(const RegisterScreen());
}

TextStyle _onNight(double size, {double alpha = 1, FontWeight weight = FontWeight.w400, double height = 1.5}) =>
    GoogleFonts.ibmPlexSansThai(
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: HeroPalette.text.withValues(alpha: alpha),
    );

/// แถบบน: ชื่อแอป, ชื่อย่านคลื่นตรงกลาง (จอกว้าง), ปุ่มเข้าสู่ระบบทางขวา
class _NavBar extends StatelessWidget {
  final double gutter;
  final bool wide;
  final bool checking;
  final VoidCallback onLogin;

  const _NavBar({required this.gutter, required this.wide, required this.checking, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 84 : 68,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: HeroPalette.text.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: HeroPalette.alpha, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text('SMART BRAIN', style: _onNight(wide ? 19 : 16, weight: FontWeight.w600).copyWith(letterSpacing: 1.6)),
          Expanded(child: wide ? const _BandNames() : const SizedBox()),
          if (checking)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: HeroPalette.text),
            )
          else
            PillAction(label: 'เข้าสู่ระบบ', onPressed: onLogin, compact: !wide),
        ],
      ),
    );
  }
}

/// ชื่อย่านคลื่นเรียงจากช้าไปเร็ว Alpha (ภาวะผ่อนคลาย) เด่นกว่าตัวอื่น เป็นป้ายบอก ไม่ใช่ลิงก์
class _BandNames extends StatelessWidget {
  const _BandNames();

  @override
  Widget build(BuildContext context) {
    const bands = ['Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final b in bands)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              b,
              style: b == 'Alpha'
                  ? _onNight(16, weight: FontWeight.w600).copyWith(color: HeroPalette.alpha)
                  : _onNight(16, alpha: 0.62),
            ),
          ),
      ],
    );
  }
}

/// หัวเรื่องสามบรรทัด บรรทัดแรกเยื้องเข้า บรรทัดกลางสีจาง ตามจังหวะของภาพต้นแบบ
class _Headline extends StatelessWidget {
  final double fontSize;

  const _Headline({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final style = _onNight(fontSize, weight: FontWeight.w600, height: 1.2).copyWith(letterSpacing: -fontSize * 0.02);
    return Semantics(
      header: true,
      label: 'ฟังสมองของคุณ วันละ 90 วินาที',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: fontSize * 1.9),
              child: Text('ฟังสมอง', style: style),
            ),
            Text('ของคุณ', style: style.copyWith(color: HeroPalette.text.withValues(alpha: 0.5))),
            Text('วันละ 90 วินาที', style: style),
          ],
        ),
      ),
    );
  }
}

/// คำอธิบายสั้น ปุ่มสร้างบัญชี และคำเตือนว่าผลไม่ใช่การวินิจฉัย
class _Pitch extends StatelessWidget {
  final bool checking;
  final VoidCallback onRegister;

  const _Pitch({required this.checking, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ต่ออุปกรณ์ Muse วัดคลื่นสมอง แล้วดูผลคู่กับแบบประเมิน PHQ-9 ได้ในที่เดียว',
          style: _onNight(16, alpha: 0.72, height: 1.65),
        ),
        const SizedBox(height: 24),
        if (checking)
          Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: HeroPalette.text),
              ),
              const SizedBox(width: 12),
              Text('กำลังตรวจสอบการเข้าสู่ระบบ', style: _onNight(13, alpha: 0.72)),
            ],
          )
        else
          PillAction(label: 'สร้างบัญชีใหม่', onPressed: onRegister),
        const SizedBox(height: 18),
        Text('ผลจากแอปเป็นข้อมูลประกอบ ไม่ใช่การวินิจฉัยโรค', style: _onNight(12, alpha: 0.45)),
      ],
    );
  }
}
