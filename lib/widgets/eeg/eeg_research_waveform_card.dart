import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import 'eeg_research_trace.dart';

/// การ์ดแสดงคลื่นสมองดิบ 4 ช่องสัญญาณ (TP9, AF7, AF8, TP10) แบบงานวิจัย
/// พร้อมตารางสถิติ (mean, std, min, max)
///
/// ใช้ทั้งในหน้าหลัก (HomeScreen) และหน้าเก็บข้อมูล EEG (EegSessionScreen)
class EegResearchWaveformCard extends StatelessWidget {
  /// ค่าสัญญาณล่าสุดของแต่ละช่อง (key = ชื่อช่องสัญญาณ)
  final Map<String, List<double>> buffers;

  /// true = ข้อมูลจำลอง, false = ข้อมูลจริงจาก Muse
  final bool isSimulating;

  /// ความสูงของพื้นที่กราฟคลื่น
  final double traceHeight;

  final EdgeInsetsGeometry? margin;

  const EegResearchWaveformCard({
    super.key,
    required this.buffers,
    required this.isSimulating,
    this.traceHeight = 180,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณค่าสถิติแบบเรียลไทม์สำหรับแต่ละช่องสัญญาณประสาท (คำนวณจากค่าดิบ Raw values)
    final Map<String, Map<String, double>> channelStats = {};
    for (final entry in buffers.entries) {
      final data = entry.value;
      if (data.isNotEmpty) {
        double sum = 0, sqSum = 0;
        double minVal = data.first, maxVal = data.first;
        for (final v in data) {
          sum += v;
          sqSum += v * v;
          if (v < minVal) minVal = v;
          if (v > maxVal) maxVal = v;
        }
        final mean = sum / data.length;
        final variance = (sqSum / data.length) - mean * mean;
        final std = math.sqrt(variance.abs());
        channelStats[entry.key] = {
          'mean': mean,
          'std': std,
          'min': minVal,
          'max': maxVal,
          'pp': maxVal - minVal,
        };
      }
    }

    final bool hasData = buffers.values.any((b) => b.isNotEmpty);
    final int totalSamples = buffers['TP9']?.length ?? 0;
    final String sourceLabel = isSimulating
        ? 'Simulation Mode'
        : 'Muse 2 (Live)';
    final now = DateTime.now();
    final String timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    const channelColors = {
      'TP9': AppColors.primaryDeep,
      'AF7': Color(0xFF2E7D32),
      'AF8': Color(0xFFE65100),
      'TP10': Color(0xFF6A1B9A),
    };

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Banner ──
          Container(
            // แถบหัวสีม่วงเข้ม ตัวอักษรขาวจึงอ่านชัดบนธีมกลางคืน
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Raw EEG Multi-Channel Traces',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasData
                                ? const Color(0xFF4CAF50)
                                : AppColors.inkFaint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasData ? 'LIVE' : 'IDLE',
                          style: TextStyle(
                            color: hasData
                                ? const Color(0xFF81C784)
                                : Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Device Metadata Row ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _metaChip('Source', sourceLabel),
                    const SizedBox(width: 12),
                    _metaChip('Fs', '256 Hz'),
                    const SizedBox(width: 12),
                    _metaChip('Ref', 'FPz (Forehead)'),
                    const Spacer(),
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: AppColors.inkFaint,
                        fontSize: 9,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Montage Info ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                color: AppColors.paper,
                child: Row(
                  children: [
                    Text(
                      'Montage: International 10-20 System  •  Channels: 4',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'N = $totalSamples pts',
                      style: TextStyle(
                        color: AppColors.inkFaint,
                        fontSize: 9,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),

              // ── Channel Color Legend ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Row(
                  children: channelColors.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 3,
                            decoration: BoxDecoration(
                              color: e.value,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            e.key,
                            style: TextStyle(
                              color: e.value,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Waveform Plot ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: AppColors.paper,
                    height: traceHeight,
                    child: CustomPaint(
                      painter: EegResearchTracePainter(
                        channels: buffers,
                        channelColors: channelColors,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),

              // ── Scale Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(width: 40, height: 2, color: AppColors.inkSoft),
                    const SizedBox(width: 4),
                    Text(
                      '~${(totalSamples / 33.3).toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.inkSoft,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 2, height: 12, color: AppColors.inkSoft),
                    const SizedBox(width: 4),
                    const Text(
                      'Auto µV',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.inkSoft,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Filter: 0.5 – 50 Hz  •  Notch: 50 Hz',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.inkFaint,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),

              // ── Per-Channel Statistics ──
              if (channelStats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Channel Statistics — Raw (Real-time)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Table(
                        columnWidths: const {
                          0: FixedColumnWidth(50),
                          1: FlexColumnWidth(),
                          2: FlexColumnWidth(),
                          3: FlexColumnWidth(),
                          4: FlexColumnWidth(),
                        },
                        border: TableBorder.all(
                          color: AppColors.line,
                          width: 0.5,
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppColors.line),
                            children: const [
                              EegStatHeader('Ch'),
                              EegStatHeader('Mean'),
                              EegStatHeader('Std'),
                              EegStatHeader('Min'),
                              EegStatHeader('Max'),
                            ],
                          ),
                          ...['TP9', 'AF7', 'AF8', 'TP10'].map((ch) {
                            final s = channelStats[ch];
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    ch,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: channelColors[ch],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                EegStatCell(s?['mean']),
                                EegStatCell(s?['std']),
                                EegStatCell(s?['min']),
                                EegStatCell(s?['max']),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.inkFaint,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
