import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// สีของฉากกลางคืน ชี้ไปที่ชุดสีกลางของแอป เพื่อให้ทุกหน้าใช้สีชุดเดียวกัน
class HeroPalette {
  static const Color night = AppColors.night;
  static const Color nightTop = AppColors.nightTop;
  static const Color theta = AppColors.theta;
  static const Color alpha = AppColors.alphaWave;
  static const Color glow = AppColors.glow;
  static const Color text = AppColors.ink;
}

/// พื้นหลัง: ไล่สีจากบนลงล่าง มีแสงอุ่นตรงขอบฟ้าและแสงเขียวจาง ๆ มุมซ้ายบน
class HeroBackdrop extends StatelessWidget {
  final double horizon; // ตำแหน่งขอบฟ้า เป็นสัดส่วนของความสูง

  const HeroBackdrop({super.key, required this.horizon});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: CustomPaint(painter: _BackdropPainter(horizon)));
  }
}

class _BackdropPainter extends CustomPainter {
  final double horizon;

  _BackdropPainter(this.horizon);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HeroPalette.nightTop, HeroPalette.night],
        ).createShader(rect),
    );

    final longSide = math.max(size.width, size.height);
    final horizonCenter = Offset(size.width / 2, size.height * horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            HeroPalette.glow.withValues(alpha: 0.16),
            HeroPalette.alpha.withValues(alpha: 0.10),
            HeroPalette.alpha.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: horizonCenter, radius: longSide * 0.55)),
    );

    final corner = Offset(size.width * 0.12, size.height * 0.08);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [HeroPalette.theta.withValues(alpha: 0.09), HeroPalette.theta.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: corner, radius: longSide * 0.5)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.horizon != horizon;
}

/// คำใหญ่โปร่งแสงด้านหลังเส้นคลื่น (แทนคำว่า "Nature" ในภาพต้นแบบ)
class GiantWord extends StatelessWidget {
  final String text;
  final double fontSize;

  const GiantWord({super.key, required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: 0.82,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [HeroPalette.theta, HeroPalette.alpha, HeroPalette.glow],
            stops: [0.05, 0.55, 1],
          ).createShader(bounds),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w300,
              letterSpacing: -fontSize * 0.03,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// เส้นคลื่นสมองหลายเส้นซ้อนกันแบบมีระยะลึก เส้นหลังเล็กและจาง เส้นหน้าใหญ่และสว่าง
/// ตรงกลางนูนเป็นสองลูกเหมือนสมองสองซีก แต่ละเส้นถมพื้นด้านล่างไว้ จึงบังเส้นที่อยู่ข้างหลังและคำใหญ่
class BrainwaveField extends StatefulWidget {
  final double horizon; // ตำแหน่งเส้นหลังสุด เป็นสัดส่วนของความสูง

  const BrainwaveField({super.key, required this.horizon});

  @override
  State<BrainwaveField> createState() => _BrainwaveFieldState();
}

class _BrainwaveFieldState extends State<BrainwaveField> with TickerProviderStateMixin {
  // คลื่นไหลช้า ๆ วนครบรอบใน 24 วินาที ความถี่ทุกตัวเป็นจำนวนเต็มรอบ จึงต่อกันได้ไม่สะดุด
  late final AnimationController _flow = AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _flow.stop();
      _reveal.value = 1;
    } else {
      if (!_flow.isAnimating) _flow.repeat();
      if (_reveal.value == 0 && !_reveal.isAnimating) _reveal.forward();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_flow, _reveal]),
          builder: (context, _) => CustomPaint(
            painter: _RidgePainter(
              phase: _flow.value,
              reveal: AppMotion.easeOut.transform(_reveal.value),
              horizon: widget.horizon,
            ),
          ),
        ),
      ),
    );
  }
}

class _RidgePainter extends CustomPainter {
  final double phase; // 0..1 วนรอบ
  final double reveal; // 0..1 ตอนเปิดหน้า เส้นค่อย ๆ ยกตัวขึ้น
  final double horizon;

  _RidgePainter({required this.phase, required this.reveal, required this.horizon});

  static const int _lines = 26;
  static const int _samples = 150;

  static double _gauss(double u, double center, double width) =>
      math.exp(-math.pow((u - center) / width, 2).toDouble());

