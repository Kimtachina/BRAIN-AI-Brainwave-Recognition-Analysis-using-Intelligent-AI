part of '../home_screen.dart';

/// นับถอยหลังเก็บข้อมูล EEG และแบนเนอร์ผลประเมินล่าสุด
extension _EegRecordingSection on _HomeScreenState {
  Widget _buildEegCountdownCard() {
    final minutes = _eegCountdownSeconds ~/ 60;
    final seconds = _eegCountdownSeconds % 60;
    final progress = 1.0 - (_eegCountdownSeconds / 90.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: 0.7,
        borderColor: const Color(0xFF1D1B2E).withValues(alpha: 0.18),
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
                  color: const Color(0xFF1D1B2E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded, color: Color(0xFF1D1B2E), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'เกณฑ์การวิเคราะห์คลื่นสมองมาตรฐาน qEEG',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isEegCountdownRunning) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseDot(color: Colors.green, size: 6),
                      const SizedBox(width: 4),
                      Text(
                        'กำลังประเมินสด',
                        style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'บันทึกข้อมูลคลื่นสมองต่อเนื่อง 1.5 นาที เพื่อประเมินค่าดัชนีความเครียดและความผ่อนคลาย (DEAP Protocol)',
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),

          if (_isEegCountdownRunning) ...[
            // วงล้อแสดงความคืบหน้าของเวลานับถอยหลังการทดสอบ (Timer circular progress or medical badge)
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B2A4A),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D1B2E).withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: 1.0 - progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.cyan, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          '$minutes:${seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Text(
                          'เหลือเวลา',
                          style: TextStyle(color: Colors.white54, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'เก็บข้อมูลตัวอย่างได้: ${_eegSamples.length} samples',
                  style: const TextStyle(fontSize: 10, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                ),
                Text(
                  'ความคืบหน้า: ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D1B2E)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _stopEegCountdown,
                icon: const Icon(Icons.stop_circle_outlined, color: AppColors.error, size: 18),
                label: const Text('หยุดการประเมิน', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startEegCountdown,
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                label: const Text('เริ่มการประเมิน qEEG รายบุคคล', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1B2E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openEegReportHistory,
                icon: const Icon(Icons.history_edu_rounded, color: Color(0xFF1D1B2E), size: 18),
                label: const Text(
                  'เปิดดูประวัติและใบประเมินแพทย์ย้อนหลัง',
                  style: TextStyle(color: Color(0xFF1D1B2E), fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1D1B2E), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLatestReportBanner() {
    final s = _eegSummaryResult!;
    final riskColor = EegAssessmentService.riskColor(s);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openLatestReport,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(
            color: riskColor,
            opacity: 0.08,
            borderColor: riskColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.description_rounded, color: riskColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ใบสรุปประเมินความเครียด (qEEG)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      s['riskLevel'] as String? ?? '',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'แตะเพื่อเปิดใบสรุปฉบับเต็ม',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
