import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ชุดสี "Night" — ฉากกลางคืนเดียวกับหน้าแรก
/// พื้นม่วงเกือบดำ ตัวหนังสือขาวอมม่วง สีหลักม่วงตามคลื่น Alpha (ภาวะผ่อนคลาย)
/// สีรองเขียวอมฟ้าตามคลื่น Theta ใช้กับสถานะดี/ปกติ สีอำพันใช้เตือน
/// ปุ่มหลักเป็นแคปซูลสีขาวตัวหนังสือเข้ม ไม่มีเงา แยกชั้นด้วยเส้นขอบบางแทน
class AppColors {
  // ฉากกลางคืน: ใช้วาดพื้นหลังและเส้นคลื่น
  static const Color night = Color(0xFF0B0A14); // ล่างสุดของฉาก ตัวหนังสือบนปุ่มขาว
  static const Color nightTop = Color(0xFF181530); // บนสุดของฉาก
  static const Color theta = Color(0xFF6FD1C1);
  static const Color alphaWave = Color(0xFFA394F7);
  static const Color glow = Color(0xFFE9C48A); // แสงอุ่นตรงขอบฟ้า

  // สีหลัก: ลิงก์ ตัวเลือกที่เลือกอยู่ ไอคอนเด่น
  static const Color primary = Color(0xFF8E80F5);
  static const Color primaryDeep = Color(0xFFB9AEFB); // ข้อความบนพื้นสีหลักอ่อน (บนพื้นมืดจึงสว่างกว่าสีหลัก)
  static const Color primarySoft = Color(0xFF26214A); // พื้นของสิ่งที่เลือกอยู่

  // สีรอง: สถานะปกติ เชื่อมต่อแล้ว สำเร็จ
  static const Color secondary = Color(0xFF4FBFAE);
  static const Color secondarySoft = Color(0xFF123330);

  // พื้นผิว
  static const Color paper = Color(0xFF0E0C1A); // พื้นหลังทั้งแอป
  static const Color surface = Color(0xFF17152A); // แผ่นเนื้อหา
  static const Color line = Color(0xFF2C2945); // เส้นขอบและเส้นคั่น

  // ตัวหนังสือ
  static const Color ink = Color(0xFFF4F2FA); // หลัก
  static const Color inkSoft = Color(0xFFB7B2CB); // รอง
  static const Color inkFaint = Color(0xFF8A85A3); // คำอธิบาย ตัวยึดตำแหน่ง

  // สถานะ
  static const Color warning = Color(0xFFE9B04F);
  static const Color error = Color(0xFFE46A6A);
  static const Color orange = Color(0xFFE8894A);

  // ชื่อเดิมที่กราฟคลื่นสดและช่องแชตยังเรียกใช้
  static const Color deepSpaceBlue = surface;
  static const Color electricCyan = primary;
  static const Color neonGreen = secondary;
}

