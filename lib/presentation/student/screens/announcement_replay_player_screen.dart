import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/domain/providers/player_provider.dart';

class AnnouncementReplayPlayerScreen extends ConsumerStatefulWidget {
  final String audioUrl;
  final String title;
  final String channelName;

  const AnnouncementReplayPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.channelName,
  });

  @override
  ConsumerState<AnnouncementReplayPlayerScreen> createState() =>
      _AnnouncementReplayPlayerScreenState();
}

class _AnnouncementReplayPlayerScreenState
    extends ConsumerState<AnnouncementReplayPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  bool _transcriptExpanded = false;
  double _playbackSpeed = 1.0;
  final List<double> _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    ref.read(playerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _play() async =>
      ref.read(playerProvider.notifier).play(widget.audioUrl);

  Future<void> _pause() async =>
      ref.read(playerProvider.notifier).pause();

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_playbackSpeed);
    setState(() {
      _playbackSpeed = _speeds[(idx + 1) % _speeds.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.state == PlayerState.playing;
    final isBuffering = playerState.state == PlayerState.buffering;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Replay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Channel Info Row ──────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1E3A5F),
                          child: const Icon(Icons.radio,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.channelName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(
                                'March 2, 2026',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF112240),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('12:34',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── AI Summary Card ───────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112240),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome,
                                  color: Color(0xFF2563EB), size: 16),
                              SizedBox(width: 6),
                              Text('AI Summary',
                                  style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This announcement covers key updates about the upcoming semester schedule, exam timetable changes, and important submission deadlines for all departments.',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Audio Player Card ─────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112240),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Title
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 20),

                          // Progress bar
                          Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 12),
                                  activeTrackColor:
                                      const Color(0xFF2563EB),
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      Colors.white.withOpacity(0.1),
                                ),
                                child: Slider(
                                  value: 0.35,
                                  onChanged: (_) {},
                                ),
                              ),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('4:20',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                    Text('12:34',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Controls row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              // Speed
                              GestureDetector(
                                onTap: _cycleSpeed,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A3A6B),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_playbackSpeed}x',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                              ),

                              // Rewind
                              IconButton(
                                icon: const Icon(Icons.replay_10,
                                    color: Colors.white70, size: 28),
                                onPressed: () {},
                              ),

                              // Play/Pause
                              GestureDetector(
                                onTap: isBuffering
                                    ? null
                                    : (isPlaying ? _pause : _play),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isBuffering
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 32),
                                ),
                              ),

                              // Forward
                              IconButton(
                                icon: const Icon(Icons.forward_10,
                                    color: Colors.white70, size: 28),
                                onPressed: () {},
                              ),

                              // Volume
                              IconButton(
                                icon: const Icon(Icons.volume_up_outlined,
                                    color: Colors.white70, size: 24),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Transcript Section ────────────────
                    GestureDetector(
                      onTap: () => setState(
                          () => _transcriptExpanded = !_transcriptExpanded),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF112240),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Full Transcript',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Icon(
                                  _transcriptExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                            if (_transcriptExpanded) ...[
                              const SizedBox(height: 14),
                              ..._transcriptLines.map(
                                (t) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(t['time']!,
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(t['text']!,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontSize: 13,
                                                height: 1.4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (playerState.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(playerState.error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _transcriptLines = [
    {'time': '0:00', 'text': 'Good afternoon everyone, this is an important announcement from the administration office.'},
    {'time': '0:18', 'text': 'The upcoming semester exam timetable has been updated. Please check the official portal.'},
    {'time': '0:42', 'text': 'All project submissions are due by March 15th. Late submissions will not be accepted.'},
    {'time': '1:05', 'text': 'The library will remain open on weekends from 8 AM to 6 PM during exam season.'},
  ];
}

