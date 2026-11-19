part of '../recommendation_screen.dart';

/// กล่องข้อความแชทของผู้ใช้และบอท
extension _MessageBubble on _RecommendationScreenState {
  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isSpeaking = _speakingMessageIndex == index;

    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: math.min(MediaQuery.of(context).size.width * 0.82, 720),
        ),
        child: Column(
          crossAxisAlignment: message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Message Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: message.isBot
                  ? AppTheme.glassDecoration(
                      color: Colors.white,
                      opacity: 0.9,
                      borderColor: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                      ),
                    )
                  : AppTheme.glassDecoration(
                      color: AppColors.primary,
                      opacity: 0.9,
                      borderColor: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot label
                  if (message.isBot) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.android_rounded, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'AI CLINICAL ADVISOR',
                          style: GoogleFonts.ibmPlexSansThai(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    message.text,
                    style: GoogleFonts.ibmPlexSansThai(
                      color: message.isBot ? AppColors.ink : Colors.white,
                      fontSize: 14.5,
                      height: 1.55,
                      fontWeight: message.isBot ? FontWeight.w500 : FontWeight.w500,
                    ),
                  ),
                  if (message.isBot && message.text.contains('🤖 กำลังนำคุณไปยังหน้า')) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Widget dest;
                        if (message.text.contains('หน้าเกมเสริมทักษะ')) {
                          dest = MiniGamesScreen(user: widget.user);
                        } else if (message.text.contains('แบบประเมินสุขภาพจิต PHQ-9')) {
                          dest = TestScreen(user: widget.user);
                        } else if (message.text.contains('คำแนะนำโภชนาการ')) {
                          dest = const NutritionScreen();
                        } else if (message.text.contains('รายงานสรุปประจำสัปดาห์')) {
                          dest = WeeklyReportScreen(user: widget.user);
                        } else {
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => dest),
                        );
                      },
                      icon: const Icon(Icons.rocket_launch_rounded, size: 14, color: AppColors.night),
                      label: Text(
                        'ไปทันที',
                        style: GoogleFonts.ibmPlexSansThai(
                          color: AppColors.night,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Message Metadata (Time and TTS trigger)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.time,
                    style: GoogleFonts.ibmPlexSansThai(
                      color: AppColors.inkFaint,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (message.isBot) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _speakMessage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : AppColors.inkFaint.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: isSpeaking
                              ? Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                              size: 14,
                              color: isSpeaking ? AppColors.secondary : AppColors.inkFaint,
                            ),
                            if (isSpeaking) ...[
                              const SizedBox(width: 4),
                              Text(
                                'กำลังอ่านออกเสียง',
                                style: GoogleFonts.ibmPlexSansThai(
                                  fontSize: 9,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