/// เหลือไล่สีไว้เฉพาะจุดที่โค้ดเดิมยังเรียกใช้ ทุกตัวไล่แค่ในโทนเดียวกัน ไม่ใช่ลายประดับ
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, Color(0xFF6656D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient memoryGame = LinearGradient(
    colors: [Color(0xFF4A4566), Color(0xFF26223A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient triviaGame = LinearGradient(
    colors: [Color(0xFF2F8F80), Color(0xFF1B5A51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// พื้นหลังของฉาก ไล่จากม่วงเข้มด้านบนลงไปเกือบดำ
  static const LinearGradient glassBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.nightTop, AppColors.paper],
  );
}

/// จังหวะการเคลื่อนไหว (ตามแนวทางของ Emil Kowalski)
/// ease-out แบบแรงสำหรับสิ่งที่ตอบสนองการกด, ease-in-out สำหรับของที่เคลื่อนบนจอ, ไม่ใช้ ease-in
class AppMotion {
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const Duration press = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration reveal = Duration(milliseconds: 1100);

  /// ผู้ใช้ตั้งเครื่องให้ลดการเคลื่อนไหวไว้หรือไม่
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// ขนาดตัวอักษร: หัวข้อใหญ่บีบระยะตัวอักษรเข้า ตัวเล็กปล่อยระยะปกติ ระยะบรรทัดหลวมขึ้นเมื่อตัวเล็กลง
class AppTextStyles {
  static TextStyle get display => GoogleFonts.ibmPlexSansThai(
        fontSize: 34,
        height: 1.18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: AppColors.ink,
      );

  static TextStyle get title => GoogleFonts.ibmPlexSansThai(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get heading => GoogleFonts.ibmPlexSansThai(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.ibmPlexSansThai(
        fontSize: 15,
        height: 1.6,
        color: AppColors.inkSoft,
      );

  static TextStyle get small => GoogleFonts.ibmPlexSansThai(
        fontSize: 13,
        height: 1.5,
        color: AppColors.inkSoft,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexSansThai(
        fontSize: 12,
        height: 1.45,
        letterSpacing: 0.1,
        color: AppColors.inkFaint,
      );

  /// ตัวเลขผลวัด: ตัวเลขกว้างเท่ากันทุกตัว ค่าเปลี่ยนแล้วไม่สั่น
  static TextStyle get metric => GoogleFonts.ibmPlexSansThai(
        fontSize: 44,
        height: 1.0,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ชื่อเดิม ใช้ในบางหน้า
  static TextStyle get heroTitle => title.copyWith(color: AppColors.primary);
}

/// รัศมีมุม: แบ่งตามลำดับชั้น ไม่ใช้ค่าเดียวทุกอย่าง
class AppRadius {
  static const double control = 10; // ช่องกรอก ปุ่ม
  static const double card = 14; // แผ่นเนื้อหา
  static const double sheet = 20; // แผ่นที่เลื่อนขึ้นจากล่าง หน้าต่างกลางจอ
}

class AppTheme {
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    final base = GoogleFonts.ibmPlexSansThaiTextTheme(ThemeData(brightness: Brightness.dark).textTheme);
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));
    // ปุ่มเป็นแคปซูลแบบหน้าแรก
    const pillShape = StadiumBorder();
    final buttonText = GoogleFonts.ibmPlexSansThai(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0);

    OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.night,
        onSecondary: AppColors.night,
        surfaceContainerHighest: AppColors.surface,
        surfaceContainerHigh: AppColors.surface,
        surfaceContainer: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      // กดแล้วไม่มีระลอกน้ำกระจายทั้งปุ่ม ใช้สีทึบขึ้นเล็กน้อยแทน
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.primary.withValues(alpha: 0.10),
      hoverColor: AppColors.primary.withValues(alpha: 0.08),
      dividerColor: AppColors.line,
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      textTheme: base
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.55, color: AppColors.ink),
            bodySmall: base.bodySmall?.copyWith(fontSize: 13, height: 1.5, color: AppColors.inkSoft),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: GoogleFonts.ibmPlexSansThai(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.night,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.inkFaint,
          elevation: 0,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pillShape,
          textStyle: buttonText,
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(AppColors.night.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.night,
          minimumSize: const Size(64, 50),
          shape: pillShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.28)),
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pillShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: controlShape,
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: outline(AppColors.line),
        enabledBorder: outline(AppColors.line),
        disabledBorder: outline(AppColors.line),
        focusedBorder: outline(AppColors.primary, 1.6),
        errorBorder: outline(AppColors.error),
        focusedErrorBorder: outline(AppColors.error, 1.6),
        prefixIconColor: AppColors.inkFaint,
        suffixIconColor: AppColors.inkFaint,
        hintStyle: GoogleFonts.ibmPlexSansThai(color: AppColors.inkFaint, fontSize: 15),
        labelStyle: GoogleFonts.ibmPlexSansThai(color: AppColors.inkSoft),
        errorStyle: GoogleFonts.ibmPlexSansThai(color: AppColors.error, fontSize: 12.5),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.inkFaint, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        titleTextStyle: GoogleFonts.ibmPlexSansThai(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink),
        contentTextStyle: GoogleFonts.ibmPlexSansThai(fontSize: 15, height: 1.55, color: AppColors.inkSoft),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        backgroundColor: Colors.white,
        contentTextStyle: GoogleFonts.ibmPlexSansThai(color: AppColors.night, fontSize: 14),
        actionTextColor: AppColors.night,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.secondary : AppColors.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.ibmPlexSansThai(fontSize: 13, color: AppColors.ink),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.inkFaint,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.line,
        labelStyle: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.inkFaint,
        selectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// เดิมเป็นเงาแบบกระจก ตอนนี้ระบบไม่ใช้เงาแล้ว
  static List<BoxShadow> get glassShadow => const [];

  /// แผ่นเนื้อหาเรียบ: พื้นทึบ เส้นขอบบาง มุม 14 ไม่มีเงา ไม่เบลอ
  /// ถ้าส่งสีมา (ไม่ใช่ขาว) จะเป็นแผ่นสีอ่อนของสีนั้น ใช้กับกล่องเตือนหรือกล่องสถานะ
  /// รับพารามิเตอร์ชื่อเดิมไว้ เพื่อให้ทุกหน้าที่เคยใช้กระจกเปลี่ยนตามได้ทันที
  static BoxDecoration glassDecoration({
    BorderRadiusGeometry? borderRadius,
    Color? color,
    double opacity = 0.65,
    Color? borderColor,
  }) {
    final isPlain = color == null || color == Colors.white || color.toARGB32() == 0xFFFFFFFF;
    final fill = isPlain
        ? AppColors.surface
        : Color.alphaBlend(color.withValues(alpha: (opacity * 0.9).clamp(0.05, 0.14)), AppColors.surface);
    final edge = isPlain ? AppColors.line : Color.alphaBlend(color.withValues(alpha: 0.28), AppColors.surface);
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: borderColor == null ? edge : Color.alphaBlend(edge, AppColors.surface)),
    );
  }

  /// แผ่นเนื้อหามาตรฐาน
  static BoxDecoration panel({Color color = AppColors.surface, double radius = AppRadius.card}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      );
}
