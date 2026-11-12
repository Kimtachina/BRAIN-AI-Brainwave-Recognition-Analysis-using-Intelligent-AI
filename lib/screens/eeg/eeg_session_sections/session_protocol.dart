part of '../eeg_session_screen.dart';

// โปรโตคอลการเก็บข้อมูล EEG: รายการเซสชัน (อารมณ์ กิจกรรม และระยะเวลา)

// ═══════════════════════════════════════════════════════════════════
// Protocol Duration Justification (Research-Backed)
// ─────────────────────────────────────────────────────────────────
// • DEAP Dataset (Koelstra et al., 2012): 60s per emotion trial
//   → 32 participants × 40 trials × 60s = gold-standard protocol
// • Optimal Time Window: 2-15s segments for feature extraction
//   (García-Martínez et al., 2019, RMIB)
// • 60s artifact-free data = stable PSD/DE features (Zheng & Lu, 2015)
// • 90s provides ~50% margin for artifact rejection
// • Sampling @ 1s interval → 60-90 data points per session
//   (vs. 12-36 points @ 5s interval previously)
// • Consumer-grade Muse: alpha power reliable at 60s+
//   (Krigolson et al., 2017)
// ═══════════════════════════════════════════════════════════════════
const List<Map<String, dynamic>> _sessions = [
  {
    'name': 'Baseline',
    'emotion': 'neutral',
    'activity': 'baseline',
    'duration': 60, // DEAP: 3-60s baseline; 60s = standard
    'icon': Icons.circle_outlined,
    'color': Color(0xFF9E9E9E),
    'gradient': [Color(0xFF757575), Color(0xFF9E9E9E)],
    'description': 'นั่งนิ่ง หลับตา 1 นาที เก็บค่า EEG พื้นฐาน (DEAP Protocol)',
    'instruction': 'จ้องมองจุดตรงกลางหน้าจอ หายใจปกติ',
  },
  {
    'name': 'ผ่อนคลาย',
    'emotion': 'calm',
    'activity': 'breathing',
    'duration': 90, // 60s DEAP + 30s margin for artifact rejection
    'icon': Icons.self_improvement_rounded,
    'color': Color(0xFF4CAF50),
    'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
    'description': 'หายใจลึกๆ 1.5 นาที ตามจังหวะ 4-7-8 เพื่อเพิ่ม Alpha wave',
    'instruction': 'หายใจเข้า 4 วิ → กลั้น 7 วิ → ออก 8 วิ',
  },
  {
    'name': 'มีความสุข',
    'emotion': 'happy',
    'activity': 'positive_recall',
    'duration': 90, // 60s DEAP + 30s margin for artifact rejection
    'icon': Icons.favorite_rounded,
    'color': Color(0xFFFFC107),
    'gradient': [Color(0xFFf7971e), Color(0xFFffd200)],
    'description': 'นึกถึงความทรงจำที่มีความสุข 1.5 นาที',
    'instruction': 'หลับตาแล้วนึกถึงเหตุการณ์ที่ทำให้มีความสุขที่สุด',
  },
  {
    'name': 'เครียด (เบา)',
    'emotion': 'stressed',
    'activity': 'mental_arithmetic',
    'duration': 90, // Trier Social Stress Test adapted: 60-120s
    'icon': Icons.calculate_rounded,
    'color': Color(0xFFF44336),
    'gradient': [Color(0xFFeb3349), Color(0xFFf45c43)],
    'description': 'นับถอยหลัง 1.5 นาที จาก 1000 ลบ 7 กระตุ้น Beta wave',
    'instruction': 'นับ: 1000, 993, 986, 979... ให้เร็วที่สุด',
  },
  {
    'name': 'เศร้า',
    'emotion': 'sad',
    'activity': 'sad_recall',
    'duration': 90, // 60s DEAP + 30s margin for artifact rejection
    'icon': Icons.water_drop_rounded,
    'color': Color(0xFF2196F3),
    'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    'description': 'นึกถึงเรื่องราวที่ทำให้เศร้าเล็กน้อย 1.5 นาที',
    'instruction': 'หลับตาแล้วนึกถึงช่วงเวลาที่ทำให้เศร้าใจ',
  },
  {
    'name': 'สมาธิสูง',
    'emotion': 'focused',
    'activity': 'focus_counting',
    'duration': 90, // Consistent 90s across all emotion sessions
    'icon': Icons.psychology_rounded,
    'color': Color(0xFF9C27B0),
    'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    'description': 'นับลมหายใจ 1.5 นาที จาก 1-10 แล้วเริ่มใหม่ กระตุ้น Gamma',
    'instruction': 'นับลมหายใจ 1...2...3... ถึง 10 แล้วเริ่มใหม่',
  },
];
