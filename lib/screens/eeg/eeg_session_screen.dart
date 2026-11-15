import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/muse/muse_service.dart';
import '../../services/api_service.dart';
import '../../widgets/eeg/eeg_pipeline_visualizer.dart';
import '../../widgets/eeg/eeg_research_waveform_card.dart';
import '../../widgets/app_page.dart';

part 'eeg_session_sections/session_list.dart';
part 'eeg_session_sections/running_session.dart';
part 'eeg_session_sections/self_report_dialog.dart';

part 'eeg_session_sections/session_protocol.dart';

/// EegSessionScreen เป็นหน้าจอสำหรับทดสอบบันทึกข้อมูลอารมณ์และสแกนคลื่นสมอง qEEG เรียลไทม์
/// มีเป้าหมาย 6 Sessions ย่อย (เช่น Baseline, ผ่อนคลาย, มีความสุข, เครียด, เศร้า, สมาธิสูง)
/// โดยใช้แบบการทดสอบ DEAP Protocol 60-90 วินาที พร้อมกราฟคลื่นสมอง และการขจัดสัญญาณรบกวน (Visualizer)
class EegSessionScreen extends StatefulWidget {
  final User user;
  final MuseService museService;

  const EegSessionScreen({
    super.key,
    required this.user,
    required this.museService,
  });

  @override
  State<EegSessionScreen> createState() => _EegSessionScreenState();
}

