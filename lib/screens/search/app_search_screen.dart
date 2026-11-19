import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/policy_content.dart';
import '../../widgets/settings_list.dart';
import '../eeg/eeg_report_history_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/help_screen.dart';
import '../profile/settings_screen.dart';
import '../reports/weekly_report_screen.dart';

/// ค้นหาทั้งแอป (แบบช่องค้นหาของ iOS Settings / command palette ของ GitHub และ Notion)
/// ยังไม่พิมพ์: แสดงที่เปิดล่าสุดและทางลัดยอดนิยม · พิมพ์แล้ว: ผลลัพธ์แบ่งตามหมวด เน้นคำที่ตรง
/// ไม่พบ: บอกคำที่ลองได้ ไม่ปล่อยหน้าว่าง
class AppSearchScreen extends StatefulWidget {
  final User user;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<User>? onUserUpdated;

  const AppSearchScreen({super.key, required this.user, required this.onSelectTab, this.onUserUpdated});

  @override
  State<AppSearchScreen> createState() => _AppSearchScreenState();
}

class _Entry {
  final String id;
  final String title;
  final String section;
  final String? subtitle;
  final IconData icon;
  final String keywords;
  final void Function(NavigatorState nav) open;

  const _Entry({
    required this.id,
    required this.title,
    required this.section,
    this.subtitle,
    required this.icon,
    this.keywords = '',
    required this.open,
  });
}

