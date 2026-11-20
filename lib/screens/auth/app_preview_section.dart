import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/brainwave_scene.dart';

/// ภาพตัวอย่างหน้าจอแอปในกรอบมือถือ ใต้ฉากหลักของหน้าแรก แบบแกลเลอรีที่ขยับตามผู้ใช้
///
/// - เลื่อนมาถึง: มือถือลอยขึ้นมาทีละเครื่อง จากเบลอเป็นคมชัด
/// - ระหว่างดู: มือถือแต่ละเครื่องลอยขึ้นลงช้า ๆ คนละจังหวะ
/// - จอกว้าง: มือถือเอียงตามเมาส์แบบ 3 มิติ (แต่ละเครื่องลึกไม่เท่ากัน) เครื่องที่ชี้อยู่ยกขึ้นและขยาย เครื่องอื่นจางลง
/// - จอแคบ: ปัดดูทีละเครื่องในแนวนอน (นิ้ว เมาส์ หรือ trackpad)
class AppPreviewSection extends StatefulWidget {
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
  State<AppPreviewSection> createState() => _AppPreviewSectionState();
}

class _AppPreviewSectionState extends State<AppPreviewSection>
    with TickerProviderStateMixin {
  /// มือถือลอยขึ้นมาทีละเครื่องเมื่อเลื่อนมาถึง
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// จังหวะลอยขึ้นลง วนตลอด (และเป็นตัวเดินเฟรมให้การเอียงตามเมาส์ไหลลื่น)
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  /// ความลึกของแต่ละเครื่อง: เลขมากขยับตามเมาส์มาก ดูเหมือนอยู่ใกล้กว่า
  static const _depth = [1.0, 0.7, 1.15, 0.85];

  /// ตำแหน่งเมาส์ในแกลเลอรี -1..1 (ค่าเป้าหมาย) และค่าที่ค่อย ๆ ไล่ตาม
  Offset _pointerTarget = Offset.zero;
  Offset _pointer = Offset.zero;

  int? _hovered;
  final _lift = List<double>.filled(AppPreviewSection.screens.length, 0);
  final _dim = List<double>.filled(AppPreviewSection.screens.length, 0);

  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scroll) {
      _scroll?.removeListener(_revealWhenVisible);
      _scroll = position?..addListener(_revealWhenVisible);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealWhenVisible());
  }

  @override
  void dispose() {
    _scroll?.removeListener(_revealWhenVisible);
    _reveal.dispose();
    _float.dispose();
    super.dispose();
  }

  /// เริ่มให้มือถือลอยขึ้นมาเมื่อขอบบนของส่วนนี้เข้ามาในจอ (ประมาณ 80% ของความสูงจอ)
  void _revealWhenVisible() {
    if (!mounted || _reveal.status != AnimationStatus.dismissed) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.8) _reveal.forward();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.ibmPlexSansThai(
      fontSize: widget.wide ? 34 : 26,
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
          padding: EdgeInsets.only(
            top: widget.wide ? 72 : 48,
            bottom: widget.wide ? 96 : 56,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gutter),
                child: Semantics(
                  header: true,
                  child: Text('ดูหน้าตาแอป', style: titleStyle),
                ),
              ),
              SizedBox(height: widget.wide ? 40 : 28),
              widget.wide ? _gallery() : _carousel(context),
            ],
          ),
        ),
      ],
    );
  }

  /// จอกว้าง: มือถือ 4 เครื่องเรียงสูงต่ำสลับ เอียงตามเมาส์
  Widget _gallery() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 32.0;
        final phoneW =
            ((constraints.maxWidth - widget.gutter * 2 - gap * 3) / 4).clamp(
              160.0,
              260.0,
            );
        final galleryH = phoneW / AppPreviewSection.phoneAspect + 120;
        return MouseRegion(
          onHover: (event) {
            _pointerTarget = Offset(
              (event.localPosition.dx / constraints.maxWidth * 2 - 1).clamp(
                -1.0,
                1.0,
              ),
              (event.localPosition.dy / galleryH * 2 - 1).clamp(-1.0, 1.0),
            );
          },
          onExit: (_) {
            _pointerTarget = Offset.zero;
            _hovered = null;
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_reveal, _float]),
            builder: (context, _) {
              _pointer = Offset.lerp(_pointer, _pointerTarget, 0.08)!;
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, s) in AppPreviewSection.screens.indexed) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Padding(
                        padding: EdgeInsets.only(top: s.$4),
                        child: MouseRegion(
                          onEnter: (_) => _hovered = i,
                          onExit: (_) {
                            if (_hovered == i) _hovered = null;
                          },
                          child: _moving(i, phoneW, interactive: true),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// จอแคบ: ปัดดูแนวนอน มือถือยังลอยขึ้นมาและขยับขึ้นลง แต่ไม่เอียงตามเมาส์
  Widget _carousel(BuildContext context) {
    const phoneW = 220.0;
    return SizedBox(
      height: phoneW / AppPreviewSection.phoneAspect + 72,
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
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: widget.gutter),
          itemCount: AppPreviewSection.screens.length,
          separatorBuilder: (_, _) => const SizedBox(width: 18),
          itemBuilder: (context, i) => AnimatedBuilder(
            animation: Listenable.merge([_reveal, _float]),
            builder: (context, _) => _moving(i, phoneW, interactive: false),
          ),
        ),
      ),
    );
  }

  /// มือถือหนึ่งเครื่องพร้อมการเคลื่อนไหวทั้งหมด (คำนวณใหม่ทุกเฟรม)
  Widget _moving(int i, double width, {required bool interactive}) {
    final s = AppPreviewSection.screens[i];

    // ลอยขึ้นมาทีละเครื่อง ห่างกันเล็กน้อย
    final start = i * 0.13;
    final raw = ((_reveal.value - start) / 0.55).clamp(0.0, 1.0);
    final appear = Curves.easeOutCubic.transform(raw);

    // ลอยขึ้นลงคนละจังหวะ
    final bob = math.sin((_float.value + i * 0.23) * 2 * math.pi) * 7;

    // ค่อย ๆ ยก/จางตามเมาส์ ไม่กระโดด
    final hovered = interactive && _hovered == i;
    final dimmed = interactive && _hovered != null && !hovered;
    _lift[i] += ((hovered ? 1.0 : 0.0) - _lift[i]) * 0.15;
    _dim[i] += ((dimmed ? 1.0 : 0.0) - _dim[i]) * 0.15;

    final d = _depth[i];
    final tilt = interactive ? _pointer : Offset.zero;
    final spinIn = (1 - appear) * 0.12 * (i.isEven ? -1 : 1);
    final scale = 1 + _lift[i] * 0.05;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(
        tilt.dx * 16 * d,
        (1 - appear) * 140 + bob - _lift[i] * 16,
        0,
        1,
      )
      ..rotateX(-tilt.dy * 0.10 * d)
      ..rotateY(tilt.dx * 0.16 * d)
      ..rotateZ(spinIn)
      ..scaleByDouble(scale, scale, 1, 1);

    Widget phone = _Phone(
      image: s.$1,
      title: s.$2,
      caption: s.$3,
      width: width,
      glow: _lift[i],
    );
    final blur = (1 - appear) * 10;
    if (blur > 0.1) {
      phone = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: phone,
      );
    }

    return Opacity(
      opacity: (appear * (1 - _dim[i] * 0.4)).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: phone,
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  final String image;
  final String title;
  final String caption;
  final double width;

  /// 0..1 แสงเรืองใต้เครื่องที่เมาส์ชี้อยู่
  final double glow;

  const _Phone({
    required this.image,
    required this.title,
    required this.caption,
    required this.width,
    this.glow = 0,
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
                  color: HeroPalette.alpha.withValues(
                    alpha: 0.18 + glow * 0.22,
                  ),
                  blurRadius: 40 + glow * 24,
                  offset: Offset(0, 16 + glow * 12),
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
