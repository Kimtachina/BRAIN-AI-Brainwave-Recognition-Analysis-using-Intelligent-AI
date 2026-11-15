part of '../eeg_session_screen.dart';

/// หน้าจอระหว่างเก็บข้อมูล: เวลาที่เหลือ คลื่นสด และแถบพลังคลื่นแต่ละย่าน
extension _RunningSession on _EegSessionScreenState {
  Widget _buildRunningSession() {
    final session = _sessions[_currentSessionIndex];
    final duration = session['duration'] as int;
    final progress = _elapsedSeconds / duration;
    final remaining = duration - _elapsedSeconds;
    final colors = session['gradient'] as List<Color>;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter(context, maxWidth: AppLayout.readingWidth, min: 24), vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        boxShadow: [
                          BoxShadow(
                            color: (session['color'] as Color).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(session['icon'], color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                session['name'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: session['color']),
              ),
              const SizedBox(height: 8),
              Text(
                session['instruction'],
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(session['color']),
                  minHeight: 10,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(Icons.timeline, '$_samplesCollected samples'),
                  _buildStatChip(Icons.timer, '$_elapsedSeconds s'),
                  _buildStatChip(Icons.label, session['emotion']),
                ],
              ),

              if (widget.museService.latestData != null) ...[
                const SizedBox(height: 24),
                _buildLiveWaveCard(),
                EegResearchWaveformCard(
                  buffers: _oscilloscopeBuffers,
                  isSimulating: widget.museService.isSimulating,
                  expanded: _EegSessionScreenState._isResearchWavesExpanded,
                  onToggle: _toggleResearchWaves,
                  traceHeight: 220,
                  margin: const EdgeInsets.only(top: 16),
                ),
                const SizedBox(height: 16),
                EegPipelineVisualizer(
                  channels: _oscilloscopeBuffers,
                  hasData: _oscilloscopeBuffers.values.any((b) => b.isNotEmpty),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _stopSession,
                  icon: const Icon(Icons.stop_rounded, color: Colors.white),
                  label: const Text('หยุด Session', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLiveWaveCard() {
    final d = widget.museService.latestData!;
    final rawVals = [d.delta, d.theta, d.alpha, d.beta, d.gamma];
    final double sumRaw = rawVals.reduce((a, b) => a + b);
    final List<double> pctVals = sumRaw > 0
        ? rawVals.map((v) => (v / sumRaw) * 100.0).toList()
        : [0.0, 0.0, 0.0, 0.0, 0.0];

    // Apply Largest Remainder Method to get rounded integers that sum to exactly 100
    final List<int> roundedVals = List.filled(5, 0);
    if (sumRaw > 0) {
      final List<int> floors = pctVals.map((v) => v.floor()).toList();
      final int floorSum = floors.reduce((a, b) => a + b);
      final int diff = 100 - floorSum;

      final List<MapEntry<int, double>> remainders = List.generate(
        5,
        (i) => MapEntry(i, pctVals[i] - floors[i])
      );
      remainders.sort((a, b) => b.value.compareTo(a.value));

      for (int i = 0; i < 5; i++) {
        roundedVals[i] = floors[i];
      }
      for (int i = 0; i < diff; i++) {
        final idx = remainders[i].key;
        roundedVals[idx]++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildMiniBar('Delta', roundedVals[0].toDouble(), Colors.purple),
          _buildMiniBar('Theta', roundedVals[1].toDouble(), Colors.green),
          _buildMiniBar('Alpha', roundedVals[2].toDouble(), Colors.blue),
          _buildMiniBar('Beta', roundedVals[3].toDouble(), Colors.orange),
          _buildMiniBar('Gamma', roundedVals[4].toDouble(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text('${value.round()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
