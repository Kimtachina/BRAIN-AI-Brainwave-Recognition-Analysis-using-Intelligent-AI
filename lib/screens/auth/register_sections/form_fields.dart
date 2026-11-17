part of '../register_screen.dart';

/// ช่องกรอกข้อมูลและป้ายชื่อที่ใช้ในฟอร์มสมัครสมาชิก หน้าตามาจากธีมกลาง
extension _FormFields on _RegisterScreenState {
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16),
      decoration: InputDecoration(counterText: '', hintText: hintText, suffixIcon: suffixIcon),
    );
  }
}
