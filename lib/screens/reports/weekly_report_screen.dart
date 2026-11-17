import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/ai/chatgpt_service.dart';
import '../../widgets/app_page.dart';

/// WeeklyReportScreen เป็นหน้าจอสรุปสถิติและแนวโน้มสภาวะจิตใจรายสัปดาห์ (AI Weekly Report)
/// ดึงรายงานคลื่นสมอง (eeg_assessment_reports) และคะแนน PHQ-9 ย้อนหลัง 7 วัน
/// เพื่อให้ AI Chatbot สังเคราะห์บทวิเคราะห์แนวโน้มสุขภาพจิตและส่งออกรายงาน PDF
class WeeklyReportScreen extends StatefulWidget {
  final User? user;

  const WeeklyReportScreen({super.key, this.user});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _isLoading = true;
  bool _isGeneratingAI = false;

  List<dynamic> _eegReports = []; // รายงานคลื่นสมองใน 7 วันล่าสุด
  List<dynamic> _phq9Results = [];

  List<FlSpot> _chartSpots = [];
  List<String> _chartDates = [];

  String _aiReport = '';
  String _errorMessage = '';

  /// ดัชนีคลื่นสมองเฉลี่ยของสัปดาห์ (0-100: ≤30 ผ่อนคลาย, ≤60 ปกติ, มากกว่านั้นเครียด)
  double? get _avgEegIndex {
    final values = _eegReports.map((r) => (r['eeg_index'] as num?)?.toDouble()).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    if (widget.user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่พบข้อมูลผู้ใช้';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = widget.user!.id;

      // 1. รายงานคลื่นสมองใน 7 วันล่าสุด
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final eegRes = await ApiService.getEegAssessmentReports(userId);
      if (eegRes['success'] == true) {
        _eegReports = (eegRes['reports'] as List? ?? [])
            .where((r) => _date(r['recorded_at'])?.isAfter(weekAgo) ?? false)
            .toList();
      }

      // 2. ผลแบบประเมิน PHQ-9
      final phqRes = await ApiService.getTestResults(userId);
      if (phqRes['success'] == true) {
        _phq9Results = phqRes['results'] ?? [];
      }

      // Process chart data
      _processChartData();

      // Load cached AI report
      await _loadCachedAIReport();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูล: $e';
      });
    }
  }

  void _processChartData() {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final dates = <String>[];

    // Generate last 7 dates (from 6 days ago to today)
    final days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      dates.add('${day.day}/${day.month}');

      final values = _eegReports
          .where((r) {
            final d = _date(r['recorded_at']);
            return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
          })
          .map((r) => (r['eeg_index'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      // 0 = วันนั้นไม่ได้วัด
      spots.add(FlSpot(i.toDouble(), values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length));
    }

    _chartSpots = spots;
    _chartDates = dates;
  }

  // เก็บรายงาน AI ล่าสุดไว้ใน shared_preferences (ใช้ได้ทั้งมือถือและเว็บ)
  String get _cacheKey => 'weekly_ai_report_${widget.user!.id}';

  Future<void> _loadCachedAIReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedText = prefs.getString(_cacheKey);
      if (cachedText != null && cachedText.isNotEmpty) {
        _aiReport = cachedText;
      }
    } catch (e) {
      debugPrint('Error loading cached AI report: $e');
    }
  }

  Future<void> _cacheAIReport(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, text);
    } catch (e) {
      debugPrint('Error saving cached AI report: $e');
    }
  }

  Future<void> _generateAIReport() async {
    if (widget.user == null) return;

    setState(() {
      _isGeneratingAI = true;
    });

    final avg = _avgEegIndex;
    String eegSessionsStr = '';
    if (_eegReports.isNotEmpty) {
      eegSessionsStr = _eegReports.take(7).map((r) {
        final date = _date(r['recorded_at']) ?? DateTime.now();
        return '- วันที่ ${date.day}/${date.month}/${date.year} | ดัชนีคลื่นสมอง: ${(r['eeg_index'] as num?)?.toStringAsFixed(0) ?? '-'}/100 (${r['risk_level'] ?? '-'})';
      }).join('\n');
    } else {
      eegSessionsStr = 'ไม่มีการวัดคลื่นสมองในสัปดาห์นี้';
    }

    String phq9Str = '';
    if (_phq9Results.isNotEmpty) {
      phq9Str = _phq9Results.take(3).map((r) {
        final date = DateTime.parse(r['test_date'].toString()).toLocal();
        return '- วันที่ ${date.day}/${date.month}/${date.year} | คะแนนประเมินความเครียด: ${r['stress_score'] ?? r['depression_score'] ?? 0} (${r['stress_level'] ?? 'ปกติ'})';
      }).join('\n');
    } else {
      phq9Str = 'ไม่มีประวัติทำแบบประเมินความเครียด PHQ-9';
    }

    final prompt = '''
ข้อมูลสุขภาพผู้ใช้ในรอบ 7 วันที่ผ่านมา:
- วัดคลื่นสมอง: ทั้งหมด ${_eegReports.length} ครั้ง
- ดัชนีคลื่นสมองเฉลี่ย (0-100, ยิ่งสูงยิ่งเครียด): ${avg == null ? 'ไม่มีข้อมูล' : avg.toStringAsFixed(0)}

ผลวัดคลื่นสมองรายครั้ง:
$eegSessionsStr

ผลประเมินความเครียดและสุขภาพจิต PHQ-9 (ย้อนหลัง):
$phq9Str

ช่วยเขียนรายงานภาพรวมสุขภาพจิต วิเคราะห์คลื่นสมอง และให้คำแนะนำฟื้นฟูเฉพาะบุคคลในภาษาไทยที่สุภาพ อบอุ่น และเข้าใจง่ายหน่อยครับ
''';

    final result = await ChatGPTService.generateWeeklyReport(promptContent: prompt);

    if (result['success'] == true && result['report'] != null) {
      final reportText = result['report'] as String;
      await _cacheAIReport(reportText);
      if (!mounted) return;
      setState(() {
        _aiReport = reportText;
        _isGeneratingAI = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isGeneratingAI = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'เกิดข้อผิดพลาดในการสร้างรายงาน AI'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansThaiRegular();
    final fontBold = await PdfGoogleFonts.notoSansThaiBold();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final userName = widget.user?.fullName ?? widget.user?.username ?? 'ผู้ใช้งาน';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'รายงานสุขภาพรายสัปดาห์ (AI Weekly Report)',
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 8),
                pw.Text('ชื่อผู้ใช้: $userName | วันที่ออกรายงาน: $dateStr', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                pw.Divider(thickness: 1.5, color: PdfColors.blue800),
                pw.SizedBox(height: 16),
                
                pw.Text('1. สรุปข้อมูลดิบรายสัปดาห์', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue900)),
                pw.Bullet(text: 'วัดคลื่นสมอง: ${_eegReports.length} ครั้ง (ดัชนีเฉลี่ย: ${_avgEegIndex?.toStringAsFixed(0) ?? '-'}/100)', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Bullet(text: 'จำนวนประวัติ PHQ-9: ${_phq9Results.length} ครั้ง', style: pw.TextStyle(font: font, fontSize: 10)),
                
                pw.SizedBox(height: 20),
                pw.Text('2. บทวิเคราะห์และคำแนะนำโดย AI', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue900)),
                pw.SizedBox(height: 8),
                pw.Text(
                  _aiReport.isNotEmpty ? _aiReport : 'ยังไม่มีบทวิเคราะห์สรุป AI (กรุณากดรับรายงาน AI ในแอปพลิเคชันก่อน)',
                  style: pw.TextStyle(font: font, fontSize: 9.5, height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppPageBar(context, title: 'รายงานประจำสัปดาห์ AI'),
      body: Container(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(AppLayout.gutter(context, maxWidth: AppLayout.contentWidth), 20, AppLayout.gutter(context, maxWidth: AppLayout.contentWidth), 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Quick Stats Overview
                        _buildQuickStatsCard(),
                        const SizedBox(height: 20),

                        // Card 2: Trend Chart
                        _buildTrendChartCard(),
                        const SizedBox(height: 20),

                        // Card 3: AI Analysis report
                        _buildAIReportCard(),
                      ],
                    ),
                  ),
      ),
    ),
    );
  }

  Widget _buildQuickStatsCard() {
    final avg = _avgEegIndex;
    final eegCount = _eegReports.length;
    final phq9Count = _phq9Results.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'สรุปสถิติประจำสัปดาห์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE4E1EC)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('วัดคลื่นสมอง', '$eegCount ครั้ง', AppColors.secondary),
              _buildStatItem('ดัชนีเฉลี่ย', avg == null ? '–' : '${avg.toStringAsFixed(0)}/100', AppColors.primary),
              _buildStatItem('แบบประเมิน', '$phq9Count ครั้ง', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildTrendChartCard() {
    final activeSpots = _chartSpots.where((s) => s.y > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'แนวโน้มคลื่นสมอง (ย้อนหลัง 7 วัน)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ดัชนีคลื่นสมองเฉลี่ยรายวัน (0–30 ผ่อนคลาย · 31–60 ปกติ · 61–100 เครียด)',
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: activeSpots.isEmpty
                ? const Center(
                    child: Text('สัปดาห์นี้ยังไม่ได้วัดคลื่นสมอง',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == 50 || value == 100) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 10),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 28,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < _chartDates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _chartDates[idx],
                                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 9),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 24,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: activeSpots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'บทวิเคราะห์สุขภาพจิตโดย AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                ],
              ),
              if (_aiReport.isNotEmpty)
                IconButton(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.share, color: AppColors.primary, size: 20),
                  tooltip: 'ส่งออกเป็น PDF',
                ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE4E1EC)),
          if (_isGeneratingAI)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('สมาร์ทเบรน AI กำลังวิเคราะห์ข้อมูลสุขภาพประจำสัปดาห์...',
                        style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            )
          else if (_aiReport.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('ยังไม่มีบทสรุปสำหรับสัปดาห์นี้',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateAIReport,
                      icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      label: const Text('วิเคราะห์สุขภาพด้วย AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiReport,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _generateAIReport,
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                      label: const Text('อัปเดต / วิเคราะห์ซ้ำ', style: TextStyle(color: AppColors.primary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                      label: const Text('พิมพ์ / บันทึก PDF', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
