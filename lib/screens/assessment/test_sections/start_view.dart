part of '../test_screen.dart';

/// หน้าเริ่มต้นแบบประเมิน PHQ-9: คำอธิบายและเกณฑ์การแปลผลคะแนน
extension _StartView on _TestScreenState {
  Widget _buildStart() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter(context), vertical: 20),
      child: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PHQ-9',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient Health Questionnaire-9',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'แบบประเมินภาวะความเครียดมาตรฐานสากล',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: _infoTitleColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'เกี่ยวกับแบบทดสอบ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _infoTitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('📋', 'จำนวนคำถาม: 9 ข้อ'),
                _buildInfoRow('⏱️', 'ใช้เวลา: ประมาณ 2-3 นาที'),
                _buildInfoRow('📊', 'คะแนนเต็ม: 27 คะแนน'),
                _buildInfoRow('🏥', 'มาตรฐาน: WHO / APA'),
                const SizedBox(height: 8),
                const Text(
                  'แบบทดสอบนี้ใช้เป็นเครื่องมือคัดกรองเบื้องต้น ไม่สามารถใช้วินิจฉัยโรคได้',
                  style: TextStyle(
                    fontSize: 12,
                    color: _infoNoteColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
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
                _buildScoreRange('5-9', 'ความเครียดเล็กน้อย', const Color(0xFFFFC107)),
                _buildScoreRange('10-14', 'ความเครียดปานกลาง', const Color(0xFFFF9800)),
                _buildScoreRange('15-19', 'ความเครียดค่อนข้างรุนแรง', const Color(0xFFFF5722)),
                _buildScoreRange('20-27', 'ความเครียดรุนแรง', const Color(0xFFF44336)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
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

  // กล่อง "เกี่ยวกับแบบทดสอบ" พื้นฟ้าอ่อน จึงใช้ตัวอักษรสีเข้มให้อ่านชัด
  static const _infoTitleColor = Color(0xFF4C3FB0);
  static const _infoTextColor = Color(0xFF1E293B);
  static const _infoNoteColor = Color(0xFF475569);

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _infoTextColor)),
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
}
