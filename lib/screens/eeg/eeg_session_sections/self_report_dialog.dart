part of '../eeg_session_screen.dart';

/// หน้าต่างให้ผู้ใช้รายงานอารมณ์ของตัวเองหลังจบเซสชัน แล้วบันทึกผล
extension _SelfReportDialog on _EegSessionScreenState {
  void _showSelfReportDialog() {
    int valence = 5;
    int arousal = 5;
    bool isSaving = false;
    final session = _sessions[_currentSessionIndex];

    final n = _samplesCollected > 0 ? _samplesCollected : 1;
    final avgA = _totalAlpha / n;
    final avgB = _totalBeta / n;
    final avgT = _totalTheta / n;
    final avgD = _totalDelta / n;
    final avgG = _totalGamma / n;

    final eval = _evaluateEEG(session['emotion'], avgA, avgB, avgT, avgD, avgG);
    final isMatch = eval['isMatch'] as bool;
    final feedback = eval['feedback'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: session['color'], size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Session "${session['name']}" เสร็จสิ้น',
                    style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เก็บได้ $_samplesCollected samples ใน $_elapsedSeconds วินาที',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 12),
              
              // ─── การตรวจสอบผลลัพธ์คลื่นสมองเบื้องต้น ───
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMatch ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isMatch ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isMatch ? Icons.check_circle_outline : Icons.info_outline,
                          color: isMatch ? Colors.green[700] : Colors.orange[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMatch ? 'สรุป: ตรงตามเป้าหมาย ($feedback)' : 'สรุป: ยังไม่ตรงเป้า ($feedback)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMatch ? Colors.green[800] : Colors.orange[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((eval['details'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 8),
                      ...(eval['details'] as List).map((d) {
                        final p = d['pass'] as bool;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1.5),
                                child: Icon(
                                  p ? Icons.check_circle : Icons.cancel,
                                  color: p ? Colors.green[600] : Colors.red[400],
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  d['text'] as String,
                                  style: TextStyle(
                                    fontSize: 11.5, 
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('ตอนนี้คุณรู้สึกอย่างไร?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('เศร้า', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: valence.toDouble(),
                      min: 1, max: 9,
                      divisions: 8,
                      label: '$valence',
                      onChanged: (v) => setDialogState(() => valence = v.round()),
                    ),
                  ),
                  const Text('สุข', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  const Text('สงบ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: arousal.toDouble(),
                      min: 1, max: 9,
                      divisions: 8,
                      label: '$arousal',
                      onChanged: (v) => setDialogState(() => arousal = v.round()),
                    ),
                  ),
                  const Text('ตื่นเต้น', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('ไม่ได้บันทึก Session นี้',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      backgroundColor: Colors.grey[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('ไม่บันทึก',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
            const SizedBox(height: 8),

            // Warning when results don't match session target
            if (!isMatch) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFFE65100), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ผลคลื่นสมองยังไม่ตรงตาม Session "${ session['name'] }" ไม่สามารถบันทึกได้ — ลองทำ Session ใหม่อีกครั้ง',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!isMatch || isSaving)
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);

                        final n = _samplesCollected > 0 ? _samplesCollected : 1;
                        final result = await ApiService.saveEmotionSession(
                          userId: widget.user.id,
                          targetEmotion: session['emotion'],
                          activityType: session['activity'],
                          sessionName: session['name'],
                          durationSeconds: _elapsedSeconds,
                          samplesCollected: _samplesCollected,
                          avgAlpha: _totalAlpha / n,
                          avgBeta: _totalBeta / n,
                          avgTheta: _totalTheta / n,
                          avgDelta: _totalDelta / n,
                          avgGamma: _totalGamma / n,
                          selfReportValence: valence,
                          selfReportArousal: arousal,
                          isCompleted: _elapsedSeconds >= (session['duration'] as int),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          final success = result['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    success ? Icons.check_circle_rounded : Icons.error_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          success
                                              ? 'บันทึก Session "${session['name']}" สำเร็จ!'
                                              : 'บันทึกไม่สำเร็จ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (success)
                                          Text(
                                            '$_samplesCollected samples · Valence: $valence · Arousal: $arousal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: success
                                  ? const Color(0xFF11998e)
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isMatch ? Icons.save_rounded : Icons.lock_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  isSaving
                      ? 'กำลังบันทึก...'
                      : isMatch
                          ? 'บันทึก'
                          : 'ไม่สามารถบันทึกได้',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMatch ? session['color'] : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
