import 'package:flutter/material.dart';

import '../../services/muse/eeg_live_signal.dart';
import '../../services/muse/muse_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/eeg/eeg_pipeline_visualizer.dart';

/// หน้าเบื้องหลัง: ดูขั้นตอนเตรียมสัญญาณ EEG (กรองความถี่ ตัดสัญญาณรบกวน แยกย่านคลื่น) แบบสด
class BehindScreen extends StatefulWidget {
  /// อัปเดตกราฟเฉพาะตอนแท็บนี้เปิดอยู่ ไม่ให้วาดซ้ำทุก 30 มิลลิวินาทีตอนอยู่หน้าอื่น
  final bool active;

  /// ไปแท็บวันนี้เพื่อเชื่อมต่อ Muse
  final VoidCallback? onConnect;

  const BehindScreen({super.key, required this.active, this.onConnect});

  @override
  State<BehindScreen> createState() => _BehindScreenState();
}

class _BehindScreenState extends State<BehindScreen> {
  final _signal = EegLiveSignal.instance;
  final _muse = MuseService();

  @override
  void initState() {
    super.initState();
    if (widget.active) _listen(true);
  }

  @override
  void didUpdateWidget(covariant BehindScreen old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      _listen(widget.active);
      if (widget.active) setState(() {});
    }
  }

  @override
  void dispose() {
    _listen(false);
    super.dispose();
  }

  void _listen(bool on) {
    if (on) {
      _signal.addListener(_refresh);
      _muse.addListener(_refresh);
    } else {
      _signal.removeListener(_refresh);
      _muse.removeListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(context);
    final wide = AppLayout.isWide(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, wide ? 28 : 12, gutter, 40),
          children: [
            Text('เบื้องหลัง', style: AppTextStyles.title.copyWith(fontSize: wide ? 30 : 26)),
            const SizedBox(height: 4),
            Text(
              'ดูว่าแอปเตรียมสัญญาณจาก Muse อย่างไรก่อนนำไปคำนวณผล: กรองความถี่ ตัดสัญญาณรบกวน และแยกเป็นย่านคลื่นสมอง',
              style: AppTextStyles.small.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            if (!_muse.isConnected) ...[
              _NotConnected(onConnect: widget.onConnect),
              const SizedBox(height: 16),
            ],
            EegPipelineVisualizer(channels: _signal.buffers, hasData: _signal.hasData),
          ],
        ),
      ),
    );
  }
}

class _NotConnected extends StatelessWidget {
  final VoidCallback? onConnect;

  const _NotConnected({this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_off_rounded, color: AppColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ยังไม่ได้เชื่อมต่อ Muse กราฟจะเริ่มทำงานเมื่อเชื่อมต่ออุปกรณ์หรือเปิดโหมดจำลอง',
              style: AppTextStyles.small.copyWith(color: AppColors.inkSoft),
            ),
          ),
          if (onConnect != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onConnect, child: const Text('ไปเชื่อมต่อ')),
          ],
        ],
      ),
    );
  }
}
