part of '../home_screen.dart';

/// ส่วนหัวของหน้าหลัก: คำทักทาย ชื่อ ปุ่มตั้งค่า (รูปโปรไฟล์) เส้นคลื่นสมอง และสถานะ Muse
extension _HeaderSection on _HomeScreenState {
  Widget _buildHeader({bool wide = false}) {
    final name = widget.user.fullName ?? widget.user.username;
    final isConnected = _museService.isConnected;
    final statusColor = isConnected ? AppColors.secondary : AppColors.inkFaint;

    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 32 : 20, wide ? 32 : 20, wide ? 32 : 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: AppTextStyles.small),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTextStyles.title.copyWith(fontSize: wide ? 30 : 26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onSearch != null) ...[
                Tooltip(
                  message: 'ค้นหา',
                  child: Pressable(
                    semanticLabel: 'ค้นหา',
                    onTap: widget.onSearch,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.search_rounded, size: 21, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // รูปโปรไฟล์ไปหน้าบัญชี (แบบแอปใหญ่) ถ้าไม่มีแท็บให้เปิดหน้าตั้งค่าแทน
              Tooltip(
                message: 'บัญชี',
                child: Pressable(
                  semanticLabel: 'บัญชี',
                  onTap: () {
                    if (widget.onTabSelected != null) {
                      widget.onTabSelected!(4);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
                      );
                    }
                  },
                  child: UserAvatar(name: name, url: widget.user.avatarUrl, size: 44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // เส้นคลื่นสมองประจำวัน: จางเมื่อยังไม่ต่อ Muse และเข้มขึ้นเมื่อเชื่อมต่อแล้ว
          BrainLine(
            height: wide ? 44 : 36,
            strokeWidth: 1.4,
            color: isConnected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
            seed: DateTime.now().day,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConnected ? 'Muse เชื่อมต่อแล้ว' : 'Muse ยังไม่เชื่อมต่อ',
                  style: AppTextStyles.small.copyWith(color: AppColors.ink),
                ),
              ),
              Text(_formatCurrentDate(), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return 'วันที่ ${now.day} ${months[now.month - 1]} ${now.year + 543}';
  }
}
