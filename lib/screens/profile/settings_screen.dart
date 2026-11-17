import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/thai_date.dart';
import '../../widgets/app_page.dart';
import '../../widgets/policy_content.dart';
import '../../widgets/settings_list.dart';
import 'account_actions.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';

/// หน้าตั้งค่าแบบแอปใหญ่: ช่องค้นหาการตั้งค่า การ์ดบัญชีด้านบน แล้วแบ่งเป็นกลุ่ม
/// บัญชีและความปลอดภัย → การแจ้งเตือน → ความเป็นส่วนตัว → ช่วยเหลือ → จัดการบัญชี
class SettingsScreen extends StatefulWidget {
  final User user;
  final ValueChanged<User>? onUserUpdated;

  const SettingsScreen({super.key, required this.user, this.onUserUpdated});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// หนึ่งรายการที่ค้นหาได้ ใช้คำค้นเพิ่มเติมช่วยให้เจอแม้พิมพ์ไม่ตรงชื่อ
class _Item {
  final String keywords;
  final Widget tile;
  const _Item(this.keywords, this.tile);
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _search = TextEditingController();
  late User _user;
  String _query = '';

  bool _loadingPrefs = true;
  bool _dailyReminder = true;
  bool _weeklyReport = true;
  bool _stressAlert = true;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadPrefs();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final result = await ApiService.getSettings(_user.id);
    if (!mounted) return;
    final s = result['settings'];
    setState(() {
      if (result['success'] == true && s is Map) {
        _dailyReminder = s['daily_reminder'] ?? true;
        _weeklyReport = s['weekly_report'] ?? true;
        _stressAlert = s['stress_alert'] ?? true;
      }
      _loadingPrefs = false;
    });
  }

