import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'sky_backdrop.dart';

/// ค่ากลางสำหรับจัดความกว้างของเนื้อหาบนจอกว้าง (เว็บ/แท็บเล็ต)
class AppLayout {
  static const double wideWidth = 1180;
  static const double pageWidth = wideWidth - 64; // ความกว้างเนื้อหาของหน้า "วันนี้" (1180 ลบขอบ 32 สองข้าง)
  static const double contentWidth = 920;
  static const double readingWidth = 760;
  static const double formWidth = 440;

  /// ระยะขอบซ้ายขวาที่ทำให้เนื้อหากว้างไม่เกิน [maxWidth] และไม่น้อยกว่า [min]
  /// ค่าเริ่มต้นกว้างเต็มเท่าหน้า "วันนี้" คิดจากพื้นที่จริงที่เหลือหลังหักแถบเมนูซ้าย
  static double gutter(BuildContext context, {double maxWidth = pageWidth, double? min}) {
    final width = available(context);
    return math.max(min ?? (isWide(context) ? 32 : 20), (width - maxWidth) / 2);
  }

  /// ความกว้างที่หน้าใช้ได้จริง: ความกว้างจอ ลบแถบเมนูด้านซ้าย (ถ้าหน้าอยู่ในโครงหลัก)
  static double available(BuildContext context) =>
      MediaQuery.sizeOf(context).width - (ShellInset.maybeOf(context) ?? 0);

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;
}

/// บอกหน้าที่อยู่ในโครงหลักว่าแถบเมนูซ้ายกินพื้นที่ไปเท่าไร เพื่อคำนวณขอบให้ถูก
class ShellInset extends InheritedWidget {
  final double left;

  const ShellInset({super.key, required this.left, required super.child});

  static double? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellInset>()?.left;

  @override
  bool updateShouldNotify(ShellInset old) => old.left != left;
}

/// พื้นหลังของหน้าด้านในแอป: ฉากท้องฟ้า (หน้าแรกและหน้าเข้าสู่ระบบยังเป็นฉากกลางคืน)
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: SkyBackdrop()),
          Positioned.fill(child: child),
        ],
      );
}

/// จัดเนื้อหาให้อยู่กึ่งกลางและกว้างไม่เกิน [maxWidth]
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContent({super.key, required this.child, this.maxWidth = AppLayout.pageWidth});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// กรอบของหน้าแบบฟอร์ม (ล็อกอิน สมัครสมาชิก ตั้งค่า)
/// ทุกขนาดจอ: คอลัมน์แคบชิดกึ่งกลาง เนื้อหาชิดซ้าย ไม่มีการ์ดลอย
/// จอกว้างวางบนแผ่นขาวขอบบาง เพื่อแยกฟอร์มออกจากพื้นที่ว่างรอบ ๆ
class AuthCard extends StatelessWidget {
  final Widget child;
  final double? maxHeight;

  const AuthCard({super.key, required this.child, this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final column = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppLayout.formWidth, maxHeight: maxHeight ?? double.infinity),
      child: child,
    );
    if (!wide) return Center(child: column);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
        decoration: AppTheme.panel(radius: AppRadius.sheet),
        child: column,
      ),
    );
  }
}

/// แถบหัวหน้าย่อย: ปุ่มย้อนกลับกับชื่อหน้าชิดซ้าย พื้นสีเดียวกับหน้า เส้นบางใต้แถบ
PreferredSizeWidget buildAppPageBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: AppColors.skyTop,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      tooltip: 'ย้อนกลับ',
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 22),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 18)),
    actions: actions,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, thickness: 1, color: AppColors.line),
    ),
  );
}

