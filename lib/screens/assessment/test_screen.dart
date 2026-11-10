import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../profile/settings_screen.dart';

part 'test_sections/start_view.dart';
part 'test_sections/quiz_view.dart';
part 'test_sections/result_sheet.dart';

part 'test_sections/phq9_questions.dart';

/// TestScreen คือหน้าจอทำแบบทดสอบคัดกรองภาวะความเครียดและซึมเศร้ามาตรฐานสากล (PHQ-9)
/// แสดงผลแบบสอบถามทีละข้อจำนวน 9 ข้อ คำนวณคะแนนรวม แปลความหมายระดับผลลัพธ์ และบันทึกลง API
class TestScreen extends StatefulWidget {
  final User? user;

  const TestScreen({super.key, this.user});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with SingleTickerProviderStateMixin {
  bool _hasStarted = false;
  int _currentQuestion = 0;
  List<int> _answers = [];
  int? _selectedAnswer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _hasStarted = true;
      _currentQuestion = 0;
      _answers = [];
      _selectedAnswer = null;
    });
    _animController.reset();
    _animController.forward();
  }

  void _selectAnswer(int score) {
    setState(() {
      _selectedAnswer = score;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _answers.add(score);
        _selectedAnswer = null;
      });

      if (_currentQuestion < _phq9Questions.length - 1) {
        _animController.reset();
        _animController.forward();
        setState(() {
          _currentQuestion++;
        });
      } else {
        _showResults();
      }
    });
  }

  Map<String, dynamic> _interpretScore(int totalScore) {
    if (totalScore <= 4) {
      return {
        'level': 'ปกติ / น้อยมาก',
        'levelEn': 'Minimal Stress',
        'stressLevel': 'normal',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.sentiment_very_satisfied,
        'recommendation': 'ไม่พบอาการความเครียด สุขภาพจิตของคุณอยู่ในเกณฑ์ดี',
        'action': 'ดูแลสุขภาพกายใจเช่นเดิม ออกกำลังกาย นอนหลับพักผ่อนให้เพียงพอ',
      };
    } else if (totalScore <= 9) {
      return {
        'level': 'ความเครียดเล็กน้อย',
        'levelEn': 'Mild Stress',
        'stressLevel': 'mild',
        'color': const Color(0xFFFFC107),
        'icon': Icons.sentiment_satisfied,
        'recommendation': 'มีอาการความเครียดเล็กน้อย ควรเฝ้าระวังและติดตามอาการ',
        'action': 'แนะนำให้ทำกิจกรรมที่ชอบ ออกกำลังกาย พูดคุยกับคนใกล้ชิด',
      };
    } else if (totalScore <= 14) {
      return {
        'level': 'ความเครียดปานกลาง',
        'levelEn': 'Moderate Stress',
        'stressLevel': 'moderate',
        'color': const Color(0xFFFF9800),
        'icon': Icons.sentiment_neutral,
        'recommendation': 'มีอาการความเครียดปานกลาง ควรปรึกษาผู้เชี่ยวชาญ',
        'action': 'ควรพบแพทย์หรือนักจิตวิทยาเพื่อวางแผนการดูแลรักษา',
      };
    } else if (totalScore <= 19) {
      return {
        'level': 'ความเครียดค่อนข้างรุนแรง',
        'levelEn': 'Moderately Severe Stress',
        'stressLevel': 'high',
        'color': const Color(0xFFFF5722),
        'icon': Icons.sentiment_dissatisfied,
        'recommendation': 'มีอาการความเครียดค่อนข้างรุนแรง จำเป็นต้องได้รับการดูแล',
        'action': 'ควรพบจิตแพทย์โดยเร็ว เพื่อรับการรักษาที่เหมาะสม',
      };
    } else {
      return {
        'level': 'ความเครียดรุนแรง',
        'levelEn': 'Severe Stress',
        'stressLevel': 'severe',
        'color': const Color(0xFFF44336),
        'icon': Icons.sentiment_very_dissatisfied,
        'recommendation': 'มีอาการความเครียดระดับรุนแรง ต้องได้รับการรักษาทันที',
        'action': 'กรุณาพบจิตแพทย์โดยด่วน สายด่วนสุขภาพจิต 1323',
      };
    }
  }

  Future<void> _showResults() async {
    final totalScore = _answers.reduce((a, b) => a + b);
    final maxScore = _phq9Questions.length * 3;
    final interpretation = _interpretScore(totalScore);

    if (widget.user != null) {
      final saveResult = await ApiService.saveTestResult(
        userId: widget.user!.id,
        stressScore: totalScore,
        depressionScore: totalScore,
        stressLevel: interpretation['stressLevel'],
      );
      print('💾 [TestScreen] saveTestResult: $saveResult');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(totalScore, maxScore, interpretation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _hasStarted ? 'แบบประเมิน PHQ-9' : 'แบบทดสอบ',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              if (widget.user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user!)),
                );
              }
            },
            icon: Icon(Icons.settings, color: AppColors.primaryBlue),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _hasStarted ? _buildQuiz() : _buildStart(),
      ),
    );
  }
}
