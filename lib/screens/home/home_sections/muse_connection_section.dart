part of '../home_screen.dart';

/// 4. การเชื่อมต่ออุปกรณ์ Muse: การ์ดสถานะ, หน้าต่างเลือกอุปกรณ์ และการ์ดรอรับข้อมูล
extension _MuseConnectionSection on _HomeScreenState {
  Widget _buildMuseConnectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        color: Colors.white,
        opacity: 0.75,
        borderColor: (_museService.isConnected ? AppColors.primaryGreen : AppColors.primaryBlue).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_museService.isConnected ? AppColors.primaryGreen : AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _museService.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                  color: _museService.isConnected ? AppColors.primaryGreen : AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'อุปกรณ์ตรวจจับ Muse S',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _museService.isConnected
                                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _museService.isConnected ? 'เชื่อมต่อแล้ว' : 'ปิดการเชื่อมต่อ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _museService.isConnected ? AppColors.primaryGreen : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _museService.status,
                      style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_museService.deviceName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.developer_board, size: 14, color: AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    'ฮาร์ดแวร์: ${_museService.deviceName}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElectrodePlacementMap(isConnected: _museService.isConnected),

          // ตารางข้อมูลโทรมาตรการเชื่อมต่อ (Connection Telemetry Grid - แสดงเมื่อเชื่อมต่อสำเร็จ)
          if (_museService.isConnected) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final double screenWidth = ResponsiveHelper.screenWidth(context);
                final int connectionCrossAxisCount = screenWidth < 450 ? 1 : 2;
                final double connectionChildAspectRatio = screenWidth < 450 ? 4.2 : 1.9;

                return GridView.count(
                  crossAxisCount: connectionCrossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: connectionChildAspectRatio,
                  children: [
                    _buildConnectionMetricItem(
                      label: 'ความแรงสัญญาณ BT',
                      value: _museService.isSimulating ? 'ดีเยี่ยม (จำลอง)' : 'เสถียร (RSSI)',
                      icon: Icons.signal_cellular_alt_rounded,
                      color: Colors.blue,
                    ),
                    _buildConnectionMetricItem(
                      label: 'อัตราข้อมูลวิเคราะห์',
                      value: '256 Samples/s',
                      icon: Icons.speed_rounded,
                      color: Colors.cyan,
                    ),
                    _buildConnectionMetricItem(
                      label: 'ความหน่วงการรับส่ง',
                      value: '< 250 ms',
                      icon: Icons.hourglass_bottom_rounded,
                      color: Colors.amber,
                    ),
                    _buildConnectionMetricItem(
                      label: 'ความน่าเชื่อถือช่องสัญญาณ',
                      value: '99.8% Calibrated',
                      icon: Icons.verified_user_rounded,
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _museService.isConnecting
                      ? null
                      : (_museService.isConnected ? _disconnectMuse : _scanAndConnect),
                  icon: _isLoading || _museService.isConnecting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _museService.isConnected ? Colors.white : AppColors.primaryBlue,
                          ),
                        )
                      : Icon(
                          _museService.isConnected ? Icons.bluetooth_disabled_rounded : Icons.bluetooth_searching_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    _museService.isConnecting
                        ? 'กำลังเชื่อมต่อ...'
                        : (_museService.isConnected ? 'ยกเลิกเชื่อมต่ออุปกรณ์' : 'ค้นหาและเชื่อมต่อ Muse'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _museService.isConnected ? AppColors.error : AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 8, color: AppColors.textGray, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForDataCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _museService.isWaitingForFFT
                          ? 'กำลังวิเคราะห์คลื่นสมอง...'
                          : 'กำลังสะสมข้อมูล EEG...',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _museService.isWaitingForFFT
                          ? 'รอ FFT คำนวณ (~1 วินาที)'
                          : '${_museService.bufferFillLevel}/${_museService.minBufferRequired} samples',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_museService.packetCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Packet #${_museService.packetCount}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF667eea), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _museService.isWaitingForFFT
                  ? null
                  : _museService.bufferProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE8F0FE),
              valueColor: AlwaysStoppedAnimation<Color>(
                _museService.isWaitingForFFT
                    ? const Color(0xFF764ba2)
                    : const Color(0xFF667eea),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_museService.packetCount == 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecoration(
                color: AppColors.warning,
                opacity: 0.12,
                borderColor: AppColors.warning.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'รอสัญญาณจริง... ตรวจสอบการสวมใส่หน้ากากวัดคลื่นสมองให้กระชับหน้าผาก',
                      style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecoration(
                color: AppColors.primaryBlue,
                opacity: 0.1,
                borderColor: AppColors.primaryBlue.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _museService.isWaitingForFFT
                          ? 'Buffer พร้อมแล้ว กำลังแปลง Fast Fourier Transform (FFT)...'
                          : 'ต้องการสะสม 256 samples เพื่อแปลงสัญญาณความถึ่สมองได้อย่างแม่นยำ',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNoBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bluetooth ไม่พร้อมใช้งาน'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ไม่สามารถใช้ Bluetooth บนแพลตฟอร์มนี้ได้'),
            SizedBox(height: 8),
            Text('คุณสามารถ:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• ใช้โหมดจำลองเพื่อทดสอบ'),
            Text('• รันแอปบน iOS/Android เพื่อเชื่อมต่อจริง'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _museService.startSimulation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('ใช้โหมดจำลอง', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeviceSelectionDialog() {
    VoidCallback? modalListener;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {

          modalListener ??= () {
            if (modalContext.mounted) setModalState(() {});
          };
          _museService.addListener(modalListener!);

          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(modalContext).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bluetooth_searching, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'เลือกอุปกรณ์ Muse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const Spacer(),
                    if (_museService.isScanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _museService.status,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: _museService.scanResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _museService.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _museService.isScanning
                                    ? 'กำลังค้นหาอุปกรณ์...'
                                    : 'ไม่พบอุปกรณ์ Muse',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (!_museService.isScanning) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'ตรวจสอบว่า Muse S เปิดอยู่และอยู่ใกล้ๆ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _museService.scanResults.length,
                          itemBuilder: (modalContext, index) {
                            final result = _museService.scanResults[index];
                            final device = result.device;
                            final rssi = result.rssi;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  child: Icon(Icons.bluetooth, color: AppColors.primaryBlue),
                                ),
                                title: Text(
                                  device.platformName.isNotEmpty
                                      ? device.platformName
                                      : 'Unknown Device',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'สัญญาณ: $rssi dBm',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _museService.isConnecting
                                      ? null
                                      : () async {
                                          Navigator.pop(modalContext);
                                          await _museService.connectToDevice(device);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text(
                                    _museService.isConnecting ? 'กำลังเชื่อมต่อ...' : 'เชื่อมต่อ',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _museService.isScanning
                            ? () => _museService.stopScan()
                            : () => _museService.startScan(),
                        icon: Icon(
                          _museService.isScanning ? Icons.stop : Icons.refresh,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          _museService.isScanning ? 'หยุดค้นหา' : 'ค้นหาใหม่',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _museService.startSimulation();
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.orange),
                        label: const Text('โหมดจำลอง', style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {

      if (modalListener != null) {
        _museService.removeListener(modalListener!);
      }
    });
  }
}
