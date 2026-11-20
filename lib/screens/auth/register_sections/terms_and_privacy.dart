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
              color: AppColors.nightSurface,
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
                    color: AppColors.nightLine,
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
                        style: GoogleFonts.ibmPlexSansThai(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
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
                  labelColor: AppColors.alphaWave,
                  unselectedLabelColor: AppColors.inkSoft,
                  indicatorColor: AppColors.alphaWave,
                  labelStyle: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.ibmPlexSansThai(fontWeight: FontWeight.normal, fontSize: 14),
                  tabs: const [
                    Tab(text: 'เงื่อนไขการใช้งาน'),
                    Tab(text: 'นโยบายความเป็นส่วนตัว'),
                  ],
                ),
                // เนื้อหา
                Expanded(
                  child: TabBarView(
                    children: [
                      PolicyContent.terms(),
                      PolicyContent.privacy(),
                    ],
                  ),
                ),
                // ปุ่มยอมรับ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.nightSurface,
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
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.night,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ยอมรับและดำเนินการต่อ',
                          style: GoogleFonts.ibmPlexSansThai(
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
}
