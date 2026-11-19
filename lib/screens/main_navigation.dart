import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import 'home/home_screen.dart';
import 'assessment/phq9_tab_screen.dart';
import 'wellness/recommendation_screen.dart';
import 'profile/profile_screen.dart';
import 'behind/behind_screen.dart';
import 'search/app_search_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page.dart';

/// โครงหลักหลังล็อกอิน
/// จอแคบ: แถบเมนูขาวติดขอบล่าง แสดงชื่อทุกเมนู เมนูที่เลือกอยู่มีขีดสีหลักด้านบน
/// จอกว้าง: แถบเมนูแนวตั้งด้านซ้าย พร้อมชื่อแอปและเส้นคลื่นสมอง
class MainNavigation extends StatefulWidget {
  final User user;

  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _items = [
  _NavItem(Icons.monitor_heart_outlined, Icons.monitor_heart_rounded, 'วันนี้'),
  _NavItem(Icons.checklist_rounded, Icons.checklist_rtl_rounded, 'แบบประเมิน'),
  _NavItem(Icons.forum_outlined, Icons.forum_rounded, 'ผู้ช่วย'),
  _NavItem(Icons.account_tree_outlined, Icons.account_tree_rounded, 'เบื้องหลัง'),
  _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'บัญชี'),
];

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _onUserUpdated(User updatedUser) => setState(() => _currentUser = updatedUser);

  void _select(int index) => setState(() => _currentIndex = index);

  bool _searchOpen = false;

  /// เปิดหน้าค้นหาทั้งแอป (ปุ่มค้นหา หรือ Ctrl/⌘ + K บนเว็บ)
  Future<void> _openSearch() async {
    if (_searchOpen) return;
    _searchOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppSearchScreen(user: _currentUser, onSelectTab: _select, onUserUpdated: _onUserUpdated),
      ),
    );
    _searchOpen = false;
  }

  List<Widget> get _screens => [
        HomeScreen(user: _currentUser, onTabSelected: _select, onSearch: _openSearch),
        Phq9TabScreen(user: _currentUser),
        RecommendationScreen(user: _currentUser),
        BehindScreen(active: _currentIndex == 3, onConnect: () => _select(0)),
        ProfileScreen(
          user: _currentUser,
          onUserUpdated: _onUserUpdated,
          onSearch: _openSearch,
          onSelectTab: _select,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openSearch,
      },
      child: Focus(autofocus: true, child: _buildShell(context)),
    );
  }

  Widget _buildShell(BuildContext context) {
    // พื้นฉากกลางคืนชุดเดียวกับหน้าแรก วางไว้ใต้ทุกแท็บ
    final body = AppBackground(child: IndexedStack(index: _currentIndex, children: _screens));

    if (AppLayout.isWide(context)) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Row(
          children: [
            _SideRail(current: _currentIndex, onSelect: _select, onSearch: _openSearch),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
            Expanded(child: ShellInset(left: 233, child: body)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _BottomItem(
                      item: _items[i],
                      active: i == _currentIndex,
                      onTap: () => _select(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.inkFaint;
    return Semantics(
      selected: active,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.94,
        semanticLabel: item.label,
        child: Column(
          children: [
            // ขีดบอกเมนูที่เลือก ยืดจากกลางออกไปทั้งสองข้าง
            AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.easeOut,
              height: 2,
              width: active ? 28 : 0,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1)),
            ),
            const Spacer(),
            Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  final VoidCallback onSearch;

  const _SideRail({required this.current, required this.onSelect, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.night,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Smart Brain', style: AppTextStyles.heading.copyWith(fontSize: 19, letterSpacing: -0.3)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 6, 12, 20),
            child: BrainLine(height: 22, strokeWidth: 1.2),
          ),
          // ช่องค้นหาแบบ command palette (GitHub / Notion / Linear) พร้อมคีย์ลัด
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              button: true,
              label: 'ค้นหา',
              child: Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  onTap: onSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: AppColors.inkFaint),
                        const SizedBox(width: 10),
                        Expanded(child: Text('ค้นหา', style: AppTextStyles.small.copyWith(color: AppColors.inkFaint))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS
                                ? '⌘K'
                                : 'Ctrl K',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                selected: i == current,
                child: Material(
                  color: i == current ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(
                            i == current ? _items[i].activeIcon : _items[i].icon,
                            size: 20,
                            color: i == current ? AppColors.primaryDeep : AppColors.inkSoft,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _items[i].label,
                            style: AppTextStyles.small.copyWith(
                              fontSize: 14.5,
                              color: i == current ? AppColors.primaryDeep : AppColors.inkSoft,
                              fontWeight: i == current ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