class _AppSearchScreenState extends State<AppSearchScreen> {
  static const _recentKey = 'app_search_recent';
  static const _popular = ['phq9', 'muse', 'eeg_history', 'weekly', 'notifications', 'help'];

  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<String> _recent = [];
  late final List<_Entry> _entries = _buildEntries();

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_Entry> _buildEntries() {
    final user = widget.user;
    void tab(NavigatorState nav, int i) {
      nav.pop();
      widget.onSelectTab(i);
    }

    void page(NavigatorState nav, Widget p) => nav.pushReplacement(MaterialPageRoute(builder: (_) => p));

    return [
      _Entry(id: 'today', title: 'วันนี้', section: 'เมนูหลัก', icon: Icons.monitor_heart_outlined,
          subtitle: 'ผลล่าสุดและคลื่นสมองตอนนี้', keywords: 'หน้าหลัก home สรุป ผลล่าสุด คลื่นสมอง', open: (n) => tab(n, 0)),
      _Entry(id: 'muse', title: 'เชื่อมต่อ Muse', section: 'เมนูหลัก', icon: Icons.bluetooth_rounded,
          subtitle: 'ค้นหาและจับคู่แถบคาดศีรษะ', keywords: 'muse bluetooth บลูทูธ อุปกรณ์ แถบคาด eeg วัด', open: (n) => tab(n, 0)),
      _Entry(id: 'phq9', title: 'แบบประเมิน PHQ-9', section: 'เมนูหลัก', icon: Icons.checklist_rounded,
          subtitle: 'ทำแบบประเมินและดูผลย้อนหลัง', keywords: 'phq ซึมเศร้า แบบทดสอบ ประเมิน สุขภาพจิต', open: (n) => tab(n, 1)),
      _Entry(id: 'assistant', title: 'ผู้ช่วย', section: 'เมนูหลัก', icon: Icons.forum_outlined,
          subtitle: 'คำแนะนำสุขภาพและการดูแลตัวเอง', keywords: 'แชท chat ai คำแนะนำ อาหาร โภชนาการ', open: (n) => tab(n, 2)),
      _Entry(id: 'account', title: 'บัญชี', section: 'เมนูหลัก', icon: Icons.person_outline_rounded,
          keywords: 'โปรไฟล์ profile ข้อมูลของฉัน', open: (n) => tab(n, 4)),
      _Entry(id: 'behind', title: 'เบื้องหลัง', section: 'เมนูหลัก', icon: Icons.account_tree_outlined,
          subtitle: 'ขั้นตอนเตรียมสัญญาณ EEG แบบสด',
          keywords: 'pipeline preprocessing กรอง filter สัญญาณ eeg fft เบื้องหลัง', open: (n) => tab(n, 3)),
      _Entry(id: 'eeg_history', title: 'ประวัติรายงานคลื่นสมอง', section: 'รายงาน', icon: Icons.insights_outlined,
          keywords: 'eeg qeeg รายงาน ประวัติ ผลวัด', open: (n) => page(n, EegReportHistoryScreen(user: user))),
      _Entry(id: 'weekly', title: 'รายงานประจำสัปดาห์', section: 'รายงาน', icon: Icons.event_note_outlined,
          subtitle: 'สรุปและบันทึกเป็น PDF', keywords: 'weekly สัปดาห์ pdf สรุป พิมพ์', open: (n) => page(n, WeeklyReportScreen(user: user))),
      _Entry(id: 'edit_profile', title: 'แก้ไขข้อมูลส่วนตัว', section: 'บัญชี', icon: Icons.badge_outlined,
          keywords: 'ชื่อ เบอร์ โทรศัพท์ วันเกิด รูปโปรไฟล์ avatar', open: (n) async {
        final updated = await n.pushReplacement<User, void>(MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
        if (updated != null) widget.onUserUpdated?.call(updated);
      }),
      _Entry(id: 'password', title: 'เปลี่ยนรหัสผ่าน', section: 'บัญชี', icon: Icons.lock_outline_rounded,
          keywords: 'password รหัส ความปลอดภัย', open: (n) => page(n, ChangePasswordScreen(user: user))),
      _Entry(id: 'settings', title: 'ตั้งค่า', section: 'ตั้งค่า', icon: Icons.settings_outlined,
          keywords: 'settings การตั้งค่า', open: (n) => page(n, SettingsScreen(user: user, onUserUpdated: widget.onUserUpdated))),
      _Entry(id: 'notifications', title: 'การแจ้งเตือน', section: 'ตั้งค่า', icon: Icons.notifications_none_rounded,
          subtitle: 'แจ้งเตือนประจำวัน รายงานสัปดาห์ ความเครียด', keywords: 'notification เตือน เสียง',
          open: (n) => page(n, SettingsScreen(user: user, onUserUpdated: widget.onUserUpdated))),
      _Entry(id: 'terms', title: 'เงื่อนไขการใช้งาน', section: 'ตั้งค่า', icon: Icons.description_outlined,
          keywords: 'terms ข้อตกลง', open: (n) => page(n, const PolicyScreen(initialTab: 0))),
      _Entry(id: 'privacy', title: 'นโยบายความเป็นส่วนตัว', section: 'ตั้งค่า', icon: Icons.privacy_tip_outlined,
          keywords: 'privacy ข้อมูลส่วนบุคคล pdpa', open: (n) => page(n, const PolicyScreen(initialTab: 1))),
      _Entry(id: 'help', title: 'ช่วยเหลือและติดต่อ', section: 'ช่วยเหลือ', icon: Icons.help_outline_rounded,
          keywords: 'help วิธีใช้ คู่มือ ติดต่อ อีเมล', open: (n) => page(n, const HelpScreen())),
      _Entry(id: 'hotline', title: 'สายด่วนสุขภาพจิต 1323', section: 'ช่วยเหลือ', icon: Icons.call_outlined,
          subtitle: 'โทรได้ตลอด 24 ชั่วโมง', keywords: 'โทร ฉุกเฉิน hotline เครียด ซึมเศร้า', open: (n) {
        n.pop();
        launchUrl(Uri.parse('tel:1323'));
      }),
    ];
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _recent = prefs.getStringList(_recentKey) ?? []);
    } catch (_) {}
  }

  Future<void> _saveRecent(String id) async {
    final next = [id, ..._recent.where((r) => r != id)].take(6).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, next);
    } catch (_) {}
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _open(_Entry e) {
    _saveRecent(e.id);
    e.open(Navigator.of(context));
  }

  /// คะแนนความตรง: ขึ้นต้นชื่อ > อยู่ในชื่อ > อยู่ในคำค้นเพิ่มเติม
  int _score(_Entry e, String q) {
    final title = e.title.toLowerCase();
    final words = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    var total = 0;
    for (final w in words) {
      if (title.startsWith(w)) {
        total += 3;
      } else if (title.contains(w)) {
        total += 2;
      } else if ('${e.keywords} ${e.subtitle ?? ''} ${e.section}'.toLowerCase().contains(w)) {
        total += 1;
      } else {
        return 0;
      }
    }
    return total;
  }

  _Entry? _byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(context, maxWidth: AppLayout.readingWidth, min: 16);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter - 8, 10, gutter, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'ปิดการค้นหา',
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppSearchField(
                      controller: _controller,
                      hint: 'ค้นหาเมนู รายงาน การตั้งค่า',
                      autofocus: true,
                      onChanged: _onChanged,
                      onSubmitted: (v) {
                        final results = _results(v.trim());
                        if (results.isNotEmpty) _open(results.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 32),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: _query.isEmpty ? _idle() : _resultsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Entry> _results(String q) {
    if (q.isEmpty) return [];
    final scored = [
      for (final e in _entries)
        if (_score(e, q) > 0) (e, _score(e, q)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((s) => s.$1).toList();
  }

  List<Widget> _idle() {
    final recent = _recent.map(_byId).whereType<_Entry>().toList();
    return [
      if (recent.isNotEmpty)
        SettingsGroup(
          title: 'เปิดล่าสุด',
          children: [
            for (final e in recent)
              SettingsTile(
                icon: Icons.history_rounded,
                title: e.title,
                subtitle: e.section,
                onTap: () => _open(e),
              ),
          ],
          footer: null,
        ),
      if (recent.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _clearRecent, child: const Text('ล้างประวัติการค้นหา')),
        ),
      const SectionLabel('ทางลัด'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in _popular)
            if (_byId(id) case final e?)
              ActionChip(
                avatar: Icon(e.icon, size: 16, color: AppColors.inkSoft),
                label: Text(e.title),
                labelStyle: AppTextStyles.small.copyWith(color: AppColors.ink),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
                onPressed: () => _open(e),
              ),
        ],
      ),
    ];
  }

  List<Widget> _resultsView() {
    final results = _results(_query);
    if (results.isEmpty) {
      return [
        const SizedBox(height: 56),
        const Icon(Icons.search_off_rounded, size: 40, color: AppColors.inkFaint),
        const SizedBox(height: 12),
        Text('ไม่พบ "$_query"', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 17)),
        const SizedBox(height: 4),
        Text('ลองคำที่สั้นลง หรือเลือกจากคำเหล่านี้', textAlign: TextAlign.center, style: AppTextStyles.small),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in ['รายงาน', 'Muse', 'รหัสผ่าน', 'แจ้งเตือน', 'PHQ'])
              ActionChip(
                label: Text(word),
                labelStyle: AppTextStyles.small.copyWith(color: AppColors.ink),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.line),
                onPressed: () {
                  _controller.text = word;
                  setState(() => _query = word);
                },
              ),
          ],
        ),
      ];
    }

    // คงลำดับหมวดตามผลที่ตรงที่สุด
    final sections = <String, List<_Entry>>{};
    for (final e in results) {
      sections.putIfAbsent(e.section, () => []).add(e);
    }
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text('${results.length} รายการ', style: AppTextStyles.caption),
      ),
      for (final s in sections.entries)
        SettingsGroup(
          title: s.key,
          children: [
            for (final e in s.value)
              _ResultTile(entry: e, query: _query, onTap: () => _open(e)),
          ],
        ),
    ];
  }
}

/// แถวผลลัพธ์ที่ทำตัวหนาเฉพาะส่วนที่ตรงกับคำค้น
class _ResultTile extends StatelessWidget {
  final _Entry entry;
  final String query;
  final VoidCallback onTap;

  const _ResultTile({required this.entry, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body.copyWith(fontSize: 15);
    final title = entry.title;
    final word = query.split(RegExp(r'\s+')).first.toLowerCase();
    final at = word.isEmpty ? -1 : title.toLowerCase().indexOf(word);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                child: Icon(entry.icon, size: 18, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      at < 0
                          ? TextSpan(text: title)
                          : TextSpan(children: [
                              TextSpan(text: title.substring(0, at)),
                              TextSpan(
                                text: title.substring(at, at + word.length),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDeep),
                              ),
                              TextSpan(text: title.substring(at + word.length)),
                            ]),
                      style: base,
                    ),
                    if (entry.subtitle != null) Text(entry.subtitle!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.north_east_rounded, size: 16, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
