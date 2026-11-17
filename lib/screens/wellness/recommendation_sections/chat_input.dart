part of '../recommendation_screen.dart';

/// ส่วนล่างของหน้าแชท: คำถามแนะนำ แถบสถานะการฟังเสียง และช่องพิมพ์ข้อความ
extension _ChatInput on _RecommendationScreenState {
  Widget _buildSuggestedQuestionsArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'คำถามแนะนำเพื่อเจาะลึก:',
                style: GoogleFonts.ibmPlexSansThai(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _suggestedQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () => _onSuggestionTap(question),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: AppTheme.glassDecoration(
                        color: Colors.white,
                        opacity: 0.9,
                        borderColor: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            question,
                            style: GoogleFonts.ibmPlexSansThai(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceListeningBar() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.glassDecoration(
            color: AppColors.deepSpaceBlue,
            opacity: 0.9,
            borderColor: AppColors.electricCyan.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _micPulseController,
                builder: (context, child) {
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withValues(
                        alpha: 0.2 + (_micPulseController.value * 0.3),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricCyan.withValues(
                            alpha: 0.2 * _micPulseController.value,
                          ),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: AppColors.electricCyan, size: 20),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partialText.isNotEmpty ? _partialText : 'กำลังรับสัญญาณเสียง... พูดได้เลย',
                      style: GoogleFonts.ibmPlexSansThai(
                        color: _partialText.isNotEmpty ? Colors.white : AppColors.inkFaint,
                        fontSize: 13.5,
                        fontWeight: _partialText.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (_partialText.isEmpty)
                      Row(
                        children: List.generate(8, (i) =>
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              final height = 4.0 + (12.0 * _waveController.value * (i % 3 == 0 ? 1.0 : (i % 3 == 1 ? 0.6 : 0.3)));
                              return Container(
                                width: 3,
                                height: height,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: (i % 2 == 0 ? AppColors.electricCyan : AppColors.neonGreen).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _sttService.cancelListening();
                  _refresh(() {
                    _isVoiceMode = false;
                    _partialText = '';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 24),
      decoration: AppTheme.glassDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        opacity: 0.9,
        borderColor: Colors.white.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          // Voice Input Mic Button
          GestureDetector(
            onTap: _isSending ? null : _toggleVoiceInput,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isVoiceMode
                    ? AppColors.electricCyan
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: _isVoiceMode ? [
                  BoxShadow(
                    color: AppColors.electricCyan.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Icon(
                _isVoiceMode ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isVoiceMode ? Colors.black87 : AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Message Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              height: 48,
              alignment: Alignment.center,
              decoration: AppTheme.glassDecoration(
                color: AppColors.paper,
                opacity: 0.6,
                borderColor: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.ibmPlexSansThai(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อมูลหรือสั่งงานด้วยเสียง...',
                  hintStyle: GoogleFonts.ibmPlexSansThai(
                    color: AppColors.inkFaint,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send Message Button
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isSending ? null : AppGradients.primary,
                color: _isSending ? Colors.grey.shade300 : null,
                shape: BoxShape.circle,
                boxShadow: _isSending ? [] : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
