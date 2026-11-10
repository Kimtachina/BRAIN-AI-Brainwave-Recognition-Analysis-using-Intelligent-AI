part of '../home_screen.dart';

/// 5. พลังคลื่นสมอง 5 ย่านความถี่ (EEG band power) และกราฟคลื่นดิบ
extension _BandPowerSection on _HomeScreenState {
  Widget _buildBandPowerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: 0.7,
        borderColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'วิเคราะห์ช่องสัญญาณคลื่นสมอง (EEG Bands)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_museService.isConnected && _museService.latestData != null)
                      ? AppColors.primaryGreen.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(
                      color: (_museService.isConnected && _museService.latestData != null)
                          ? AppColors.primaryGreen
                          : Colors.grey,
                      size: 6,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (_museService.isConnected && _museService.latestData != null)
                          ? (_museService.isSimulating ? 'จำลองสัญญาณ' : 'เรียลไทม์')
                          : 'STANDBY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: (_museService.isConnected && _museService.latestData != null)
                            ? AppColors.primaryGreen
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (_museService.isConnected && _museService.latestData != null)
                ? 'ความเข้มของคลื่นสัญญาณสมองในแต่ละย่านความถี่ (ความถี่สุ่ม 256Hz)'
                : 'กรุณาเชื่อมต่ออุปกรณ์ Muse เพื่อเริ่มอ่านคลื่นสมองแบบสด',
            style: const TextStyle(fontSize: 13, color: AppColors.textGray),
          ),
          const SizedBox(height: 18),

          // รูปแบบเลย์เอาต์ยืดหยุ่นรองรับการแสดงผลความแรงคลื่นสมอง 5 ย่านความถี่ (Wrap แทนที่จะใช้การเลื่อนแนวนอน)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              int columns = 2;
              if (availableWidth >= 560) {
                columns = 5;
              } else if (availableWidth >= 340) {
                columns = 3;
              } else {
                columns = 2;
              }

              const spacing = 8.0;
              final cardWidth = (availableWidth - (columns - 1) * spacing) / columns;
              final hasData = _museService.isConnected && _museService.latestData != null;
              final rawVals = hasData
                  ? [
                      _museService.latestData!.delta,
                      _museService.latestData!.theta,
                      _museService.latestData!.alpha,
                      _museService.latestData!.beta,
                      _museService.latestData!.gamma,
                    ]
                  : [0.0, 0.0, 0.0, 0.0, 0.0];

              // แปลงสัดส่วนเป็นเปอร์เซ็นต์ (Normalized percentages)
              final double sumRaw = rawVals.reduce((a, b) => a + b);
              final List<double> pctVals = sumRaw > 0
                  ? rawVals.map((v) => (v / sumRaw) * 100.0).toList()
                  : [0.0, 0.0, 0.0, 0.0, 0.0];

              // ปรับแต่งโดยใช้วิธีเศษเหลือสูงสุด (Largest Remainder Method / Hamilton Method) เพื่อปรับจุดทศนิยมให้รวมกันได้ครบ 100% พอดี
              final List<int> roundedVals = List.filled(5, 0);
              if (sumRaw > 0) {
                final List<int> floors = pctVals.map((v) => v.floor()).toList();
                final int floorSum = floors.reduce((a, b) => a + b);
                final int diff = 100 - floorSum;

                // จัดเก็บค่าดัชนีและเศษที่เหลือหลังปัดเศษลง
                final List<MapEntry<int, double>> remainders = List.generate(
                  5,
                  (i) => MapEntry(i, pctVals[i] - floors[i])
                );

                // เรียงลำดับจากค่าเศษเหลือมากไปหาน้อย
                remainders.sort((a, b) => b.value.compareTo(a.value));

                // กำหนดสัดส่วนพื้นฐาน (Floors)
                for (int i = 0; i < 5; i++) {
                  roundedVals[i] = floors[i];
                }

                // กระจายผลต่างเศษเหลือที่เหลืออยู่ให้แก่ย่านความถี่ที่มีเศษเหลือมากสุดตามลำดับ
                for (int i = 0; i < diff; i++) {
                  final idx = remainders[i].key;
                  roundedVals[idx]++;
                }
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: [
                  _buildCircularWaveIndicator(
                    'Delta',
                    hasData ? roundedVals[0].toDouble() : 0.0,
                    const Color(0xFF8B5CF6),
                    'หลับลึก',
                    1.0,
                    hasData,
                    width: cardWidth,
                  ),
                  _buildCircularWaveIndicator(
                    'Theta',
                    hasData ? roundedVals[1].toDouble() : 0.0,
                    const Color(0xFF10B981),
                    'ผ่อนคลาย',
                    2.5,
                    hasData,
                    width: cardWidth,
                  ),
                  _buildCircularWaveIndicator(
                    'Alpha',
                    hasData ? roundedVals[2].toDouble() : 0.0,
                    const Color(0xFF3B82F6),
                    'ตื่นตัว',
                    5.0,
                    hasData,
                    width: cardWidth,
                  ),
                  _buildCircularWaveIndicator(
                    'Beta',
                    hasData ? roundedVals[3].toDouble() : 0.0,
                    const Color(0xFFF59E0B),
                    'คิดวิเคราะห์',
                    9.0,
                    hasData,
                    width: cardWidth,
                  ),
                  _buildCircularWaveIndicator(
                    'Gamma',
                    hasData ? roundedVals[4].toDouble() : 0.0,
                    const Color(0xFFEF4444),
                    'สมาธิสูง',
                    15.0,
                    hasData,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          if (_museService.isConnected) ...[
            const SizedBox(height: 18),
            EegResearchWaveformCard(
              buffers: _oscilloscopeBuffers,
              isSimulating: _museService.isSimulating,
              expanded: _HomeScreenState._isResearchWavesExpanded,
              onToggle: _toggleResearchWaves,
            ),
            const SizedBox(height: 18),
            EegPipelineVisualizer(
              channels: _oscilloscopeBuffers,
              hasData: _oscilloscopeBuffers.values.any((b) => b.isNotEmpty),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularWaveIndicator(
    String name,
    double value,
    Color color,
    String desc,
    double frequency,
    bool isActive, {
    double? width,
  }) {
    final displayColor = isActive ? color : Colors.grey[400]!;
    return Container(
      width: width ?? 104,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: isActive ? 0.8 : 0.4,
        borderColor: displayColor.withValues(alpha: isActive ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.textDark : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value / 100),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return CircularProgressIndicator(
                      value: val,
                      strokeWidth: 6,
                      backgroundColor: displayColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Text(
                '${value.round()}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: displayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // กราฟเส้นคลื่นสมองเคลื่อนไหวแบบเรียลไทม์ (Dynamic animated microwave line chart)
          MicroWaveChart(
            color: displayColor,
            frequency: frequency,
            isActive: isActive,
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.textGray : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}
