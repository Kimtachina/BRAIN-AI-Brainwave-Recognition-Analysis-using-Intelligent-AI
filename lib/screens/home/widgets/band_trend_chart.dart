import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../services/muse/muse_service.dart';
import '../../../theme/app_theme.dart';

/// กราฟเส้นสัดส่วนคลื่นสมอง 5 ย่าน (%) ย้อนหลัง [window] วินาที
/// แกน X เป็นวินาทีนับจากตอนนี้ (ติดลบ = ในอดีต) แกน Y เป็นเปอร์เซ็นต์ของพลังรวม
class BandTrendChart extends StatelessWidget {
  final List<BrainwaveData> history;
  final int window;

  const BandTrendChart({super.key, required this.history, this.window = 60});

  /// ชื่อและสีของแต่ละย่าน เรียงเหมือนการ์ดวงกลมด้านล่าง
  static const bands = [
    ('Delta', Color(0xFF8B5CF6)),
    ('Theta', Color(0xFF10B981)),
    ('Alpha', Color(0xFF3B82F6)),
    ('Beta', Color(0xFFF59E0B)),
    ('Gamma', Color(0xFFEF4444)),
  ];

  static List<double> _percentages(BrainwaveData d) {
    final raw = [d.delta, d.theta, d.alpha, d.beta, d.gamma];
    final sum = raw.fold<double>(0, (a, b) => a + b);
    return sum > 0 ? raw.map((v) => v / sum * 100).toList() : List.filled(5, 0);
  }

  @override
  Widget build(BuildContext context) {
    final now = history.isEmpty ? DateTime.now() : history.last.timestamp;
    final points = [
      for (final d in history)
        if (now.difference(d.timestamp).inMilliseconds <= window * 1000)
          (x: -now.difference(d.timestamp).inMilliseconds / 1000, pct: _percentages(d)),
    ];
    final hasData = points.length >= 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('สัดส่วนคลื่นสมอง $window วินาทีล่าสุด',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                for (final (name, color) in bands) _LegendItem(name: name, color: hasData ? color : AppColors.inkFaint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                LineChart(
                  duration: Duration.zero,
                  LineChartData(
                    minX: -window.toDouble(),
                    maxX: 0,
                    minY: 0,
                    maxY: 100,
                    clipData: const FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.line, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 40,
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.inkFaint)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: window / 4,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              v == 0 ? 'ตอนนี้' : '${v.abs().toInt()} วิ',
                              style: const TextStyle(fontSize: 10, color: AppColors.inkFaint),
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: hasData,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surface,
                        tooltipBorder: const BorderSide(color: AppColors.line),
                        getTooltipItems: (spots) => [
                          for (final s in spots)
                            LineTooltipItem(
                              '${bands[s.barIndex].$1} ${s.y.round()}%',
                              TextStyle(color: bands[s.barIndex].$2, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: [
                      for (var i = 0; i < bands.length; i++)
                        LineChartBarData(
                          spots: hasData ? [for (final p in points) FlSpot(p.x, p.pct[i])] : const [],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: bands[i].$2,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                    ],
                  ),
                ),
                if (!hasData)
                  const Center(
                    child: Text('กราฟจะแสดงเมื่อเริ่มรับสัญญาณจาก Muse',
                        style: TextStyle(fontSize: 12, color: AppColors.inkFaint)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String name;
  final Color color;

  const _LegendItem({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(name, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ],
    );
  }
}
