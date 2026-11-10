import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../models/user.dart';
import '../../services/muse/muse_service.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../services/eeg/eeg_assessment_service.dart';
import '../../services/eeg/eeg_pdf_service.dart';
import '../../emotion_detection/emotion_detection.dart';
import '../eeg/eeg_session_screen.dart'; // เพิ่มการนำเข้าหน้าเก็บบันทึกข้อมูลคลื่นสมอง
import '../eeg/eeg_assessment_report_screen.dart';
import '../eeg/eeg_report_history_screen.dart';
import '../profile/settings_screen.dart';
import '../games/mini_games_screen.dart';
import '../../widgets/eeg/eeg_pipeline_visualizer.dart';
import '../../widgets/eeg/eeg_research_waveform_card.dart';
import 'widgets/cyber_frame_painter.dart';
import 'widgets/electrode_placement_map.dart';
import 'widgets/grid_pattern_painter.dart';
import 'widgets/micro_wave_chart.dart';
import 'widgets/pulse_dot.dart';
import 'widgets/sci_fi_scanner_overlay.dart';

part 'home_sections/header_section.dart';
part 'home_sections/health_summary_section.dart';
part 'home_sections/brain_video_section.dart';
part 'home_sections/quick_actions_section.dart';
part 'home_sections/muse_connection_section.dart';
part 'home_sections/band_power_section.dart';
part 'home_sections/eeg_recording_section.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final Function(int)? onTabSelected;

  const HomeScreen({super.key, required this.user, this.onTabSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MuseService _museService = MuseService();
  static bool _isResearchWavesExpanded = true;
 
  // สถานะค่าบัฟเฟอร์สัญญาณของหน้าจอออสซิลโลสโคปแบบเรียลไทม์ (Real-time scrolling oscilloscope state)
  final Map<String, List<double>> _oscilloscopeBuffers = {
    'TP9': [],
    'AF7': [],
    'AF8': [],
    'TP10': [],
  };
  StreamSubscription? _rawEegSubscription;
  Timer? _simulationWaveTimer;

  void _updateOscilloscopeSubscription() {
    final bool shouldBeRunning = _museService.isConnected;
    
    if (shouldBeRunning) {
      if (_museService.isSimulating) {
        _rawEegSubscription?.cancel();
        _rawEegSubscription = null;
        if (_simulationWaveTimer == null || !_simulationWaveTimer!.isActive) {
          _startSimulationWaves();
        }
      } else {
        _simulationWaveTimer?.cancel();
        _simulationWaveTimer = null;
        if (_rawEegSubscription == null) {
          _startListeningToRawEeg();
        }
      }
    } else {
      _rawEegSubscription?.cancel();
      _rawEegSubscription = null;
      _simulationWaveTimer?.cancel();
      _simulationWaveTimer = null;
      _oscilloscopeBuffers.forEach((key, value) => value.clear());
    }
  }

  void _startListeningToRawEeg() {
    _rawEegSubscription?.cancel();
    _rawEegSubscription = _museService.rawEegStream.listen((channelData) {
      if (!mounted || !_museService.isConnected || _museService.isSimulating) return;
      setState(() {
        channelData.forEach((channel, samples) {
          _addOscilloscopeSample(channel, samples);
        });
      });
    });
  }

  void _startSimulationWaves() {
    _simulationWaveTimer?.cancel();
    double time = 0;
    final random = math.Random();
    _simulationWaveTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_museService.isConnected || !_museService.isSimulating) {
        timer.cancel();
        return;
      }
      time += 0.03;
      setState(() {
        final tp9Val = 15.0 * math.sin(2 * math.pi * 10 * time) + 4.0 * math.sin(2 * math.pi * 4 * time) + (random.nextDouble() - 0.5) * 6.0;
        final af7Val = 8.0 * math.sin(2 * math.pi * 20 * time) + 10.0 * math.sin(2 * math.pi * 8 * time) + (random.nextDouble() - 0.5) * 8.0;
        final af8Val = 7.0 * math.sin(2 * math.pi * 18 * time) + 9.0 * math.sin(2 * math.pi * 9 * time) + (random.nextDouble() - 0.5) * 7.5;
        final tp10Val = 10.0 * math.sin(2 * math.pi * 6 * time) + 15.0 * math.sin(2 * math.pi * 2 * time) + (random.nextDouble() - 0.5) * 5.0;

        _addSingleOscilloscopeSample('TP9', tp9Val);
        _addSingleOscilloscopeSample('AF7', af7Val);
        _addSingleOscilloscopeSample('AF8', af8Val);
        _addSingleOscilloscopeSample('TP10', tp10Val);
      });
    });
  }

  void _addOscilloscopeSample(String channel, List<double> samples) {
    final buffer = _oscilloscopeBuffers[channel];
    if (buffer != null) {
      buffer.addAll(samples);
      if (buffer.length > 500) {
        buffer.removeRange(0, buffer.length - 500);
      }
    }
  }

  void _addSingleOscilloscopeSample(String channel, double value) {
    final buffer = _oscilloscopeBuffers[channel];
    if (buffer != null) {
      buffer.add(value);
      if (buffer.length > 500) {
        buffer.removeAt(0);
      }
    }
  }

  final EmotionDetectionService _emotionService = EmotionDetectionService();
  late final VideoPlayerController _videoController;
  bool _isVideoLoaded = false;
  bool _isVideoPlaying = true;
  bool _isVideoMuted = true;

  EmotionResult? _tfliteEmotion;
  EmotionResult? _tsceptionEmotion;
  String _selectedModel = 'tflite'; // 'tflite' (Model 1) or 'tsception' (Model 2)
  bool _isDetectingEmotion = false;
  Timer? _emotionDetectionTimer;
  bool _isLoading = false;

  Map<String, dynamic>? _latestTestResult;
  Map<String, dynamic>? _latestEegReport;
  bool _healthLoaded = false;

  StreamSubscription? _testResultSub;
  StreamSubscription? _brainwaveSub;

  // สถานะเครื่องนับเวลาถอยหลังการทดสอบ EEG (EEG Countdown Timer State)
  bool _isEegCountdownRunning = false;
  bool _isEegCountdownDone = false;
  int _eegCountdownSeconds = 90; // บันทึก 90 วินาที = อิง DEAP 60 วินาที + 30 วินาทีขอบเขตตัดสัญญาณรบกวน
  Timer? _eegCountdownTimer;
  Timer? _eegSampleTimer; // เครื่องเวลาสุ่มตัวอย่างความถี่เร็ว (Fast sampling timer 250ms)
  Map<String, dynamic>? _eegSummaryResult;
  
  // ชุดข้อมูลคลื่นสมอง EEG สะสมที่วัดได้ระหว่างการนับเวลาถอยหลัง
  final List<Map<String, double>> _eegSamples = [];

  @override
  void initState() {
    super.initState();

    // กำหนดค่าและเตรียมการเล่นวิดีโอตัวอย่างคลื่นสมองจากไฟล์ในเครื่อง (Initialize Video Player)
    _videoController = VideoPlayerController.asset('assets/videos/brain_demo.mov')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoLoaded = true;
            _isVideoPlaying = _videoController.value.isPlaying;
            _isVideoMuted = _videoController.value.volume == 0;
          });
          _videoController.play();
        }
      });

    _museService.addListener(_onMuseDataUpdate);
    _updateOscilloscopeSubscription();
    _subscribeRealtime();
    _initEmotionDetection();
  }

  void _subscribeRealtime() {
    final userId = widget.user.id;

    _testResultSub = SupabaseService.client
        .from('test_results')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('test_date', ascending: false)
        .limit(1)
        .listen((data) {
      if (!mounted) return;
      setState(() {
        _healthLoaded = true;
        if (data.isNotEmpty) {
          _latestTestResult = data.first;
          print('🔴 [Realtime] test_results updated: $_latestTestResult');
        }
      });
    }, onError: (e) {
      print('❌ [Realtime] test_results error: $e');

      _loadTestResultFallback();
    });

    _brainwaveSub = SupabaseService.client
        .from('eeg_assessment_reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .listen((data) {
      if (!mounted) return;
      setState(() {
        _healthLoaded = true;
        if (data.isNotEmpty) {
          _latestEegReport = data.first;
          print('🔴 [Realtime] eeg_assessment_reports updated: $_latestEegReport');
        } else {
          _latestEegReport = null;
        }
      });
    }, onError: (e) {
      print('❌ [Realtime] eeg_assessment_reports error: $e');
      _loadLatestEegReportFallback();
    });
  }

  Future<void> _loadTestResultFallback() async {
    try {
      final result = await ApiService.getTestResults(widget.user.id);
      if (!mounted) return;
      setState(() {
        _healthLoaded = true;
        if (result['success'] == true &&
            result['results'] != null &&
            (result['results'] as List).isNotEmpty) {
          _latestTestResult = (result['results'] as List).first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _healthLoaded = true);
    }
  }

  Future<void> _loadLatestEegReportFallback() async {
    try {
      final result = await ApiService.getEegAssessmentReports(widget.user.id, limit: 1);
      if (!mounted) return;
      setState(() {
        if (result['success'] == true &&
            result['reports'] != null &&
            (result['reports'] as List).isNotEmpty) {
          _latestEegReport = Map<String, dynamic>.from((result['reports'] as List).first);
        } else {
          _latestEegReport = null;
        }
      });
    } catch (_) {}
  }

  Map<String, dynamic> _summaryFromReport(Map<String, dynamic>? row) {
    if (row == null) return {};
    final data = row['report_data'];
    if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<void> _initEmotionDetection() async {
    await _emotionService.loadModel();

    _emotionDetectionTimer = Timer.periodic(
      const Duration(seconds: EmotionConstants.detectionIntervalSeconds),
      (_) => _autoDetectEmotion(),
    );
  }

  Future<void> _autoDetectEmotion() async {
    if (!_museService.isConnected || _museService.latestData == null) return;
    if (_isDetectingEmotion) return;

    _isDetectingEmotion = true;
    try {
      final data = _museService.latestData!;
      final eegData = {
        'alpha': data.alpha,
        'beta': data.beta,
        'theta': data.theta,
        'delta': data.delta,
        'gamma': data.gamma,
        'attention': data.attention,
        'meditation': data.meditation,
      };

      final results = await _emotionService.detectFromEEG(eegData);

      if (mounted) {
        setState(() {
          _tfliteEmotion = results['tflite'];
          _tsceptionEmotion = results['tsception'];
        });

        final mainResult = results['tflite'];
        if (mainResult != null && mainResult.confidence >= EmotionConstants.confidenceThreshold) {
          ApiService.saveEmotionLog(
            userId: widget.user.id,
            emotionType: mainResult.emotionType,
            triggerEvent: 'eeg_brainwave',
            intensity: (mainResult.confidence * 10).round(),
          );
        }

        final secondResult = results['tsception'];
        if (secondResult != null && secondResult.confidence >= EmotionConstants.confidenceThreshold) {
          ApiService.saveEmotionLog(
            userId: widget.user.id,
            emotionType: secondResult.emotionType,
            triggerEvent: 'eeg_brainwave_tsception',
            intensity: (secondResult.confidence * 10).round(),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Emotion detection error: $e');
    } finally {
      _isDetectingEmotion = false;
    }
  }

  @override
  void dispose() {
    _emotionDetectionTimer?.cancel();
    _emotionService.dispose();
    _eegCountdownTimer?.cancel();
    _eegSampleTimer?.cancel();

    _testResultSub?.cancel();
    _brainwaveSub?.cancel();

    _rawEegSubscription?.cancel();
    _simulationWaveTimer?.cancel();

    _museService.removeListener(_onMuseDataUpdate);
    _museService.stopSimulation();
    _videoController.dispose();
    super.dispose();
  }

  // === EEG 90-Second Countdown Methods (DEAP Protocol) ===

  void _startEegCountdown() {
    if (!_museService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเชื่อมต่อ Muse ก่อนเริ่มทดสอบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isEegCountdownRunning = true;
      _isEegCountdownDone = false;
      _eegCountdownSeconds = 90;
      _eegSamples.clear();
      _eegSummaryResult = null;
    });

    // เครื่องจับเวลาสุ่มสัญญาณแบบเร็ว - ทำการสุ่มเก็บข้อมูลสัญญาณสมองทุกๆ 250 มิลลิวินาที (เก็บราวๆ 360 ชุดในเวลา 90 วินาที)
    _eegSampleTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) { timer.cancel(); return; }
      _collectEegSample();
    });

    // เครื่องเวลานับถอยหลังสำหรับ UI - อัปเดตแสดงผลบนหน้าจอทุกๆ 1 วินาที
    _eegCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      setState(() {
        _eegCountdownSeconds--;
      });

      if (_eegCountdownSeconds <= 0) {
        timer.cancel();
        _eegSampleTimer?.cancel();
        _finishEegCountdown();
      }
    });
  }

  void _stopEegCountdown() {
    _eegCountdownTimer?.cancel();
    _eegSampleTimer?.cancel();
    setState(() {
      _isEegCountdownRunning = false;
      _eegCountdownSeconds = 90;
      _eegSamples.clear();
    });
  }

  void _collectEegSample() {
    final data = _museService.latestData;
    if (data == null) return;

    _eegSamples.add({
      'alpha': data.alpha,
      'beta': data.beta,
      'theta': data.theta,
      'delta': data.delta,
      'gamma': data.gamma,
      'attention': data.attention,
      'meditation': data.meditation,
    });
  }

  Future<void> _finishEegCountdown() async {
    final summary = EegAssessmentService.computeFromSamples(_eegSamples);

    // ทำนายสภาวะทางอารมณ์/จิตใจภาพรวมโดยใช้โมเดล PyTorch Mobile บนข้อมูลค่าเฉลี่ย
    try {
      final sessionEegData = {
        'alpha': summary['avgAlpha'] as double? ?? 0.0,
        'beta': summary['avgBeta'] as double? ?? 0.0,
        'theta': summary['avgTheta'] as double? ?? 0.0,
        'delta': summary['avgDelta'] as double? ?? 0.0,
        'gamma': summary['avgGamma'] as double? ?? 0.0,
      };
      final results = await _emotionService.detectFromEEG(sessionEegData);
      final tfliteResult = results['tflite'];
      if (tfliteResult != null) {
        summary['tfliteMentalState'] = tfliteResult.emotionType;
        summary['tfliteMentalStateLabel'] = EmotionType.fromString(tfliteResult.emotionType).label;
        summary['tfliteMentalStateConfidence'] = tfliteResult.confidence;
      }
      final tsceptionResult = results['tsception'];
      if (tsceptionResult != null) {
        summary['tsceptionMentalState'] = tsceptionResult.emotionType;
        summary['tsceptionMentalStateLabel'] = EmotionType.fromString(tsceptionResult.emotionType).label;
        summary['tsceptionMentalStateConfidence'] = tsceptionResult.confidence;
      }
    } catch (e) {
      debugPrint('❌ Failed to run session mental state prediction: $e');
    }

    setState(() {
      _isEegCountdownRunning = false;
      _isEegCountdownDone = true;
      _eegSummaryResult = summary;
    });

    final saveResult = await ApiService.saveEegAssessmentReport(
      userId: widget.user.id,
      reportData: EegAssessmentService.toJson(summary),
    );

    if (!mounted) return;

    if (saveResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveResult['message'] ?? 'บันทึกใบสรุปไม่สำเร็จ'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EegAssessmentReportScreen(
          user: widget.user,
          summary: summary,
          recordedAt: summary['recordedAt'] as String?,
        ),
      ),
    );
  }

  void _openEegReportHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EegReportHistoryScreen(user: widget.user),
      ),
    );
  }

  void _openLatestReport() {
    if (_eegSummaryResult == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EegAssessmentReportScreen(
          user: widget.user,
          summary: _eegSummaryResult!,
          recordedAt: _eegSummaryResult!['recordedAt'] as String?,
        ),
      ),
    );
  }

  void _onMuseDataUpdate() {
    _updateOscilloscopeSubscription();
    if (mounted) setState(() {});
  }

  Future<void> _scanAndConnect() async {
    setState(() => _isLoading = true);

    final isAvailable = await _museService.isBluetoothAvailable();

    if (!isAvailable) {

      _showNoBluetoothDialog();
    } else {

      await _museService.startScan();

      if (mounted) {
        _showDeviceSelectionDialog();
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _disconnectMuse() async {
    await _museService.disconnect();
  }

  /// ให้โค้ด UI ในไฟล์ part เรียกรีเฟรชหน้าจอได้
  /// (extension เรียก setState ตรง ๆ ไม่ได้ เพราะเป็นเมธอดแบบ protected)
  void _refresh(VoidCallback fn) => setState(fn);

  /// พับ/ขยายการ์ดกราฟคลื่นดิบ (เรียกจาก band_power_section.dart)
  void _toggleResearchWaves() =>
      setState(() => _isResearchWavesExpanded = !_isResearchWavesExpanded);

  /// หน้าหลักแบ่งเป็นส่วน ๆ ตามลำดับที่แสดงบนจอ
  /// โค้ดของแต่ละส่วนอยู่ในโฟลเดอร์ home_sections/ (part ของไฟล์นี้)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.glassBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. สรุปสุขภาพ (Health Summary)
                      _buildHealthSummaryCard(),
                      const SizedBox(height: 20),

                      // 2. วิดีโอสมองแบบ HUD (Video Brain View)
                      _buildBrainVideoHud(),
                      const SizedBox(height: 20),

                      // 3. เมนูลัด (Quick Actions)
                      _buildQuickActions(),
                      const SizedBox(height: 20),

                      // 4. การเชื่อมต่อ Muse (Muse Connection)
                      _buildMuseConnectionCard(),
                      const SizedBox(height: 16),
                      if (_museService.isConnected &&
                          _museService.latestData == null &&
                          !_museService.isSimulating) ...[
                        _buildWaitingForDataCard(),
                        const SizedBox(height: 16),
                      ],

                      // 5. พลังคลื่นสมองแต่ละย่าน (EEG Band Power)
                      _buildBandPowerCard(),
                      const SizedBox(height: 16),

                      // 6. ตรวจจับอารมณ์และนับถอยหลังเก็บข้อมูล EEG
                      if (_museService.isConnected) ...[
                        _buildEmotionDetectionCard(),
                        const SizedBox(height: 16),
                        _buildEegCountdownCard(),
                        const SizedBox(height: 16),
                      ],

                      // 7. ผลประเมินล่าสุด (Latest Report)
                      if (_isEegCountdownDone && _eegSummaryResult != null) ...[
                        _buildLatestReportBanner(),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
