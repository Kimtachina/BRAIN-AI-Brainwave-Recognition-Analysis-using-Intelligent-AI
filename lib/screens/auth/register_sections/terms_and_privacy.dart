part of '../register_screen.dart';

/// หน้าต่างแสดงข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว
extension _TermsAndPrivacy on _RegisterScreenState {
  void _showTermsAndPrivacyBottomSheet(BuildContext context, {required int initialTab}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialTab,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // แถบจับด้านบน
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 8),
                // หัวข้อ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ข้อตกลงและนโยบาย',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // แท็บเลือกหมวด
                TabBar(
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textGray,
                  indicatorColor: AppColors.primaryBlue,
                  labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.prompt(fontWeight: FontWeight.normal, fontSize: 14),
                  tabs: const [
                    Tab(text: 'เงื่อนไขการใช้งาน'),
                    Tab(text: 'นโยบายความเป็นส่วนตัว'),
                  ],
                ),
                // เนื้อหา
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTermsContent(),
                      _buildPrivacyContent(),
                    ],
                  ),
                ),
                // ปุ่มยอมรับ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _refresh(() {
                            _agreeToTerms = true;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ยอมรับและดำเนินการต่อ',
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsContent() {
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

  Widget _buildPrivacyContent() {
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

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: GoogleFonts.prompt(
        fontSize: 13,
        color: AppColors.textDark,
        height: 1.6,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.prompt(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.prompt(
        fontSize: 13,
        color: AppColors.textGray,
        height: 1.6,
      ),
    );
  }
}
