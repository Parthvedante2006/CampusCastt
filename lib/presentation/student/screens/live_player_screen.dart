import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/providers/player_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../data/api/broadcast_api.dart';
import '../../common/widgets/live_badge.dart';
import '../../common/widgets/listener_counter.dart';

class LivePlayerScreen extends ConsumerStatefulWidget {
  final String broadcastId;
  final String channelName;

  const LivePlayerScreen({
    super.key,
    required this.broadcastId,
    required this.channelName,
  });

  @override
  ConsumerState<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends ConsumerState<LivePlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  String? _streamUrl;
  bool _isLoading = true;
  String? _error;
  String _title = '';
  String _description = '';
  int _listenerCount = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _loadBroadcastAndPlay();
    _listenToListenerCount();
  }

  @override
  void dispose() {
    _waveController.dispose();
    ref.read(playerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _loadBroadcastAndPlay() async {
    try {
      // 1. Fetch broadcast details from Firestore
      final broadcastDoc = await FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(widget.broadcastId)
          .get();

      if (!broadcastDoc.exists) {
        setState(() {
          _error = 'Broadcast not found';
          _isLoading = false;
        });
        return;
      }

      final data = broadcastDoc.data()!;
      setState(() {
        _title = data['title'] ?? 'Live Broadcast';
        _description = data['description'] ?? '';
      });

      // 2. Fetch the HLS stream URL from backend
      final api = BroadcastApi();
      final streamUrl = await api.getStreamUrl(widget.broadcastId);

      setState(() {
        _streamUrl = streamUrl;
        _isLoading = false;
      });

      // 3. Start playing the HLS stream
      await ref.read(playerProvider.notifier).play(streamUrl);
    } catch (e) {
      setState(() {
        _error = 'Failed to load broadcast: $e';
        _isLoading = false;
      });
    }
  }

  void _listenToListenerCount() {
    // Listen to real-time listener count updates
    final listenerStream = ref.read(listenerCountProvider(widget.broadcastId));
    listenerStream.whenData((count) {
      if (mounted) {
        setState(() {
          _listenerCount = count;
        });
      }
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
        child: _isLoading
            ? _buildLoadingView()
            : _error != null
                ? _buildErrorView()
                : _buildPlayerView(isPlaying, isBuffering),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2563EB)),
          SizedBox(height: 16),
          Text(
            'Connecting to live stream...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerView(bool isPlaying, bool isBuffering) {
    return Column(
      children: [
        // ── Top Bar ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Live Broadcast',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {
                  // TODO: Implement share functionality
                },
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
                // ── Channel Info ─────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1E3A5F),
                      child: const Icon(Icons.radio,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.channelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4B4D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFFFF4B4D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Listener count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112240),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _listenerCount.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Live Audio Player Card ──────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2C191D),
                        Color(0xFF1E3A5F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF4A252A),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Live waveform animation
                      if (isPlaying)
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                10,
                                (i) => Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: 4,
                                  height: 20 +
                                      (i % 3) * 15 * _waveController.value,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4B4D),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (isBuffering)
                        const Column(
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFFFF4B4D),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Buffering...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Play/Pause Button
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            ref.read(playerProvider.notifier).pause();
                          } else if (_streamUrl != null) {
                            ref.read(playerProvider.notifier).play(_streamUrl!);
                          }
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4B4D),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4B4D).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Description ──────────────────────────────
                if (_description.isNotEmpty) ...[
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
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'About',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Info Card ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF112240),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.headphones,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Live Audio Quality',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'This is a live broadcast. Audio is streamed in real-time at 128 kbps AAC quality.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
