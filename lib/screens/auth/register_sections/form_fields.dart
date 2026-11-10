part of '../register_screen.dart';

/// ช่องกรอกข้อมูลและป้ายชื่อที่ใช้ในฟอร์มสมัครสมาชิก
extension _FormFields on _RegisterScreenState {
  /// สร้างป้ายชื่อเหนือช่องกรอกข้อมูล
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.prompt(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  /// สร้างช่องกรอกข้อมูลพร้อมไอคอน
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
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
      style: GoogleFonts.prompt(fontSize: 15, color: AppColors.textDark),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
