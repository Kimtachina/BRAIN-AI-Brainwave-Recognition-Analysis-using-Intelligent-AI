part of '../home_screen.dart';

/// 1. การ์ดสรุปสุขภาพ: ผลแบบประเมินความเครียดและผลทำนายของโมเดลจาก EEG
extension _HealthSummarySection on _HomeScreenState {
  Widget _buildHealthSummaryCard() {
    final stressLevel = _latestTestResult?['stress_level'];
    final stressScore = _latestTestResult?['stress_score'] as int?;
    final depressionScore = _latestTestResult?['depression_score'] as int?;
    final display = _getStressDisplay(stressLevel, stressScore);
    final Color statusColor = display['color'];

    final eegSummary = _summaryFromReport(_latestEegReport);
    final eegIndex = (eegSummary['eegIndex'] as num?)?.toDouble() ??
        (_latestEegReport?['eeg_index'] as num?)?.toDouble();
    final riskLevel = eegSummary['riskLevel'] as String? ??
        _latestEegReport?['risk_level'] as String?;
    final riskColor = _latestEegReport != null 
        ? EegAssessmentService.riskColor(eegSummary)
        : AppColors.inkSoft;
    final recordedAt = _latestEegReport?['recorded_at']?.toString() ??
        eegSummary['recordedAt'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: 0.75,
        borderColor: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'บันทึกวิเคราะห์สุขภาพสมองล่าสุด',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_healthLoaded) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แผงควบคุมฝั่งซ้าย: ข้อมูลผลประเมินภาวะอารมณ์ PHQ-9 (Left Panel)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(display['emoji'], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'ระดับความเครียด',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        display['label'],
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latestTestResult != null
                            ? 'PHQ-9: ${stressScore ?? depressionScore ?? '-'}/27 คะแนน'
                            : 'ยังไม่มีประวัติการประเมิน',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                      ),
                      if (_latestTestResult?['test_date'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ทดสอบ: ${_formatDate(_latestTestResult!['test_date'])}',
                          style: TextStyle(fontSize: 9, color: AppColors.inkFaint),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // แผงควบคุมฝั่งขวา: ข้อมูลผลประเมินคลื่นสมอง EEG (Right Panel)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'สถานะสัญญาณสมอง',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_latestEegReport != null) ...[
                        Text(
                          'EEG Index: ${eegIndex?.toStringAsFixed(0) ?? "0"}/100',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ระดับความเสี่ยง: ${riskLevel ?? "-"}',
                          style: TextStyle(
                            fontSize: 11, 
                            color: riskColor, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (recordedAt != null)
                          Text(
                            'วัดเมื่อ: ${_formatDate(recordedAt)}',
                            style: TextStyle(fontSize: 9, color: AppColors.inkFaint),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final user = widget.user;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EegAssessmentReportScreen(
                                      user: user,
                                      summary: eegSummary,
                                      recordedAt: recordedAt,
                                      reportId: _latestEegReport?['id'] as int?,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 12, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'ดูผลสรุป',
                                      style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(color: AppColors.primary),
                                          const SizedBox(height: 16),
                                          Text(
                                            'กำลังสร้าง PDF...',
                                            style: GoogleFonts.ibmPlexSansThai(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                                try {
                                  final display = EegAssessmentService.forDisplay(eegSummary);
                                  await EegPdfService.sharePdf(display, widget.user, topoBytes: null);
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('เกิดข้อผิดพลาดในการดาวน์โหลด PDF: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.picture_as_pdf_rounded, size: 12, color: AppColors.error),
                                    SizedBox(width: 4),
                                    Text(
                                      'PDF',
                                      style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'ไม่พบประวัติคลื่นสมอง',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'เชื่อมต่อ Muse เพื่อเริ่มวิเคราะห์คลื่นสมองรายบุคคล',
                          style: TextStyle(fontSize: 10, color: AppColors.inkFaint),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStressDisplay(String? stressLevel, int? score) {
    switch (stressLevel) {
      case 'normal':
        return {'label': 'ปกติ', 'emoji': '😊', 'color': const Color(0xFF1E8A7A)};
      case 'mild':
        return {'label': 'ความเครียดเล็กน้อย', 'emoji': '😐', 'color': const Color(0xFFF5B041)};
      case 'moderate':
        return {'label': 'ความเครียดปานกลาง', 'emoji': '😟', 'color': const Color(0xFFE67E22)};
      case 'high':
        return {'label': 'ความเครียดค่อนข้างรุนแรง', 'emoji': '😰', 'color': const Color(0xFFEC7063)};
      case 'severe':
        return {'label': 'ความเครียดรุนแรง', 'emoji': '🆘', 'color': const Color(0xFFEC7063)};
      default:
        return {'label': 'ยังไม่ได้ทดสอบ', 'emoji': '❓', 'color': AppColors.inkFaint};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year + 543} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (_) {
      return dateStr;
    }
  }
}
