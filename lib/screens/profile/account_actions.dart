import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../auth/welcome_screen.dart';

/// การกระทำกับบัญชีที่ใช้ร่วมกันระหว่างหน้าบัญชีและหน้าตั้งค่า
class AccountActions {
  AccountActions._();

  static void _goToWelcome(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  static Future<void> confirmSignOut(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        content: const Text('ข้อมูลของคุณยังอยู่ครบ เข้าสู่ระบบอีกครั้งด้วยอีเมลเดิมได้ทุกเมื่อ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ApiService.signOut();
    _goToWelcome(navigator);
  }

  /// ลบบัญชีถาวร ต้องพิมพ์คำยืนยันก่อน (แบบ GitHub) เพื่อกันกดพลาด
  static Future<void> confirmDeleteAccount(BuildContext context, User user) async {
    const confirmWord = 'ลบบัญชี';
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    var deleting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canDelete = controller.text.trim() == confirmWord && !deleting;
          return AlertDialog(
            title: const Text('ลบบัญชีถาวร?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ระบบจะลบโปรไฟล์ ผลแบบประเมิน รายงานคลื่นสมอง และการตั้งค่าทั้งหมด ย้อนกลับไม่ได้',
                  style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),
                Text('พิมพ์ "$confirmWord" เพื่อยืนยัน', style: AppTextStyles.small),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  enabled: !deleting,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(hintText: confirmWord, isDense: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(0, 44)),
                onPressed: !canDelete
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        final result = await SupabaseService.deleteAccount(user.id);
                        if (result['success'] == true) {
                          await ApiService.signOut();
                          _goToWelcome(navigator);
                        } else {
                          setDialogState(() => deleting = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(result['message']?.toString() ?? 'ลบบัญชีไม่สำเร็จ ลองอีกครั้ง')),
                          );
                        }
                      },
                child: deleting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('ลบบัญชี'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }
}
