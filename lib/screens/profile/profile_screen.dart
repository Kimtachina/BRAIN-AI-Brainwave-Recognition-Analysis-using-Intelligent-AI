import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/thai_date.dart';
import '../../widgets/app_page.dart';
import '../../widgets/settings_list.dart';
import '../eeg/eeg_report_history_screen.dart';
import '../reports/weekly_report_screen.dart';
import 'account_actions.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

/// หน้าบัญชีแบบแอปใหญ่ (Google Account / Instagram):
/// หัวโปรไฟล์ + ปุ่มแก้ไขโปรไฟล์ → ตัวเลขสรุป → ข้อมูลส่วนตัว → กิจกรรม → ทั่วไป → ออกจากระบบ
class ProfileScreen extends StatefulWidget {
  final User user;
  final ValueChanged<User>? onUserUpdated;
  final VoidCallback? onSearch;
  final ValueChanged<int>? onSelectTab;

  const ProfileScreen({super.key, required this.user, this.onUserUpdated, this.onSearch, this.onSelectTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;
  int? _assessments;
  int? _eegReports;
  bool _eegCapped = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen old) {
    super.didUpdateWidget(old);
    if (old.user != widget.user) setState(() => _user = widget.user);
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getProfile(_user.id),
      ApiService.getTestResults(_user.id),
      ApiService.getEegAssessmentReports(_user.id),
    ]);
    if (!mounted) return;
    final profile = results[0];
    final tests = results[1]['results'];
    final eeg = results[2]['reports'];
    setState(() {
      if (profile['success'] == true && profile['profile'] != null) {
        _user = User.fromJson(profile['profile']);
      }
      _assessments = tests is List ? tests.length : null;
      _eegReports = eeg is List ? eeg.length : null;
      _eegCapped = eeg is List && eeg.length >= 50;
    });
    if (profile['success'] == true) widget.onUserUpdated?.call(_user);
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

  void _openSettings() => _push(SettingsScreen(user: _user, onUserUpdated: (u) {
        setState(() => _user = u);
        widget.onUserUpdated?.call(u);
      }));

  @override
  Widget build(BuildContext context) {
    final name = _user.fullName ?? _user.username;
    final gutter = AppLayout.gutter(context, maxWidth: AppLayout.readingWidth);
    final wide = AppLayout.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(gutter, wide ? 28 : 12, gutter, 40),
            children: [
              // แถบบน: ชื่อหน้า + ปุ่มค้นหาและตั้งค่า (ตำแหน่งเดียวกับแอปใหญ่ส่วนมาก)
              Row(
                children: [
                  Expanded(child: Text('บัญชี', style: AppTextStyles.title.copyWith(fontSize: wide ? 30 : 26))),
                  if (widget.onSearch != null)
                    IconButton(
                      tooltip: 'ค้นหา',
                      onPressed: widget.onSearch,
                      icon: const Icon(Icons.search_rounded, color: AppColors.ink),
                    ),
                  IconButton(
                    tooltip: 'ตั้งค่า',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _identity(name),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('แก้ไขโปรไฟล์'),
                ),
              ),
              const SizedBox(height: 16),
              _stats(),
              SettingsGroup(
                title: 'ข้อมูลส่วนตัว',
                children: [
                  SettingsTile(icon: Icons.person_outline_rounded, title: 'ชื่อ-นามสกุล', value: _user.fullName, emptyHint: 'เพิ่ม', onTap: _editProfile),
                  SettingsTile(icon: Icons.phone_outlined, title: 'เบอร์โทรศัพท์', value: _user.phone, emptyHint: 'เพิ่ม', onTap: _editProfile),
                  SettingsTile(icon: Icons.alternate_email_rounded, title: 'อีเมล', value: _user.email, emptyHint: 'เพิ่ม', onTap: _editProfile),
                  SettingsTile(icon: Icons.cake_outlined, title: 'วันเกิด', value: ThaiDate.fromText(_user.birthDate), emptyHint: 'เพิ่ม', onTap: _editProfile),
                ],
              ),
              SettingsGroup(
                title: 'กิจกรรมของฉัน',
                children: [
                  SettingsTile(
                    icon: Icons.checklist_rounded,
                    title: 'ผลแบบประเมิน PHQ-9',
                    onTap: widget.onSelectTab == null ? null : () => widget.onSelectTab!(1),
                  ),
                  SettingsTile(
                    icon: Icons.insights_outlined,
                    title: 'ประวัติรายงานคลื่นสมอง',
                    onTap: () => _push(EegReportHistoryScreen(user: _user)),
                  ),
                  SettingsTile(
                    icon: Icons.event_note_outlined,
                    title: 'รายงานประจำสัปดาห์',
                    subtitle: 'สรุปและบันทึกเป็น PDF',
                    onTap: () => _push(WeeklyReportScreen(user: _user)),
                  ),
                ],
              ),
              SettingsGroup(
                title: 'ทั่วไป',
                children: [
                  SettingsTile(icon: Icons.settings_outlined, title: 'ตั้งค่า', subtitle: 'การแจ้งเตือน รหัสผ่าน ความเป็นส่วนตัว', onTap: _openSettings),
                  SettingsTile(icon: Icons.help_outline_rounded, title: 'ช่วยเหลือและติดต่อ', onTap: () => _push(const HelpScreen())),
                ],
              ),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'ออกจากระบบ',
                    destructive: true,
                    onTap: () => AccountActions.confirmSignOut(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(child: Text('${AppInfo.name} เวอร์ชัน ${AppInfo.version}', style: AppTextStyles.caption)),
              if (!wide) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(String name) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'เปลี่ยนรูปโปรไฟล์',
          child: Pressable(
            onTap: _editProfile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(name: name, url: _user.avatarUrl, size: 76),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.inkSoft),
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
              Text(name, style: AppTextStyles.title.copyWith(fontSize: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((_user.email ?? '').isNotEmpty)
                Text(_user.email!, style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    String count(int? n, {bool capped = false}) => n == null ? '–' : (capped ? '$n+' : '$n');
    final since = _user.createdAt == null ? '–' : ThaiDate.monthYear(_user.createdAt!.toLocal());

    Widget cell(String value, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(value, style: AppTextStyles.heading.copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    const sep = SizedBox(height: 40, child: VerticalDivider(width: 1, thickness: 1, color: AppColors.line));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          cell(count(_assessments), 'แบบประเมิน'),
          sep,
          cell(count(_eegReports, capped: _eegCapped), 'รายงานคลื่นสมอง'),
          sep,
          cell(since, 'สมาชิกตั้งแต่'),
        ],
      ),
    );
  }
}
