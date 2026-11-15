part of '../home_screen.dart';

/// 3. เมนูลัด: เก็บข้อมูล EEG, แบบประเมิน PHQ-9 และมินิเกม
extension _QuickActionsSection on _HomeScreenState {
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เมนูการประเมินและเก็บข้อมูลคลื่นสมอง',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildFeaturedEegSessionCard(context),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              context,
              icon: Icons.assignment_outlined,
              title: 'แบบประเมินสุขภาพจิต (PHQ-9)',
              subtitle: 'ประเมินระดับความเครียดและภาวะอารมณ์ด้วยเกณฑ์มาตรฐานสากล',
              iconColor: AppColors.primaryBlue,
              onTap: () {
                widget.onTabSelected?.call(1);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              context,
              icon: Icons.psychology_outlined,
              title: 'มินิเกมฝึกฝนทักษะสมอง',
              subtitle: 'กิจกรรมกระตุ้นการทำงานด้านความคิด ความจำ และสมาธิ (Cognitive Tasks)',
              iconColor: AppColors.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MiniGamesScreen(user: widget.user),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// สร้างบัตรปุ่มกดสำหรับเปิดหน้าเก็บบันทึกข้อมูลอารมณ์คลื่นสมอง (EEG Session Screen)
  /// ออกแบบเป็นสไตล์พรีเมียม ไฮเทค ตามภาพดีไซน์ที่กำหนด มีลายเส้นตาราง Grid สีจางที่พื้นหลัง
  /// และมีปุ่มวงกลมสีขาวบรรจุลูกศรนำทางชี้ไปข้างหน้า
  Widget _buildFeaturedEegSessionCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: HoverLift(child: GestureDetector(
        onTap: () {
          // นำทางผู้ใช้ไปยังหน้าจอการเก็บบันทึกข้อมูลคลื่นสมองและอารมณ์จริง EegSessionScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EegSessionScreen(
                user: widget.user,
                museService: _museService, // ส่งมอบ service สัญญาณบลูทูธของอุปกรณ์ Muse ไปร่วมใช้งาน
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 125,
          decoration: AppTheme.glassDecoration(
            color: AppColors.primaryBlue,
            opacity: 0.15,
            borderColor: AppColors.primaryBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // ลายเส้นกริดตารางจำลองจอวิเคราะห์สัญญาณแบบจาง
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(color: AppColors.primaryBlue.withValues(alpha: 0.04)),
                ),
              ),
              // วงกลมประดับพื้นหลังด้านขวาบนเพื่อความสมมาตรทางดีไซน์
              Positioned(
                right: -15,
                top: -15,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // กล่องแสดงไอคอนสมองทรงพรีเมียมสีฟ้าอ่อนตัดน้ำเงินเข้ม
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.primaryBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    // ส่วนแสดงชื่อปุ่มและคำบรรยายวัตถุประสงค์การวัดผล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'บันทึกข้อมูลอารมณ์',
                                style: GoogleFonts.prompt(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // วงกลมจุดสีเขียวบ่งบอกสถานะการวัดแบบเรียลไทม์
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.neonGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เชื่อมต่อเซนเซอร์ EEG เพื่อเริ่มทำการบันทึกและประเมินจิตวิทยาคลินิก',
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              color: AppColors.textGray,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ปุ่มวงกลมสีขาวบรรจุไอคอนหัวลูกศรชี้ไปขวาตามรูปต้นแบบดีไซน์
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return HoverLift(child: Container(
      width: double.infinity,
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: 0.75,
        borderColor: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconColor.withValues(alpha: 0.15), width: 0.8),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGray,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: iconColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
