part of '../home_screen.dart';

/// 2. วิดีโอสมองพร้อมหน้าจอ HUD (สถานะการบันทึก ช่องสัญญาณ และปุ่มควบคุมวิดีโอ)
extension _BrainVideoSection on _HomeScreenState {
  Widget _buildBrainVideoHud() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ตัวเล่นวิดีโอ (Video Player) — แสดงผลเต็มพื้นที่ในกรอบ Stack
            Positioned.fill(
              child: _isVideoLoaded
                  ? FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0F1424),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_outlined,
                          color: Colors.cyan,
                          size: 40,
                        ),
                      ),
                    ),
            ),

            // กรอบมุมสไตล์ไฮเทค (High-Tech Cyber Corner Frame Paint)
            Positioned.fill(
              child: CustomPaint(
                painter: CyberFramePainter(
                  color: Colors.cyan.withValues(alpha: 0.6),
                  isConnected: _museService.isConnected,
                ),
              ),
            ),

            // แถบเส้นเลเซอร์สแกนแบบล้ำสมัย (Pulse-scanning laser line overlay)
            if (_isVideoLoaded && _isVideoPlaying)
              const Positioned.fill(
                child: SciFiScannerOverlay(
                  color: Colors.cyan,
                ),
              ),

            // แผ่นฟิล์มไล่ระดับเฉดสีเพื่อเพิ่มการอ่านค่า (Subtle gradient overlay at bottom and top for readability)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // หน้าจอ HUD มุมบนซ้าย: แสดงสถานะการบันทึกภาพพร้อมจุดสีแดงกะพริบ (HUD Overlay: Top-Left)
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(color: Colors.red, size: 8),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NEURAL IMAGING CAPTURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.cyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _museService.isConnected
                            ? 'จับสัญญาณคลื่นสมองจริง: ACTIVE FEED'
                            : 'จำลองสแกนเนอร์: CALIBRATING',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // หน้าจอ HUD มุมบนขวา: แสดงข้อมูลรายละเอียดการเชื่อมต่อเครื่องส่ง (HUD Overlay: Top-Right)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DEVICE: ${_museService.deviceName ?? (widget.user.username.length > 8 ? widget.user.username.substring(0, 8) : widget.user.username).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _museService.isConnected ? 'RATE: 256Hz (LIVE)' : 'RATE: 256Hz (STANDBY)',
                      style: const TextStyle(
                        fontSize: 7,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // หน้าจอ HUD มุมล่างซ้าย: แสดงสถานะช่องวัดสัญญาณสมองแบบสด (HUD Overlay: Bottom-Left)
            Positioned(
              bottom: 14,
              left: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildChannelStatusBadge('TP9', _museService.isConnected),
                      const SizedBox(width: 4),
                      _buildChannelStatusBadge('AF7', _museService.isConnected),
                      const SizedBox(width: 4),
                      _buildChannelStatusBadge('AF8', _museService.isConnected),
                      const SizedBox(width: 4),
                      _buildChannelStatusBadge('TP10', _museService.isConnected),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SIGNAL SYNC SPEED: 250ms',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // หน้าจอ HUD มุมล่างขวา: แถบควบคุมวิดีโอแบบกระจกฝ้าลอยตัว (HUD Overlay: Bottom-Right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ปุ่มกด เล่น / หยุดเล่นวิดีโอ (Play / Pause Button)
                    GestureDetector(
                      onTap: () {
                        _refresh(() {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                            _isVideoPlaying = false;
                          } else {
                            _videoController.play();
                            _isVideoPlaying = true;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ปุ่มเปิด / ปิดเสียงวิดีโอ (Mute Button)
                    GestureDetector(
                      onTap: () {
                        _refresh(() {
                          if (_videoController.value.volume > 0) {
                            _videoController.setVolume(0);
                            _isVideoMuted = true;
                          } else {
                            _videoController.setVolume(0.5);
                            _isVideoMuted = false;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVideoMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // จุดไฟกระพริบแสดงสัญญาณสดแบบเรียลไทม์ (Live Indicator Dot)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _museService.isConnected ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _museService.isConnected ? 'LIVE' : 'SIMULATE',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // หน้าต่างซ้อนทับขณะกำลังโหลด (Loading overlay)
            if (!_isVideoLoaded)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0F1424),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ระบบบันทึกความถึ่สมองกำลังเตรียมการ...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelStatusBadge(String name, bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isConnected ? Colors.green.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            name,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