  /// ส่วนผสมของ 4 ย่านคลื่น: Delta ช้าและกว้าง, Theta, Alpha เด่นตรงกลาง, Beta เร็วและเล็ก
  double _signal(double u, int line) {
    final p = phase * 2 * math.pi;
    final s = line * 0.83;
    final delta = math.sin(u * 2 * math.pi * 1.6 - p + s) * 0.35;
    final theta = math.sin(u * 2 * math.pi * 4.4 - p * 2 + s * 1.7) * 0.25;
    final alpha = math.sin(u * 2 * math.pi * 10.5 - p * 4 + s * 2.3) * (0.08 + 0.35 * _gauss(u, 0.5, 0.16));
    final beta = math.sin(u * 2 * math.pi * 23 - p * 7 + s * 3.1) * 0.06;
    return delta + theta + alpha + beta;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h * horizon;
    final bottom = h * 1.02;
    final cx = w / 2;
    final halfSpan = math.max(w, 420.0) * 0.5;
    final ampMax = h * 0.3 * reveal;

    for (var i = 0; i < _lines; i++) {
      final z = i / (_lines - 1); // 0 = หลังสุด, 1 = หน้าสุด
      final base = top + (bottom - top) * math.pow(z, 1.65);
      final span = halfSpan * (0.55 + 0.75 * z);
      // เส้นกลาง ๆ สูงที่สุด เส้นหน้าสุดเตี้ยลง พื้นใต้หัวเรื่องจึงไม่รก
      final amp = ampMax * (0.15 + 0.85 * math.pow(z, 1.2)) * (1 - 0.55 * math.pow(z, 4));
      final left = cx - span;
      final right = cx + span;

      final line = Path();
      for (var j = 0; j <= _samples; j++) {
        final u = j / _samples;
        // สองลูกนูนซ้ายขวา เหมือนสมองสองซีก
        final env = math.min(1.0, 0.85 * (_gauss(u, 0.39, 0.13) + _gauss(u, 0.61, 0.13)));
        final lift = env * 0.9 + 0.1;
        final y = base - amp * (lift + _signal(u, i) * (0.18 + 0.32 * env));
        final x = left + (right - left) * u;
        if (j == 0) {
          line.moveTo(x, y);
        } else {
          line.lineTo(x, y);
        }
      }

      // ถมพื้นใต้เส้นเพื่อบังของที่อยู่ข้างหลัง ขอบซ้ายขวาค่อย ๆ จางเพื่อไม่ให้เห็นเป็นขั้นบันได
      final fill = Path.from(line)
        ..lineTo(right, h)
        ..lineTo(left, h)
        ..close();
      final cover = 0.35 + 0.6 * z;
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            colors: [
              HeroPalette.night.withValues(alpha: 0),
              HeroPalette.night.withValues(alpha: cover),
              HeroPalette.night.withValues(alpha: cover),
              HeroPalette.night.withValues(alpha: 0),
            ],
            stops: const [0, 0.22, 0.78, 1],
          ).createShader(Rect.fromLTRB(left, 0, right, h)),
      );

      final color = Color.lerp(HeroPalette.theta, HeroPalette.alpha, z)!;
      final strength = 0.35 + 0.6 * z;
      Shader fade(double opacity) => LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.3, 0.7, 1],
      ).createShader(Rect.fromLTRB(left, 0, right, h));

      if (z > 0.45) {
        canvas.drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
            ..shader = fade(strength * 0.45),
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 + 0.9 * z
          ..strokeJoin = StrokeJoin.round
          ..shader = fade(strength),
      );
    }
  }

  @override
  bool shouldRepaint(_RidgePainter old) => old.phase != phase || old.reveal != reveal || old.horizon != horizon;
}

/// เงามืดบนและล่างให้ตัวหนังสืออ่านง่ายเมื่อวางบนเส้นคลื่น
class HeroShade extends StatelessWidget {
  const HeroShade({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HeroPalette.night.withValues(alpha: 0.55),
              HeroPalette.night.withValues(alpha: 0),
              HeroPalette.night.withValues(alpha: 0),
              HeroPalette.night.withValues(alpha: 0.62),
              HeroPalette.night.withValues(alpha: 0.9),
            ],
            stops: const [0, 0.16, 0.48, 0.72, 1],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มแคปซูลสีขาวคู่กับวงกลมลูกศร กดได้ทั้งสองส่วนแล้วทำงานเหมือนกัน
class PillAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool compact;

  const PillAction({super.key, required this.label, required this.onPressed, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 48.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.night,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: size,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Icon(Icons.north_east_rounded, size: compact ? 16 : 18, color: AppColors.night),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ฉากหลังของหน้าเข้าสู่ระบบและสมัครสมาชิก: พื้นกลางคืน กับเส้นคลื่นสมองชุดเดียวกับหน้าแรกที่ครึ่งล่าง
/// จอแคบฟอร์มวางบนเส้นคลื่นตรง ๆ จึงหรี่เส้นลงให้อ่านตัวหนังสือง่าย
class AuthBackdrop extends StatelessWidget {
  final Widget child;

  const AuthBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Stack(
      children: [
        const Positioned.fill(child: HeroBackdrop(horizon: 0.62)),
        Positioned.fill(
          child: Opacity(opacity: wide ? 0.9 : 0.3, child: const BrainwaveField(horizon: 0.6)),
        ),
        const Positioned.fill(child: HeroShade()),
        Positioned.fill(child: child),
      ],
    );
  }
}
