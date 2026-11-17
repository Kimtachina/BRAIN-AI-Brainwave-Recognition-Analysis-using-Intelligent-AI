import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_page.dart';

/// เนื้อหาเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว ใช้ร่วมกันระหว่างหน้าสมัครสมาชิกและหน้าตั้งค่า
class PolicyContent {
  PolicyContent._();

  static Widget terms() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('เงื่อนไขการใช้บริการแอปพลิเคชัน (Terms of Use)'),
          const SizedBox(height: 12),
          _buildSectionText(
            'ยินดีต้อนรับสู่แอปพลิเคชันวิเคราะห์สภาวะสมองและอารมณ์ของเรา กรุณาอ่านและทำความเข้าใจข้อตกลงและเงื่อนไขการใช้บริการนี้โดยละเอียดก่อนเริ่มต้นใช้งาน',
          ),
          const Divider(height: 32),
          _buildSectionTitle('1. วัตถุประสงค์และการจำกัดความรับผิดชอบ'),
          _buildSectionBody(
            'แอปพลิเคชันนี้ออกแบบมาสำหรับการประเมินสภาวะทางอารมณ์ ระดับความเครียด และการฝึกสมาธิเบื้องต้นผ่านสัญญาณคลื่นไฟฟ้าสมอง (EEG) ผลลัพธ์และคำแนะนำทั้งหมดใช้เพื่อวัตถุประสงค์ในการศึกษา ติดตามแนวโน้มส่วนบุคคล และเพื่อความบันเทิงเท่านั้น "ไม่ใช่ข้อมูลวินิจฉัยทางการแพทย์" และไม่สามารถใช้ทดแทนคำปรึกษาจากแพทย์ผู้เชี่ยวชาญได้',
          ),
          _buildSectionTitle('2. ความรับผิดชอบต่อบัญชีผู้ใช้'),
          _buildSectionBody(
            'ผู้ใช้บริการตกลงที่จะให้ข้อมูลที่เป็นจริง ถูกต้อง และเป็นปัจจุบันในการลงทะเบียนเข้าใช้งาน และมีหน้าที่รักษาความลับของชื่อผู้ใช้งานและรหัสผ่าน หากตรวจพบกิจกรรมที่น่าสงสัยเกี่ยวกับการใช้งานบัญชีผู้ใช้ คุณตกลงที่จะแจ้งให้ทีมงานทราบทันที',
          ),
          _buildSectionTitle('3. การเชื่อมต่ออุปกรณ์ตรวจวัด'),
          _buildSectionBody(
            'การประมวลผลคลื่นสมองในแอปพลิเคชันจำเป็นต้องเชื่อมต่อกับอุปกรณ์ตรวจวัดสัญญาณสมองที่รองรับ (เช่น แถบคาดศีรษะ Muse) ผู้ใช้บริการต้องมีอุปกรณ์ดังกล่าวและมีหน้าที่รับผิดชอบต่อความเสี่ยง ความปลอดภัย และการจัดเก็บแบตเตอรี่ของอุปกรณ์ตนเอง',
          ),
          _buildSectionTitle('4. การจำกัดสิทธิ์และการอนุญาตสิทธิ์การใช้งาน'),
          _buildSectionBody(
            'ทางระบบมอบสิทธิ์การใช้งานแอปพลิเคชันแบบจำกัด ไม่สามารถโอนสิทธิ์ได้ และห้ามนำโค้ด ส่วนติดต่อผู้ใช้ หรือข้อมูลในแอปพลิเคชันไปดัดแปลง คัดลอก หรือนำไปใช้ในเชิงพาณิชย์โดยไม่ได้รับความยินยอมเป็นลายลักษณ์อักษรจากเรา',
          ),
          _buildSectionTitle('5. การปรับปรุงและการยุติการให้บริการ'),
          _buildSectionBody(
            'เราขอสงวนสิทธิ์ในการปรับปรุง เปลี่ยนแปลง หรือยุติการให้บริการส่วนใดส่วนหนึ่ง หรือทั้งหมดของแอปพลิเคชัน โดยอาจจะมีการแจ้งให้ผู้ใช้ทราบล่วงหน้าผ่านทางระบบ',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget privacy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('นโยบายความเป็นส่วนตัว (Privacy Policy)'),
          const SizedBox(height: 12),
          _buildSectionText(
            'เราตระหนักถึงความสำคัญของข้อมูลส่วนบุคคลของคุณ นโยบายนี้อธิบายถึงวิธีการจัดเก็บ นำไปใช้ และปกป้องข้อมูลของคุณเมื่อใช้งานแอปพลิเคชันนี้',
          ),
          const Divider(height: 32),
          _buildSectionTitle('1. ข้อมูลที่เราจัดเก็บและวิธีจัดเก็บ'),
          _buildSectionBody(
            '- ข้อมูลส่วนตัวพื้นฐาน: ชื่อผู้ใช้งาน, อีเมล, เบอร์โทรศัพท์ และวันเกิด สำหรับการลงทะเบียนและระบุตัวตน\n'
            '- ข้อมูลสรีรวิทยาและสมอง: สัญญาณคลื่นไฟฟ้าสมองดิบ (Raw EEG data) ที่ตรวจวัดได้จากอุปกรณ์เชื่อมต่อ, ระดับคลื่นสมองแยกตามย่านความถี่ (Alpha, Beta, Gamma, Delta, Theta)\n'
            '- ข้อมูลผลลัพธ์การใช้งาน: ผลการประเมินสมาธิ, คะแนนความผ่อนคลาย, และระดับสภาวะทางอารมณ์',
          ),
          _buildSectionTitle('2. การนำข้อมูลไปใช้งาน'),
          _buildSectionBody(
            'เรานำข้อมูลที่รวบรวมมาใช้เพื่อ:\n'
            '- ประมวลผลและจำลองความเปลี่ยนแปลงทางอารมณ์ สมาธิ และทัศนคติในแอปพลิเคชัน\n'
            '- พัฒนาและปรับปรุงอัลกอริทึมการเรียนรู้ของเครื่อง (Machine Learning) ให้มีความแม่นยำยิ่งขึ้น\n'
            '- แสดงรายงานประวัติย้อนหลังและข้อมูลสรุปเพื่อการดูแลสุขภาพทางใจส่วนตัวของคุณ',
          ),
          _buildSectionTitle('3. การรักษาความปลอดภัยและความเป็นส่วนตัว'),
          _buildSectionBody(
            'ข้อมูลคลื่นสมองและสุขภาพของคุณถือเป็นความลับสูงสุด เราใช้มาตรการเข้ารหัสข้อมูล (Encryption) ทั้งในส่วนการส่งผ่านข้อมูลและการจัดเก็บ และจะไม่เปิดเผย ขาย หรือแบ่งปันข้อมูลส่วนบุคคลของท่านแก่บุคคลภายนอก เว้นแต่จะได้รับความยินยอมโดยชัดแจ้งจากท่าน',
          ),
          _buildSectionTitle('4. สิทธิ์ของเจ้าของข้อมูลส่วนบุคคล'),
          _buildSectionBody(
            'คุณมีสิทธิ์เข้าถึง ขอรับสำเนา ขอให้แก้ไข หรือขอให้ลบข้อมูลส่วนบุคคลทั้งหมดรวมถึงประวัติคลื่นสมองของคุณออกจากฐานข้อมูลของเราเมื่อใดก็ได้ โดยสามารถทำเรื่องผ่านเมนูการตั้งค่า หรือติดต่อฝ่ายสนับสนุนของเรา',
          ),
          _buildSectionTitle('5. การติดต่อเรา'),
          _buildSectionBody(
            'หากคุณมีข้อสงสัยหรือข้อคำถามเกี่ยวกับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัวนี้ สามารถติดต่อทีมงานผู้พัฒนาผ่านช่องทางติดต่อในแอปพลิเคชัน',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  static Widget _buildSectionText(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        color: AppColors.ink,
        height: 1.6,
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }

  static Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        color: AppColors.inkSoft,
        height: 1.6,
      ),
    );
  }
}

/// หน้าเต็มสำหรับอ่านเงื่อนไขและนโยบาย เปิดจากหน้าตั้งค่า
class PolicyScreen extends StatelessWidget {
  final int initialTab;

  const PolicyScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: buildAppPageBar(context, title: 'เงื่อนไขและนโยบาย'),
        body: Column(
          children: [
            ColoredBox(
              color: AppColors.surface,
              child: TabBar(
                labelColor: AppColors.primaryDeep,
                unselectedLabelColor: AppColors.inkSoft,
                indicatorColor: AppColors.primary,
                dividerColor: AppColors.line,
                labelStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: AppTextStyles.small.copyWith(fontSize: 14),
                tabs: const [Tab(text: 'เงื่อนไขการใช้งาน'), Tab(text: 'นโยบายความเป็นส่วนตัว')],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppLayout.readingWidth),
                  child: TabBarView(children: [PolicyContent.terms(), PolicyContent.privacy()]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
