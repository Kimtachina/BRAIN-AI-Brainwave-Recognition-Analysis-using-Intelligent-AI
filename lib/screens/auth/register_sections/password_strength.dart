part of '../register_screen.dart';

/// แถบวัดความแข็งแรงของรหัสผ่าน และรายการเกณฑ์แต่ละข้อ
extension _PasswordStrength on _RegisterScreenState {
  /// แสดงแถบวัดความแข็งแรงของรหัสผ่าน + Checklist เกณฑ์แต่ละข้อ
  Widget _buildPasswordStrengthIndicator() {
    final result = _passwordResult!;
    final checks = result.checks;

    // เลือกสี/ข้อความตามระดับความแข็งแรง
    Color strengthColor;
    String strengthLabel;
    double strengthProgress;

    switch (result.strength) {
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        strengthLabel = 'อ่อน';
        strengthProgress = result.score / 5;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        strengthLabel = 'ปานกลาง';
        strengthProgress = result.score / 5;
      case PasswordStrength.strong:
        strengthColor = Colors.green;
        strengthLabel = 'แข็งแรง';
        strengthProgress = 1.0;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถบความแข็งแรง
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strengthProgress,
                    backgroundColor: AppColors.line,
                    color: strengthColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthLabel,
                style: GoogleFonts.ibmPlexSansThai(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Checklist เกณฑ์แต่ละข้อ
          _buildCheckItem('อย่างน้อย 8 ตัวอักษร', checks.minLength),
          _buildCheckItem('มีตัวพิมพ์ใหญ่ (A-Z)', checks.hasUppercase),
          _buildCheckItem('มีตัวพิมพ์เล็ก (a-z)', checks.hasLowercase),
          _buildCheckItem('มีตัวเลข (0-9)', checks.hasDigit),
          _buildCheckItem('มีอักขระพิเศษ (!@#\$%)', checks.hasSpecialChar),
        ],
      ),
    );
  }

  /// สร้างเช็คมาร์กสำหรับเกณฑ์รหัสผ่านแต่ละข้อ
  Widget _buildCheckItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: passed ? Colors.green : AppColors.inkFaint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 12,
              color: passed ? Colors.green.shade700 : AppColors.inkSoft,
              fontWeight: passed ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
