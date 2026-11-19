import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'muse_ble_service.dart';

/// สัญญาณ EEG ดิบล่าสุดของเซนเซอร์ 4 จุด (ประมาณ 2 วินาทีต่อช่อง) ใช้ร่วมกันหลายหน้า
/// เช่น กราฟคลื่นดิบในหน้าวันนี้ และขั้นตอนเตรียมสัญญาณในหน้าเบื้องหลัง
///
/// ฟังสตรีมจาก Muse เมื่อเชื่อมต่อจริง หรือสร้างคลื่นจำลองเมื่ออยู่ในโหมดจำลอง
/// และล้างบัฟเฟอร์เมื่อตัดการเชื่อมต่อ
class EegLiveSignal extends ChangeNotifier {
  EegLiveSignal._() {
    _muse.addListener(_sync);
    _sync();
  }

  static final EegLiveSignal instance = EegLiveSignal._();

  static const _maxSamples = 500;

  final MuseService _muse = MuseService();

  final Map<String, List<double>> buffers = {
    'TP9': [],
    'AF7': [],
    'AF8': [],
    'TP10': [],
  };

  bool get hasData => buffers.values.any((b) => b.isNotEmpty);

  StreamSubscription<Map<String, List<double>>>? _rawSubscription;
  Timer? _simulationTimer;

  void _sync() {
    if (!_muse.isConnected) {
      _stopAll();
      if (hasData) {
        for (final b in buffers.values) {
          b.clear();
        }
        notifyListeners();
      }
      return;
    }
    if (_muse.isSimulating) {
      _rawSubscription?.cancel();
      _rawSubscription = null;
      if (_simulationTimer?.isActive != true) _startSimulation();
    } else {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      _rawSubscription ??= _muse.rawEegStream.listen(_onRaw);
    }
  }

  void _onRaw(Map<String, List<double>> channelData) {
    if (!_muse.isConnected || _muse.isSimulating) return;
    channelData.forEach((channel, samples) {
      final buffer = buffers[channel];
      if (buffer == null) return;
      buffer.addAll(samples);
      if (buffer.length > _maxSamples) buffer.removeRange(0, buffer.length - _maxSamples);
    });
    notifyListeners();
  }

  /// คลื่นจำลองผสมหลายความถี่ต่อช่อง ให้หน้าตาใกล้เคียงสัญญาณจริง
  void _startSimulation() {
    var time = 0.0;
    final random = math.Random();
    double wave(double a1, double f1, double a2, double f2, double noise) =>
        a1 * math.sin(2 * math.pi * f1 * time) + a2 * math.sin(2 * math.pi * f2 * time) + (random.nextDouble() - 0.5) * noise;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_muse.isConnected || !_muse.isSimulating) {
        timer.cancel();
        return;
      }
      time += 0.03;
      _add('TP9', wave(15, 10, 4, 4, 6));
      _add('AF7', wave(8, 20, 10, 8, 8));
      _add('AF8', wave(7, 18, 9, 9, 7.5));
      _add('TP10', wave(10, 6, 15, 2, 5));
      notifyListeners();
    });
  }

  void _add(String channel, double value) {
    final buffer = buffers[channel]!;
    buffer.add(value);
    if (buffer.length > _maxSamples) buffer.removeAt(0);
  }

  void _stopAll() {
    _rawSubscription?.cancel();
    _rawSubscription = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
}
