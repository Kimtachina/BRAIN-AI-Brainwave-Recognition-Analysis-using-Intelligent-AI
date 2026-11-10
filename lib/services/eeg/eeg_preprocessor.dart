import 'dart:math';

/// ตัวกรองสัญญาณ EEG ก่อนนำไปวิเคราะห์ (ใช้ในหน้าแสดงขั้นตอน EegPipelineVisualizer)
///
/// 1. DC offset removal / detrend
/// 2. Band-pass filter: 1-45 Hz (Butterworth, zero-phase)
/// 3. Notch filter: 50/60 Hz (ตั้งค่าตามประเทศ)
///
/// อ้างอิง:
/// - IFCN Standards for EEG Recording (2017)
/// - Krigolson et al. (2017) Muse validation study
class EegPreprocessor {
  /// Sampling rate (Hz)
  final int samplingRate;

  /// Bandpass filter low cutoff (Hz) — 1 Hz ดีกว่า 0.5 Hz สำหรับ movement rejection
  final double bandpassLow;

  /// Bandpass filter high cutoff (Hz)
  final double bandpassHigh;

  /// Notch filter frequency (Hz) — 50 Hz (Asia/Europe) or 60 Hz (US/Japan)
  final double notchFrequency;

  EegPreprocessor({
    this.samplingRate = 256,
    this.bandpassLow = 1.0,
    this.bandpassHigh = 45.0,
    this.notchFrequency = 50.0,
  });

  // ═══════════════════════════════════════════════════════════════
  //  1. DC Offset Removal / Detrend
  // ═══════════════════════════════════════════════════════════════

  /// ลบ DC offset (mean subtraction) + optional linear detrend
  ///
  /// สำคัญ: ต้องทำ BEFORE filtering เพื่อลด IIR transient
  /// ถ้าไม่ลบ DC → filter จะ ring อย่างหนักใน samples แรก
  List<double> removeDCOffset(List<double> data,
      {bool linearDetrend = true}) {
    final n = data.length;
    if (n < 2) return List.from(data);

    if (!linearDetrend) {
      // Simple mean subtraction
      double sum = 0;
      for (final v in data) {
        sum += v;
      }
      final mean = sum / n;
      return List.generate(n, (i) => data[i] - mean);
    }

    // Linear detrend: fit y = ax + b, then subtract
    // Using least-squares: a = (n*Σxy - Σx*Σy) / (n*Σx² - (Σx)²)
    double sx = 0, sy = 0, sxy = 0, sx2 = 0;
    for (int i = 0; i < n; i++) {
      sx += i;
      sy += data[i];
      sxy += i * data[i];
      sx2 += i * i;
    }

    final denom = n * sx2 - sx * sx;
    if (denom.abs() < 1e-10) {
      // Degenerate case: just subtract mean
      final mean = sy / n;
      return List.generate(n, (i) => data[i] - mean);
    }

    final a = (n * sxy - sx * sy) / denom;
    final b = (sy - a * sx) / n;

    return List.generate(n, (i) => data[i] - (a * i + b));
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. Band-pass Filter (4th-order Butterworth)
  // ═══════════════════════════════════════════════════════════════

  /// 4th-order Butterworth band-pass filter (zero-phase)
  ///
  /// Implemented as cascade of two 2nd-order sections (SOS)
  /// → 4th-order total → -24 dB/octave rolloff
  /// → ดีกว่า 2nd-order (-12 dB/octave) ของเดิมมาก
  ///
  /// Zero-phase: forward + backward pass ทำให้ไม่เกิด phase distortion
  List<double> bandpassFilter(List<double> data) {
    if (data.length < 8) return List.from(data);

    // High-pass (remove <1 Hz)
    var filtered = _butterworth2ndHP(data, bandpassLow, samplingRate);
    filtered = _butterworth2ndHP(filtered, bandpassLow, samplingRate); // 2x = 4th order

    // Low-pass (remove >45 Hz)
    filtered = _butterworth2ndLP(filtered, bandpassHigh, samplingRate);
    filtered = _butterworth2ndLP(filtered, bandpassHigh, samplingRate); // 2x = 4th order

    return filtered;
  }

  /// 2nd-order Butterworth High-pass (zero-phase forward-backward)
  static List<double> _butterworth2ndHP(
      List<double> x, double fc, int fs) {
    final w = tan(pi * fc / fs);
    final w2 = w * w;
    final r = sqrt(2.0);
    final norm = 1.0 / (1.0 + r * w + w2);
    final a0 = norm;
    final a1 = -2.0 * norm;
    final a2 = norm;
    final b1 = 2.0 * (w2 - 1.0) * norm;
    final b2 = (1.0 - r * w + w2) * norm;

    return _filtfilt(x, a0, a1, a2, b1, b2);
  }

  /// 2nd-order Butterworth Low-pass (zero-phase forward-backward)
  static List<double> _butterworth2ndLP(
      List<double> x, double fc, int fs) {
    final w = tan(pi * fc / fs);
    final w2 = w * w;
    final r = sqrt(2.0);
    final norm = 1.0 / (1.0 + r * w + w2);
    final a0 = w2 * norm;
    final a1 = 2.0 * a0;
    final a2 = a0;
    final b1 = 2.0 * (w2 - 1.0) * norm;
    final b2 = (1.0 - r * w + w2) * norm;

    return _filtfilt(x, a0, a1, a2, b1, b2);
  }

  /// Zero-phase filtering: forward pass + backward pass
  /// → eliminates phase distortion from IIR filter
  static List<double> _filtfilt(
      List<double> x, double a0, double a1, double a2,
      double b1, double b2) {
    final n = x.length;
    if (n < 3) return List.from(x);

    // Forward pass
    final y = List<double>.filled(n, 0.0);
    y[0] = a0 * x[0];
    y[1] = a0 * x[1] + a1 * x[0] - b1 * y[0];
    for (int i = 2; i < n; i++) {
      y[i] = a0 * x[i] + a1 * x[i - 1] + a2 * x[i - 2] -
          b1 * y[i - 1] - b2 * y[i - 2];
    }

    // Backward pass (zero-phase)
    final y2 = List<double>.filled(n, 0.0);
    y2[n - 1] = a0 * y[n - 1];
    if (n > 1) {
      y2[n - 2] = a0 * y[n - 2] + a1 * y[n - 1] - b1 * y2[n - 1];
    }
    for (int i = n - 3; i >= 0; i--) {
      y2[i] = a0 * y[i] + a1 * y[i + 1] + a2 * y[i + 2] -
          b1 * y2[i + 1] - b2 * y2[i + 2];
    }

    return y2;
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. Notch Filter (50/60 Hz)
  // ═══════════════════════════════════════════════════════════════

  /// IIR Notch filter สำหรับกรอง power line interference
  ///
  /// Q = 30 → narrow notch ที่ notchFrequency ± ~1.7 Hz
  /// ไม่กระทบ EEG band ข้างเคียง (45 Hz gamma)
  List<double> notchFilter(List<double> data) {
    if (data.length < 3) return List.from(data);
    final f0 = notchFrequency;
    final q = 30.0;
    final w0 = 2 * pi * f0 / samplingRate;
    final bw = w0 / q;
    final gb = cos(w0);
    final beta = tan(bw / 2);

    final norm = 1.0 / (1.0 + beta);
    final a0 = norm;
    final a1 = -2.0 * gb * norm;
    final a2 = norm;
    final b1 = -2.0 * gb * norm;
    final b2 = (1.0 - beta) * norm;

    // Forward-backward for zero-phase
    return _filtfilt(data, a0, a1, a2, b1, b2);
  }
}
