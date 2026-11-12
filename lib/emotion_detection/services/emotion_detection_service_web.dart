import 'package:flutter/foundation.dart';
import '../models/emotion_result.dart';
import '../models/emotion_type.dart';
import 'emotion_heuristics.dart';

/// Web build: tflite_flutter ไม่รองรับเว็บ จึงใช้สูตรประเมินจากสัดส่วนคลื่นสมอง
/// ชุดเดียวกับที่มือถือใช้เป็นตัวสำรอง (emotion_heuristics.dart)
/// ผลลัพธ์จึงใช้ป้ายเดียวกับมือถือ: 'tflite' → calm/neutral/focused, 'tsception' → stressed/happy/calm/sad
class EmotionDetectionService {
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;
  String? get lastError => null;

  Future<void> loadModel() async {
    _isModelLoaded = true;
    debugPrint('✅ Emotion Detection (web: heuristic mode, no TFLite)');
  }

  Future<Map<String, EmotionResult>> detectFromEEG(Map<String, double> eegData) async {
    return {
      'tflite': heuristicMentalState(eegData),
      'tsception': heuristicEmotion(eegData),
    };
  }

  Future<EmotionResult> detectFromFace(dynamic imageData) async {
    return EmotionResult(
      emotionType: EmotionType.neutral.name,
      confidence: 0.0,
      timestamp: DateTime.now(),
      allScores: {},
    );
  }

  Future<EmotionResult> detectFromVoice(List<double> audioFeatures) async {
    return EmotionResult(
      emotionType: EmotionType.neutral.name,
      confidence: 0.0,
      timestamp: DateTime.now(),
      allScores: {},
    );
  }

  void dispose() {
    _isModelLoaded = false;
  }
}