  /// บันทึกทันทีที่สลับ ถ้าบันทึกไม่ได้ให้คืนค่าเดิมและบอกผู้ใช้
  Future<void> _savePref(String key, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    final result = await SupabaseService.updateSettings(
      userId: _user.id,
      dailyReminder: key == 'daily' ? value : null,
      weeklyReport: key == 'weekly' ? value : null,
      stressAlert: key == 'stress' ? value : null,
    );
    if (!mounted || result['success'] == true) return;
    setState(() => apply(!value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกการตั้งค่าไม่สำเร็จ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง')),
    );
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.push<User>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user)),
    );
    if (updated == null) return;
    setState(() => _user = updated);
    widget.onUserUpdated?.call(updated);
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: 'เวอร์ชัน ${AppInfo.version}',
      applicationLegalese: 'ผลวิเคราะห์ใช้ติดตามแนวโน้มส่วนบุคคล ไม่ใช่การวินิจฉัยทางการแพทย์',
    );
  }

  Map<String, List<_Item>> _groups() {
    return {
      'บัญชีและความปลอดภัย': [
        _Item('ข้อมูลส่วนตัว ชื่อ เบอร์ วันเกิด รูปโปรไฟล์ แก้ไข profile',
            SettingsTile(icon: Icons.badge_outlined, title: 'ข้อมูลส่วนตัว', subtitle: 'ชื่อ เบอร์โทร วันเกิด รูปโปรไฟล์', onTap: _editProfile)),
        _Item('เปลี่ยนรหัสผ่าน password ความปลอดภัย',
            SettingsTile(icon: Icons.lock_outline_rounded, title: 'เปลี่ยนรหัสผ่าน', onTap: () => _push(ChangePasswordScreen(user: _user)))),
        _Item('อีเมล email เข้าสู่ระบบ',
            SettingsTile(icon: Icons.alternate_email_rounded, title: 'อีเมลที่ใช้เข้าสู่ระบบ', value: _user.email ?? '-')),
      ],
      'การแจ้งเตือน': [
        _Item('แจ้งเตือนประจำวัน เตือน notification reminder',
            SettingsSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'แจ้งเตือนประจำวัน',
              subtitle: 'ชวนวัดคลื่นสมองและทำแบบประเมิน',
              value: _dailyReminder,
              onChanged: _loadingPrefs ? null : (v) => _savePref('daily', v, (x) => _dailyReminder = x),
            )),
        _Item('สรุปรายงานประจำสัปดาห์ weekly notification',
            SettingsSwitchTile(
              icon: Icons.event_note_outlined,
              title: 'สรุปรายงานประจำสัปดาห์',
              value: _weeklyReport,
              onChanged: _loadingPrefs ? null : (v) => _savePref('weekly', v, (x) => _weeklyReport = x),
            )),
        _Item('แจ้งเตือนความเครียดสูง stress alert notification',
            SettingsSwitchTile(
              icon: Icons.monitor_heart_outlined,
              title: 'แจ้งเมื่อความเครียดสูง',
              subtitle: 'จากผลวัดคลื่นสมองล่าสุด',
              value: _stressAlert,
              onChanged: _loadingPrefs ? null : (v) => _savePref('stress', v, (x) => _stressAlert = x),
            )),
      ],
      'ความเป็นส่วนตัว': [
        _Item('เงื่อนไขการใช้งาน terms ข้อตกลง',
            SettingsTile(icon: Icons.description_outlined, title: 'เงื่อนไขการใช้งาน', onTap: () => _push(const PolicyScreen(initialTab: 0)))),
        _Item('นโยบายความเป็นส่วนตัว privacy ข้อมูลส่วนบุคคล pdpa',
            SettingsTile(icon: Icons.privacy_tip_outlined, title: 'นโยบายความเป็นส่วนตัว', onTap: () => _push(const PolicyScreen(initialTab: 1)))),
      ],
      'ช่วยเหลือ': [
        _Item('ศูนย์ช่วยเหลือ help วิธีใช้ ติดต่อ',
            SettingsTile(icon: Icons.help_outline_rounded, title: 'ศูนย์ช่วยเหลือ', onTap: () => _push(const HelpScreen()))),
        _Item('สายด่วนสุขภาพจิต 1323 โทร ฉุกเฉิน',
            SettingsTile(
              icon: Icons.call_outlined,
              title: 'สายด่วนสุขภาพจิต',
              value: '1323',
              onTap: () => launchUrl(Uri.parse('tel:1323')),
            )),
        _Item('เกี่ยวกับ about เวอร์ชัน version license สัญญาอนุญาต',
            SettingsTile(icon: Icons.info_outline_rounded, title: 'เกี่ยวกับ ${AppInfo.name}', value: AppInfo.version, onTap: _showAbout)),
      ],
      'จัดการบัญชี': [
        _Item('ออกจากระบบ logout sign out',
            SettingsTile(icon: Icons.logout_rounded, title: 'ออกจากระบบ', destructive: true, onTap: () => AccountActions.confirmSignOut(context))),
        _Item('ลบบัญชี delete account',
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'ลบบัญชี',
              destructive: true,
              onTap: () => AccountActions.confirmDeleteAccount(context, _user),
            )),
      ],
    };
  }

  bool _matches(String group, _Item item) {
    if (_query.isEmpty) return true;
    final hay = '$group ${item.keywords}'.toLowerCase();
    return _query.toLowerCase().split(RegExp(r'\s+')).every(hay.contains);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user.fullName ?? _user.username;
    final groups = _groups();
    final visible = <Widget>[];
    groups.forEach((title, items) {
      final shown = items.where((i) => _matches(title, i)).map((i) => i.tile).toList();
      if (shown.isEmpty) return;
      visible.add(SettingsGroup(
        title: title,
        footer: _query.isEmpty && title == 'จัดการบัญชี' ? 'การลบบัญชีจะลบข้อมูลทั้งหมดอย่างถาวร' : null,
        children: shown,
      ));
    });

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: buildAppPageBar(context, title: 'ตั้งค่า'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppLayout.gutter(context, maxWidth: AppLayout.readingWidth),
          16,
          AppLayout.gutter(context, maxWidth: AppLayout.readingWidth),
          40,
        ),
        children: [
          AppSearchField(
            controller: _search,
            hint: 'ค้นหาการตั้งค่า',
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          if (_query.isEmpty)
            SettingsGroup(children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _editProfile,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        UserAvatar(name: name, url: _user.avatarUrl, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.heading, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('บัญชี ${AppInfo.name} · ข้อมูลส่วนตัว', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkFaint),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ...visible,
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 36, color: AppColors.inkFaint),
                  const SizedBox(height: 10),
                  Text('ไม่พบการตั้งค่า "$_query"', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('ลองคำอื่น เช่น "รหัสผ่าน" "แจ้งเตือน" "นโยบาย"', style: AppTextStyles.small),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Center(child: Text('${AppInfo.name} เวอร์ชัน ${AppInfo.version}', style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}
