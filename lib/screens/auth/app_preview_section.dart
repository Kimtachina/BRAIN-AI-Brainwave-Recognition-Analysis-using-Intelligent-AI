import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/brainwave_scene.dart';

/// ภาพตัวอย่างหน้าจอแอปในกรอบมือถือ ใต้ฉากหลักของหน้าแรก
/// จอกว้าง: มือถือ 4 เครื่องเรียงกันแบบสูงต่ำสลับ / จอแคบ: ปัดดูทีละเครื่องในแนวนอน
class AppPreviewSection extends StatelessWidget {
  final double gutter;
  final bool wide;

  const AppPreviewSection({
    super.key,
    required this.gutter,
    required this.wide,
  });

  /// ภาพมือถือ, ชื่อหน้า, คำอธิบายสั้น, ระยะเลื่อนลงบนจอกว้าง (ให้เรียงสูงต่ำสลับกัน)
  static const screens = [
    (
      'assets/images/app_preview_today.webp',
      'วันนี้',
      'สถานะ Muse และผลล่าสุด',
      40.0,
    ),
    (
      'assets/images/app_preview_bands.webp',
      'คลื่นสมองตอนนี้',
      'กราฟสัดส่วนคลื่น 60 วินาที',
      0.0,
    ),
    (
      'assets/images/app_preview_phq9.webp',
      'แบบประเมิน PHQ-9',
      'ประเมินความเครียด 9 ข้อ',
      56.0,
    ),
    (
      'assets/images/app_preview_behind.webp',
      'เบื้องหลัง',
      'ขั้นตอนเตรียมสัญญาณ EEG',
      16.0,
    ),
  ];

  /// สัดส่วนกว้าง/สูงของภาพมือถือ (540 x 1158)
  static const phoneAspect = 540 / 1158;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.ibmPlexSansThai(
      fontSize: wide ? 34 : 26,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: HeroPalette.text,
    );

    // พื้นหลังชุดเดียวกับฉากด้านบน (ม่วงเข้มมีแสงเรือง) ขอบบนไล่จากสีมืดของท้ายฉาก จึงต่อกันเนียนไม่เห็นรอยต่อ
    return Stack(
      children: [
        const Positioned.fill(child: HeroBackdrop(horizon: 0.55)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HeroPalette.night,
                  HeroPalette.night.withValues(alpha: 0),
                ],
                stops: const [0, 0.22],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: wide ? 72 : 48, bottom: wide ? 96 : 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Semantics(
                  header: true,
                  child: Text('ดูหน้าตาแอป', style: titleStyle),
                ),
              ),
              SizedBox(height: wide ? 40 : 28),
              wide ? _row(context) : _carousel(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 32.0;
        final phoneW = ((constraints.maxWidth - gutter * 2 - gap * 3) / 4)
            .clamp(160.0, 260.0);
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in screens.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                Padding(
                  padding: EdgeInsets.only(top: s.$4),
                  child: _Phone(
                    image: s.$1,
                    title: s.$2,
                    caption: s.$3,
                    width: phoneW,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _carousel(BuildContext context) {
    const phoneW = 220.0;
    return SizedBox(
      height: phoneW / phoneAspect + 72,
      // ให้ลากด้วยเมาส์ได้ด้วย (เว็บบนจอแคบ) ไม่ใช่แค่ปัดด้วยนิ้ว
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          itemCount: screens.length,
          separatorBuilder: (_, _) => const SizedBox(width: 18),
          itemBuilder: (context, i) {
            final s = screens[i];
            return _Phone(
              image: s.$1,
              title: s.$2,
              caption: s.$3,
              width: phoneW,
            );
          },
        ),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  final String image;
  final String title;
  final String caption;
  final double width;

  const _Phone({
    required this.image,
    required this.title,
    required this.caption,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.15),
              boxShadow: [
                BoxShadow(
                  color: HeroPalette.alpha.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Image.asset(
              image,
              width: width,
              height: width / AppPreviewSection.phoneAspect,
              fit: BoxFit.contain,
              semanticLabel: 'ตัวอย่างหน้า$title บนมือถือ',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: HeroPalette.text,
            ),
          ),
          Text(
            caption,
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 13,
              color: HeroPalette.text.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}
