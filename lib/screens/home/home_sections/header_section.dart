part of '../home_screen.dart';

/// ส่วนหัวของหน้าหลัก: แบนเนอร์ต้อนรับ รูปโปรไฟล์ ชื่อผู้ใช้ วันที่ สถานะระบบ และปุ่มตั้งค่า
extension _HeaderSection on _HomeScreenState {
  Widget _buildHeader({bool wide = false}) {
    final name = widget.user.fullName ?? widget.user.username;
    final hasAvatar = widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty;
    final isConnected = _museService.isConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0458B8), Color(0xFF046BD2), Color(0xFF0791C4), Color(0xFF00A79D)],
            stops: [0.0, 0.4, 0.75, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ลายตารางจางและวงกลมประดับพื้นหลัง
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              Positioned(
                right: -50,
                top: -70,
                child: _heroCircle(220, 0.09),
              ),
              Positioned(
                right: 90,
                bottom: -90,
                child: _heroCircle(170, 0.07),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 28 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: wide ? 64 : 54,
                          height: wide ? 64 : 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            image: hasAvatar
                                ? DecorationImage(
                                    image: NetworkImage(widget.user.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: hasAvatar
                              ? null
                              : Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontSize: wide ? 24 : 21,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()} • ผู้เข้ารับการทดสอบ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: wide ? 26 : 21,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'ตั้งค่า',
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: CircleBorder(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)));
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(11),
                                child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: wide ? 20 : 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _heroChip(
                          leading: const PulseDot(color: AppColors.neonGreen, size: 6),
                          label: 'ระบบพร้อมทำงาน',
                        ),
                        _heroChip(
                          leading: Icon(
                            isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          label: isConnected ? 'Muse เชื่อมต่อแล้ว' : 'Muse ยังไม่เชื่อมต่อ',
                        ),
                        _heroChip(
                          leading: const Icon(Icons.badge_outlined, color: Colors.white, size: 13),
                          label: 'รหัสผู้ป่วย: EEG-${widget.user.id.toString().padLeft(8, '0')}',
                        ),
                        _heroChip(
                          leading: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                          label: _formatCurrentDate(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  /// ป้ายข้อมูลแบบกระจกบนแบนเนอร์
  Widget _heroChip({required Widget leading, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
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
