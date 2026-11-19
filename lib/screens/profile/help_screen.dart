import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

/// HelpScreen เป็นหน้าจอสำหรับแสดงคู่มือช่วยเหลือแนะนำการใช้แอปพลิเคชัน
/// อธิบายวิธีการใช้งานหน้าฟังก์ชันหลัก รวมถึงช่องทางการติดต่อขอรับความช่วยเหลือด่วน
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppPageBar(context, title: 'ช่วยเหลือ'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter(context), vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยินดีต้อนรับสู่ SmartBrain Care',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เราพร้อมดูแลสุขภาพสมองของคุณ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'วิธีใช้งาน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.quiz_outlined,
              iconColor: Colors.blue,
              title: 'แบบทดสอบ PHQ-9',
              description: 'ทำแบบทดสอบเพื่อประเมินสุขภาพจิตของคุณ ผลลัพธ์จะบันทึกไว้ในประวัติ',
            ),
            _buildFeatureCard(
              icon: Icons.games_outlined,
              iconColor: Colors.green,
              title: 'เกมบริหารสมอง',
              description: 'เล่นเกมฝึกสมอง เช่น เกมจำ, ปริศนาตัวเลข, ลำดับสี เพื่อเสริมสร้างความจำและสมาธิ',
            ),
            _buildFeatureCard(
              icon: Icons.history,
              iconColor: Colors.orange,
              title: 'ดูประวัติ',
              description: 'ดูประวัติผลการทดสอบทั้งหมดของคุณ ติดตามความเปลี่ยนแปลงของสุขภาพจิต',
            ),
            _buildFeatureCard(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.purple,
              title: 'แชทคำแนะนำ AI',
              description: 'พูดคุยกับ AI เพื่อรับคำแนะนำด้านสุขภาพจิต พร้อมระบบ RAG ที่ให้ข้อมูลแม่นยำ',
            ),
            _buildFeatureCard(
              icon: Icons.bluetooth,
              iconColor: Colors.indigo,
              title: 'เชื่อมต่อ Muse S',
              description: 'เชื่อมต่ออุปกรณ์ Muse S เพื่อวัดคลื่นสมอง EEG แบบ real-time',
            ),

            const SizedBox(height: 24),

            Text(
              'ติดต่อเรา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            _buildContactCard(
              icon: Icons.phone,
              iconColor: Colors.green,
              title: 'สายด่วนสุขภาพจิต',
              value: '1323',
              onTap: () => _launchUrl('tel:1323'),
            ),
            _buildContactCard(
              icon: Icons.email,
              iconColor: Colors.blue,
              title: 'อีเมล',
              value: 'support@smartbrain.com',
              onTap: () => _launchUrl('mailto:support@smartbrain.com'),
            ),

            const SizedBox(height: 24),

            Text(
              'ข้อมูลเพิ่มเติม',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'เวอร์ชัน',
              value: 'v1.1.1',
            ),
            _buildInfoCard(
              icon: Icons.shield_outlined,
              title: 'นโยบายความเป็นส่วนตัว',
              value: 'ข้อมูลของคุณปลอดภัย',
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.inkFaint,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkFaint, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.inkSoft,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
