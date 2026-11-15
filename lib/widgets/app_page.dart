import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ค่ากลางสำหรับจัดความกว้างของเนื้อหาบนจอกว้าง (เว็บ/แท็บเล็ต)
/// ทุกหน้าใช้ชุดเดียวกันเพื่อให้เนื้อหาอยู่กึ่งกลางและไม่ยืดเต็มจอ
class AppLayout {
  /// หน้าแดชบอร์ดที่มีหลายคอลัมน์
  static const double wideWidth = 1280;

  /// หน้าเนื้อหาทั่วไป (รายการ การ์ด รายงาน)
  static const double contentWidth = 960;

  /// หน้าอ่าน/ตั้งค่า/แชต ที่ควรแคบกว่าเพื่ออ่านง่าย
  static const double readingWidth = 820;

  /// หน้าแบบฟอร์ม (ล็อกอิน สมัครสมาชิก เปลี่ยนรหัสผ่าน)
  static const double formWidth = 560;

  /// ระยะขอบซ้ายขวาที่ทำให้เนื้อหากว้างไม่เกิน [maxWidth] และไม่น้อยกว่า [min]
  /// ใช้เป็น padding ของ ListView/ScrollView เพื่อให้เลื่อนได้ทั้งความกว้างจอ
  static double gutter(BuildContext context, {double maxWidth = contentWidth, double min = 20}) {
    final width = MediaQuery.sizeOf(context).width;
    return math.max(min, (width - maxWidth) / 2);
  }

  /// จอกว้างพอสำหรับเลย์เอาต์แบบเดสก์ท็อปหรือไม่
  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;
}

/// พื้นหลังมาตรฐานของทุกหน้า: ไล่สีฟ้าอ่อนพร้อมวงแสงสีน้ำเงินและเขียวจาง ๆ
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.glassBackgroundGradient),
      child: Stack(
        children: [
          const Positioned(
            top: -160,
            right: -120,
            child: _Glow(color: AppColors.primaryBlue, size: 520),
          ),
          const Positioned(
            top: 380,
            left: -200,
            child: _Glow(color: AppColors.primaryGreen, size: 520),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

/// จัดเนื้อหาให้อยู่กึ่งกลางและกว้างไม่เกิน [maxWidth]
/// ใช้กับส่วนที่ไม่เลื่อน (หัวหน้า แถบแท็บ ช่องพิมพ์) หรือครอบเนื้อหาภายใน ScrollView
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// กรอบการ์ดกระจกสำหรับหน้าแบบฟอร์ม (ล็อกอิน/สมัครสมาชิก)
/// จอกว้าง: ครอบเนื้อหาด้วยการ์ดกึ่งกลางจอ จอแคบ: แสดงเนื้อหาตามเดิมไม่มีกรอบ
class AuthCard extends StatelessWidget {
  final Widget child;

  /// จำกัดความสูงสูงสุดของการ์ด ใช้กับเนื้อหาที่ขยายเต็มความสูง (มี Expanded ภายใน)
  final double? maxHeight;

  const AuthCard({super.key, required this.child, this.maxHeight});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 640) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.formWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                blurRadius: 48,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// AppBar มาตรฐานของหน้าย่อย: พื้นโปร่งใส ปุ่มย้อนกลับ และหัวเรื่องสีน้ำเงินกึ่งกลาง
PreferredSizeWidget buildAppPageBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      tooltip: 'ย้อนกลับ',
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryBlue, size: 20),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.primaryBlue,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    actions: actions,
  );
}

/// กล่องข้อความในฟอร์มล็อกอิน/สมัครสมาชิก ใช้แจ้งข้อผิดพลาดหรือผลสำเร็จไว้ในหน้า
/// ข้อความอยู่ค้างจนผู้ใช้แก้ไข และโปรแกรมอ่านหน้าจอจะอ่านให้ทันทีที่ปรากฏ
class AuthMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;

  /// ปุ่มเสริมใต้ข้อความ เช่น "ส่งอีเมลยืนยันอีกครั้ง"
  final String? actionLabel;
  final VoidCallback? onAction;

  const AuthMessageBanner({
    super.key,
    required this.message,
    this.isError = true,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : const Color(0xFF067647);
    final background = isError ? const Color(0xFFFEF3F2) : const Color(0xFFECFDF3);
    final border = isError ? const Color(0xFFFECDCA) : const Color(0xFFABEFC6);

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: color, fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500),
                  ),
                  if (actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: InkWell(
                        onTap: onAction,
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            color: onAction == null ? color.withValues(alpha: 0.5) : color,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
