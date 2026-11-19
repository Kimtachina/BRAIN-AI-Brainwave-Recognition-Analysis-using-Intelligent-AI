import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'test_screen.dart';
import '../../widgets/app_page.dart';

/// Phq9TabScreen เป็นหน้าจอหลักสำหรับการทำแบบประเมินและติดตามประวัติ PHQ-9
/// แบ่งออกเป็น 2 แท็บย่อย: แท็บทำแบบประเมิน และแท็บดูประวัติผลการทดสอบย้อนหลัง
class Phq9TabScreen extends StatefulWidget {
  final User user;

  const Phq9TabScreen({super.key, required this.user});

  @override
  State<Phq9TabScreen> createState() => _Phq9TabScreenState();
}

class _Phq9TabScreenState extends State<Phq9TabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _testHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final result = await ApiService.getTestResults(widget.user.id);
    if (result['success'] == true && result['results'] != null) {
      setState(() {
        _testHistory = List<Map<String, dynamic>>.from(result['results']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
            // ส่วนหัวข้อด้านบนของหน้าจอ
            Padding(
              padding: EdgeInsets.fromLTRB(AppLayout.gutter(context), 20, AppLayout.gutter(context), 10),
              child: Column(
                children: [
                  // ส่วนแสดงชื่อแบบทดสอบ
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'แบบทดสอบ PHQ-9',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Patient Health Questionnaire-9',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ส่วนแถบเลือกแท็บการนำทาง (Tab Bar Container)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: AppTheme.glassDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: AppColors.night,
                      unselectedLabelColor: AppColors.inkSoft,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('ทำแบบทดสอบ'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('ประวัติ'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // พื้นที่แสดงผลสำหรับแต่ละแท็บการทำงาน
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTestTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  /// จอกว้างวางสองกล่องคู่กันและสูงเท่ากัน จอแคบเรียงต่อกันลงมา
  Widget _sideBySide(Widget first, Widget second) {
    if (!AppLayout.isWide(context)) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: first), const SizedBox(width: 16), Expanded(child: second)],
      ),
    );
  }

  Widget _buildTestTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppLayout.gutter(context), 20, AppLayout.gutter(context), 20),
      child: Column(
        children: [
          // การ์ดแสดงข้อมูลทั่วไปเกี่ยวกับ PHQ-9
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(
              color: AppColors.primary,
              opacity: 0.15,
              borderColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PHQ-9',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'แบบประเมินภาวะความเครียดมาตรฐานสากล',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // จอกว้าง: กล่องข้อมูลกับเกณฑ์ประเมินวางคู่กัน จอแคบเรียงลงมา
          _sideBySide(
            // กล่องข้อมูลเกี่ยวกับเวลาและจำนวนข้อสอบในการทำประเมิน
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'เกี่ยวกับแบบทดสอบ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.checklist, 'จำนวนคำถาม: 9 ข้อ'),
                  _buildInfoRow(Icons.timer_outlined, 'ใช้เวลา: ประมาณ 2-3 นาที'),
                  _buildInfoRow(Icons.bar_chart, 'คะแนนเต็ม: 27 คะแนน'),
                  _buildInfoRow(Icons.verified, 'มาตรฐาน: WHO / APA'),
                  const SizedBox(height: 8),
                  Text(
                    'แบบทดสอบนี้ใช้เป็นเครื่องมือคัดกรองเบื้องต้น ไม่สามารถใช้วินิจฉัยโรคได้',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // เกณฑ์ช่วงคะแนนการแปลผลลัพธ์
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เกณฑ์ประเมินผล',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildScoreRange('0-4', 'ปกติ', const Color(0xFF4CAF50)),
                  _buildScoreRange(
                      '5-9', 'ความเครียดเล็กน้อย', const Color(0xFFFFC107)),
                  _buildScoreRange(
                      '10-14', 'ความเครียดปานกลาง', const Color(0xFFFF9800)),
                  _buildScoreRange(
                      '15-19', 'ความเครียดค่อนข้างรุนแรง', const Color(0xFFFF5722)),
                  _buildScoreRange('20-27', 'ความเครียดรุนแรง', const Color(0xFFF44336)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ปุ่มเริ่มต้นสำหรับคลิกไปทำแบบทดสอบ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TestScreen(user: widget.user)),
                ).then((_) => _loadHistory());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: AppColors.night, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'เริ่มทำแบบประเมิน',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.night,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _testHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: AppColors.line),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีประวัติการทดสอบ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ทำแบบทดสอบ PHQ-9 เพื่อเริ่มบันทึกประวัติ',
                    style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(AppLayout.gutter(context), 20, AppLayout.gutter(context), 20),
              itemCount: _testHistory.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // การ์ดสรุปผลคะแนนรวมที่แสดงอยู่ด้านบนสุดของแท็บประวัติ
                  return _buildSummaryCard();
                }
                final test = _testHistory[index - 1];
                return _buildHistoryCard(test);
              },
            ),
    );
  }

  Widget _buildSummaryCard() {
    if (_testHistory.isEmpty) return const SizedBox.shrink();

    final latest = _testHistory.first;
    final stressLevel = latest['stress_level'] ?? 'normal';
    final score = latest['stress_score'] ?? latest['depression_score'] ?? 0;
    final display = _getStressDisplay(stressLevel);

    final Color rangeColor = display['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        color: rangeColor,
        opacity: 0.08,
        borderColor: rangeColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.assessment_rounded,
                  color: display['color'] as Color, size: 22),
              const SizedBox(width: 8),
              Text(
                'ผลการทดสอบล่าสุด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: display['color'] as Color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // วงกลมสัญลักษณ์แสดงคะแนนรวม
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rangeColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: rangeColor.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: display['color'] as Color,
                        ),
                      ),
                      Text(
                        '/27',
                        style: TextStyle(
                          fontSize: 11,
                          color: (display['color'] as Color).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display['label'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: display['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (latest['test_date'] != null)
                      Text(
                        'ทดสอบเมื่อ: ${_formatDate(latest['test_date'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'จำนวนครั้งที่ทดสอบ: ${_testHistory.length} ครั้ง',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> test) {
    final stressLevel = test['stress_level'] ?? 'normal';
    final score = test['stress_score'] ?? test['depression_score'] ?? 0;
    final display = _getStressDisplay(stressLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 50,
            decoration: BoxDecoration(
              color: display['color'] as Color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test['test_date']?.toString().substring(0, 10) ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ผลการทดสอบ: ${display['label']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (display['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score/27',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: display['color'] as Color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScoreRange(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              range,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStressDisplay(String stressLevel) {
    switch (stressLevel) {
      case 'normal':
        return {'label': 'ปกติ', 'color': const Color(0xFF4CAF50)};
      case 'mild':
        return {'label': 'ความเครียดเล็กน้อย', 'color': const Color(0xFFFFC107)};
      case 'moderate':
        return {
          'label': 'ความเครียดปานกลาง',
          'color': const Color(0xFFFF9800)
        };
      case 'high':
        return {'label': 'ความเครียดค่อนข้างรุนแรง', 'color': const Color(0xFFFF5722)};
      case 'severe':
        return {'label': 'ความเครียดรุนแรง', 'color': const Color(0xFFF44336)};
      default:
        return {'label': 'ยังไม่ได้ทดสอบ', 'color': AppColors.inkFaint};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