class _EegSessionScreenState extends State<EegSessionScreen>
    with TickerProviderStateMixin {
  static bool _isResearchWavesExpanded = true;
  bool _isRunning = false;
  int _currentSessionIndex = -1;
  int _elapsedSeconds = 0;
  int _samplesCollected = 0;
  Timer? _timer;
  Timer? _sampleTimer;

  double _totalAlpha = 0, _totalBeta = 0, _totalTheta = 0;
  double _totalDelta = 0, _totalGamma = 0;

  late AnimationController _pulseController;

  // Real-time scrolling oscilloscope state
  final Map<String, List<double>> _oscilloscopeBuffers = {
    'TP9': [],
    'AF7': [],
    'AF8': [],
    'TP10': [],
  };
  StreamSubscription? _rawEegSubscription;
  Timer? _simulationWaveTimer;

  void _startListeningToRawEeg() {
    _rawEegSubscription?.cancel();
    _rawEegSubscription = widget.museService.rawEegStream.listen((channelData) {
      if (!mounted || !_isRunning) return;
      setState(() {
        channelData.forEach((channel, samples) {
          for (final sample in samples) {
            _addOscilloscopeSample(channel, sample);
          }
        });
      });
    });
  }

  void _startSimulationWaves() {
    _simulationWaveTimer?.cancel();
    double time = 0;
    final random = Random();
    _simulationWaveTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isRunning) {
        timer.cancel();
        return;
      }
      time += 0.03;
      setState(() {
        // Generate realistic synthetic EEG traces (base frequencies + minor noise)
        // Alpha: ~10 Hz
        final tp9Val = 15.0 * sin(2 * pi * 10 * time) + 4.0 * sin(2 * pi * 4 * time) + (random.nextDouble() - 0.5) * 6.0;
        // Beta: ~20 Hz
        final af7Val = 8.0 * sin(2 * pi * 20 * time) + 10.0 * sin(2 * pi * 8 * time) + (random.nextDouble() - 0.5) * 8.0;
        // Beta: ~18 Hz
        final af8Val = 7.0 * sin(2 * pi * 18 * time) + 9.0 * sin(2 * pi * 9 * time) + (random.nextDouble() - 0.5) * 7.5;
        // Theta/Delta: ~4 Hz
        final tp10Val = 10.0 * sin(2 * pi * 6 * time) + 15.0 * sin(2 * pi * 2 * time) + (random.nextDouble() - 0.5) * 5.0;

        _addOscilloscopeSample('TP9', tp9Val);
        _addOscilloscopeSample('AF7', af7Val);
        _addOscilloscopeSample('AF8', af8Val);
        _addOscilloscopeSample('TP10', tp10Val);
      });
    });
  }

  void _addOscilloscopeSample(String channel, double value) {
    final buffer = _oscilloscopeBuffers[channel];
    if (buffer != null) {
      buffer.add(value);
      if (buffer.length > 500) {
        buffer.removeAt(0);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sampleTimer?.cancel();
    _rawEegSubscription?.cancel();
    _simulationWaveTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startSession(int index) {
    if (!widget.museService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเชื่อมต่อ Muse ก่อนเริ่ม Session'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _currentSessionIndex = index;
      _isRunning = true;
      _elapsedSeconds = 0;
      _samplesCollected = 0;
      _totalAlpha = 0;
      _totalBeta = 0;
      _totalTheta = 0;
      _totalDelta = 0;
      _totalGamma = 0;
      // Clear buffers
      _oscilloscopeBuffers.forEach((key, value) => value.clear());
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final duration = _sessions[index]['duration'] as int;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= duration) _stopSession();
    });

    // Sampling @ 1s → 60-90 samples per session (was 5s → 12-36 samples)
    // Higher density enables 2-5s windowed PSD analysis
    // (García-Martínez et al., 2019: optimal TW = 2-15s)
    _sampleTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _collectSample();
    });

    // Start wave collection/simulation
    if (widget.museService.isSimulating) {
      _startSimulationWaves();
    } else {
      _startListeningToRawEeg();
    }
  }

  void _collectSample() {
    final data = widget.museService.latestData;
    if (data == null) return;

    _totalAlpha += data.alpha;
    _totalBeta += data.beta;
    _totalTheta += data.theta;
    _totalDelta += data.delta;
    _totalGamma += data.gamma;
    _samplesCollected++;

    if (mounted) setState(() {});
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    _sampleTimer?.cancel();
    _rawEegSubscription?.cancel();
    _simulationWaveTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (!mounted) return;

    _showSelfReportDialog();

    setState(() => _isRunning = false);
  }

  Map<String, dynamic> _evaluateEEG(String emotion, double alpha, double beta, double theta, double delta, double gamma) {
    bool isMatch = false;
    String feedback = '';
    List<Map<String, dynamic>> details = [];

    void addDetail(bool pass, String text) {
      details.add({'pass': pass, 'text': text});
    }

    final totalPower = alpha + beta + theta + delta + gamma;
    if (totalPower <= 0) {
      return {'isMatch': false, 'feedback': 'ไม่พบสัญญาณสมอง', 'details': []};
    }

    switch (emotion) {
      case 'neutral':
        isMatch = true;
        feedback = 'เส้นฐาน (Baseline) สมบูรณ์แบบ';
        addDetail(true, 'เก็บข้อมูลคลื่นสมองได้ครบถ้วน (Baseline)');
        break;
        
      case 'calm':
        final baRatio = beta / (alpha > 0 ? alpha : 1);
        if (baRatio < 3.5) {
          isMatch = true;
          feedback = 'ผ่อนคลายได้ดีมาก';
          addDetail(true, 'คลื่นความเครียด (Beta) อยู่ในระดับต่ำ');
        } else {
          feedback = 'สมองยังมีความตื่นตัวสูง';
          addDetail(false, 'คลื่น Beta ยังค่อนข้างสูง (สัดส่วน Beta/Alpha = ${baRatio.toStringAsFixed(1)})');
        }
        
        if (alpha > 6.5) {
          addDetail(true, 'คลื่นผ่อนคลาย (Alpha) ทำงานได้ดี (${alpha.toStringAsFixed(1)})');
        } else {
          addDetail(false, 'คลื่น Alpha ยังค่อนข้างต่ำ ลองหลับตาและหายใจลึกๆ');
        }
        break;
        
      case 'focused':
        if (beta > 25.0) {
          isMatch = true;
          feedback = 'สมาธิดีมาก (จดจ่อสูง)';
          addDetail(true, 'คลื่น Beta พุ่งสูงสะท้อนการคิดวิเคราะห์ (${beta.toStringAsFixed(1)})');
        } else {
          feedback = 'สมาธิอยู่ในระดับปานกลาง';
          addDetail(false, 'คลื่น Beta ยังไม่สูงมาก อาจจะหลุดโฟกัส');
        }
        if (gamma > 10.0) {
          addDetail(true, 'คลื่น Gamma (การประมวลผลขั้นสูง) ทำงานได้ดี (${gamma.toStringAsFixed(1)})');
        } else {
          addDetail(false, 'คลื่น Gamma ยังอยู่ในระดับปกติ');
        }
        break;
        
      case 'stressed':
        if (beta > 20.0 && delta > 30.0) {
          isMatch = true;
          feedback = 'พบรูปแบบความเครียดชัดเจน';
          addDetail(true, 'คลื่นความเครียด (Beta) พุ่งสูง (${beta.toStringAsFixed(1)})');
          addDetail(true, 'พบการเกร็งกล้ามเนื้อ/หน้าเครียด (Delta = ${delta.toStringAsFixed(1)})');
        } else if (beta > 25.0) {
          isMatch = true;
          feedback = 'มีความเครียดทางจิตใจ (Cognitive Stress)';
          addDetail(true, 'คลื่น Beta พุ่งสูง (${beta.toStringAsFixed(1)})');
          addDetail(false, 'ไม่พบการเกร็งกล้ามเนื้อรุนแรง');
        } else {
          feedback = 'คุณดูผ่อนคลายกว่าที่คิด';
          addDetail(false, 'คลื่นความเครียดยังอยู่ในเกณฑ์ปกติ');
          addDetail(false, 'ไม่มีสัญญาณการเกร็งหน้าหรือขมวดคิ้ว');
        }
        break;
        
      case 'happy':
        if (alpha > 5.5 && beta > 20.0) {
          isMatch = true;
          feedback = 'อารมณ์เบิกบาน/ตื่นตัวในทางบวก';
          addDetail(true, 'Beta ทำงานดี แสดงถึงความตื่นตัว (Arousal)');
          addDetail(true, 'Alpha อยู่ในเกณฑ์ดี สะท้อนอารมณ์ผ่อนคลาย (Positive Valence)');
        } else {
          feedback = 'อารมณ์ยังค่อนข้างเป็นกลาง';
          addDetail(false, 'ระดับความตื่นตัวทางบวกยังไม่เด่นชัด');
        }
        break;
        
      case 'sad':
        if (delta > 35.0 || theta > 18.0) {
          isMatch = true;
          feedback = 'พบความถี่ต่ำสอดคล้องกับความเศร้า';
          if (delta > 35.0) addDetail(true, 'Delta พุ่งสูง (อาจมีการขมวดคิ้ว/น้ำตาคลอ/สะอื้น)');
          if (theta > 18.0) addDetail(true, 'Theta สูง (${theta.toStringAsFixed(1)}) สะท้อนความรู้สึกเครียดลึก');
        } else {
          feedback = 'ควบคุมอารมณ์ได้ดี ไม่ค่อยเครียด';
          addDetail(false, 'ไม่พบคลื่นความถี่ต่ำที่บ่งชี้ความเศร้ารุนแรง');
        }
        break;
        
      default:
        isMatch = true;
        feedback = 'เก็บข้อมูลสำเร็จ';
    }
    
    return {'isMatch': isMatch, 'feedback': feedback, 'details': details};
  }

  /// พับ/ขยายการ์ดกราฟคลื่นดิบ (เรียกจาก running_session.dart)
  void _toggleResearchWaves() =>
      setState(() => _isResearchWavesExpanded = !_isResearchWavesExpanded);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryBlue),
          onPressed: () {
            if (_isRunning) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('หยุด Session?'),
                  content: const Text('ข้อมูลที่เก็บแล้วจะถูกบันทึก'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _stopSession();
                        Navigator.pop(context);
                      },
                      child: const Text('หยุดและออก', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'เก็บข้อมูลอารมณ์',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isRunning ? _buildRunningSession() : _buildSessionList(),
    ),
    );
  }
}