/// กล่องข้อความในฟอร์ม ใช้แจ้งข้อผิดพลาดหรือผลสำเร็จไว้ในหน้า
/// แถบสีด้านซ้ายบอกประเภท ข้อความอยู่ค้างจนผู้ใช้แก้ไข และโปรแกรมอ่านหน้าจอจะอ่านให้ทันที
class AuthMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
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
    final accent = isError ? AppColors.error : AppColors.secondary;
    final text = isError ? const Color(0xFFF4B3B3) : const Color(0xFF9BE3D6);

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withValues(alpha: 0.12), AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.control)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message, style: AppTextStyles.small.copyWith(color: text, height: 1.5)),
                      if (actionLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: InkWell(
                            onTap: onAction,
                            child: Text(
                              actionLabel!,
                              style: AppTextStyles.small.copyWith(
                                color: onAction == null ? text.withValues(alpha: 0.5) : text,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: text,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่ม/การ์ดที่กดได้: ยุบลงเล็กน้อยทันทีที่นิ้วแตะ (ไม่รอปล่อยนิ้ว) แล้วคืนตัวด้วย ease-out
/// ใช้กับพื้นที่กดที่ไม่ใช่ปุ่มของ Material
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  const Pressable({super.key, required this.child, this.onTap, this.pressedScale = 0.97, this.semanticLabel});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1,
            duration: AppMotion.press,
            curve: AppMotion.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// เส้นคลื่นสมองเส้นเดียว เป็นเอกลักษณ์ของแอป
/// สร้างจากคลื่นหลายความถี่ซ้อนกัน (Delta ถึง Beta) ด้วยค่าคงที่ จึงได้รูปเดิมทุกครั้ง
/// [animate] = true: ลากเส้นจากซ้ายไปขวาครั้งเดียวตอนแสดง (ข้ามถ้าเครื่องตั้งลดการเคลื่อนไหว)
class BrainLine extends StatefulWidget {
  final double height;
  final Color color;
  final bool animate;
  final double strokeWidth;
  final int seed;

  const BrainLine({
    super.key,
    this.height = 56,
    this.color = AppColors.primary,
    this.animate = false,
    this.strokeWidth = 1.6,
    this.seed = 7,
  });

  @override
  State<BrainLine> createState() => _BrainLineState();
}

class _BrainLineState extends State<BrainLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.reveal);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || AppMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _BrainLinePainter(
              progress: AppMotion.easeOut.transform(_c.value),
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              seed: widget.seed,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrainLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final int seed;

  _BrainLinePainter({required this.progress, required this.color, required this.strokeWidth, required this.seed});

  double _y(double t) {
    // ส่วนผสมของคลื่น: ช้าและกว้าง (Delta/Theta) + กลาง (Alpha) + เร็วและเล็ก (Beta)
    final s = seed.toDouble();
    final slow = math.sin(t * 2 * math.pi * 1.3 + s) * 0.30;
    final theta = math.sin(t * 2 * math.pi * 4.7 + s * 0.7) * 0.20;
    // ช่วงกลางเส้นมี Alpha เด่นขึ้น เหมือนตอนหลับตาผ่อนคลาย
    final burst = math.exp(-math.pow((t - 0.62) / 0.12, 2).toDouble());
    final alpha = math.sin(t * 2 * math.pi * 10.5 + s * 1.3) * (0.10 + 0.32 * burst);
    final beta = math.sin(t * 2 * math.pi * 23 + s * 2.1) * 0.06;
    return slow + theta + alpha + beta;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const steps = 360;
    final mid = size.height / 2;
    final amp = size.height / 2 * 0.92;
    final path = Path();
    final last = (steps * progress).round();
    for (var i = 0; i <= last; i++) {
      final t = i / steps;
      final x = t * size.width;
      final y = mid - _y(t) * amp;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_BrainLinePainter old) =>
      old.progress != progress || old.color != color || old.seed != seed || old.strokeWidth != strokeWidth;
}

/// หัวข้อของกลุ่มเนื้อหา: ตัวหนังสือเล็กสีรอง เว้นระยะบนมากกว่าล่าง เพื่อจับกลุ่มกับเนื้อหาข้างล่าง
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.ibmPlexSansThai(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
