import '../models/emotion_result.dart';

// สูตรประเมินจากสัดส่วนคลื่นสมอง ใช้ร่วมกันทั้งมือถือและเว็บ
// - มือถือ: ใช้เป็นตัวสำรองเมื่อโหลดโมเดล TFLite ไม่ได้
// - เว็บ: ใช้เป็นหลัก เพราะ tflite_flutter ไม่รองรับเว็บ
// ป้ายผลลัพธ์ตรงกับที่โมเดล TFLite ให้หลัง _mapModelLabel เพื่อให้ทั้งสองแพลตฟอร์มแสดงผลชุดเดียวกัน

/// 3 สภาวะ (แทนโมเดล emotion_model.tflite): calm / neutral / focused
EmotionResult heuristicMentalState(Map<String, double> eegData) {
  double alpha = eegData['alpha'] ?? 0;
  double beta = eegData['beta'] ?? 0;
  double theta = eegData['theta'] ?? 0;
  double delta = eegData['delta'] ?? 0;
  double gamma = eegData['gamma'] ?? 0;

  double total = alpha + beta + theta + delta + gamma;
  if (total == 0) total = 1;

  double aPct = alpha / total;
  double bPct = beta / total;
  double tPct = theta / total;
  double dPct = delta / total;
  double gPct = gamma / total;

  Map<String, double> scores = {};

  // Relaxed: Alpha สูง + Beta ต่ำ → สงบผ่อนคลาย
  scores['calm'] =
      (aPct * 1.5 + tPct * 0.3 + (1 - bPct) * 0.5).clamp(0.0, 1.0);

  // Neutral: สมดุลทุก band → สภาวะปกติ
  double balance = 1.0 -
      ((aPct - 0.2).abs() +
          (bPct - 0.2).abs() +
          (tPct - 0.2).abs() +
          (dPct - 0.2).abs());
  scores['neutral'] = balance.clamp(0.0, 1.0);

  // Concentrating: Beta + Gamma สูง → มีสมาธิ/ตื่นตัว
  scores['focused'] =
      (bPct * 1.3 + gPct * 0.8 + (1 - dPct) * 0.3).clamp(0.0, 1.0);

  double maxScore = scores.values.reduce((a, b) => a > b ? a : b);
  if (maxScore > 0) {
    scores = scores.map((k, v) =>
        MapEntry(k, double.parse((v / maxScore).toStringAsFixed(4))));
  }

  String emotionType =
      scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  return EmotionResult(
    emotionType: emotionType,
    confidence: scores[emotionType] ?? 0.0,
    timestamp: DateTime.now(),
    allScores: scores,
  );
}

/// 4 อารมณ์ (แทนโมเดล Tsception.tflite): stressed / happy / calm / sad
EmotionResult heuristicEmotion(Map<String, double> eegData) {
  double alpha = eegData['alpha'] ?? 0;
  double beta = eegData['beta'] ?? 0;
  double theta = eegData['theta'] ?? 0;
  double delta = eegData['delta'] ?? 0;
  double gamma = eegData['gamma'] ?? 0;

  double total = alpha + beta + theta + delta + gamma;
  if (total == 0) total = 1;

  double aPct = alpha / total;
  double bPct = beta / total;
  double tPct = theta / total;
  double dPct = delta / total;
  double gPct = gamma / total;

  Map<String, double> scores = {};

  // Angry/Fear -> Stressed
  scores['stressed'] = (bPct * 1.0 + gPct * 0.8).clamp(0.0, 1.0);
  // Happy
  scores['happy'] = (aPct * 1.2 + tPct * 0.4).clamp(0.0, 1.0);
  // Relaxed -> Calm
  scores['calm'] = (aPct * 1.5 + (1 - bPct) * 0.5).clamp(0.0, 1.0);
  // Sad
  scores['sad'] = (tPct * 1.0 + dPct * 0.8).clamp(0.0, 1.0);

  double maxScore = scores.values.reduce((a, b) => a > b ? a : b);
  if (maxScore > 0) {
    scores = scores.map((k, v) =>
        MapEntry(k, double.parse((v / maxScore).toStringAsFixed(4))));
  }

  String emotionType =
      scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  return EmotionResult(
    emotionType: emotionType,
    confidence: scores[emotionType] ?? 0.0,
    timestamp: DateTime.now(),
    allScores: scores,
  );
}
