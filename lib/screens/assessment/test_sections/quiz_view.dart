part of '../test_screen.dart';

/// หน้าตอบคำถามทีละข้อ
extension _QuizView on _TestScreenState {
  Widget _buildQuiz() {
    final question = _phq9Questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _phq9Questions.length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter(context, maxWidth: AppLayout.readingWidth), vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Text(
                  'ข้อ ${_currentQuestion + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  ' / ${_phq9Questions.length}',
                  style: TextStyle(fontSize: 14, color: AppColors.inkFaint),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _phq9Instruction,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question['question']!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question['en']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaint,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(_answerOptions.length, (index) {
              final isSelected = _selectedAnswer == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                            ? AppColors.primary
                            : AppColors.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                ? AppColors.primary
                                : AppColors.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _answerOptions[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? AppColors.primary : AppColors.ink,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            if (_currentQuestion == 8)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'หากคุณมีความคิดทำร้ายตัวเอง กรุณาโทรสายด่วนสุขภาพจิต 1323 ตลอด 24 ชม.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
