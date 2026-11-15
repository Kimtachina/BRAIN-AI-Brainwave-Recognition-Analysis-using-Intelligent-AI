part of '../eeg_session_screen.dart';

/// รายการเซสชันให้เลือกเริ่มเก็บข้อมูล (แสดงเมื่อยังไม่ได้เริ่มเซสชัน)
extension _SessionList on _EegSessionScreenState {
  Widget _buildSessionList() {
    final isConnected = widget.museService.isConnected;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter(context, maxWidth: AppLayout.contentWidth), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isConnected)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'กรุณาเชื่อมต่อ Muse ก่อนเริ่มเก็บข้อมูล',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          const Text(
            'เลือก Session',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'แต่ละ session จะกระตุ้นอารมณ์ที่แตกต่างกัน พร้อมบันทึก EEG',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),

          ...List.generate(_sessions.length, (i) {
            final s = _sessions[i];
            final colors = s['gradient'] as List<Color>;
            final durationSecs = s['duration'] as int;
            final durationStr = durationSecs % 60 == 0 
                ? '${durationSecs ~/ 60} นาที' 
                : '${durationSecs / 60} นาที';

            return GestureDetector(
              onTap: isConnected ? () => _startSession(i) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected ? colors : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? colors.first : Colors.grey).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15, top: -15,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(s['icon'], color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'],
                                  style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s['description'],
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      durationStr,
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.label, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      s['emotion'],
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('คำแนะนำ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text(
                        'ควรทำ Baseline ก่อนทุกครั้ง และพัก 1-2 นาทีระหว่าง session\nอ้างอิง: DEAP Dataset Protocol (60s/trial), Krigolson et al. 2017',
                        style: TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
