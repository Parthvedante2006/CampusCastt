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
    extends ConsumerState<AnnouncementReplayPlayerScreen> {
  @override
  void dispose() {
    ref.read(playerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _play() async {
    await ref.read(playerProvider.notifier).play(widget.audioUrl);
  }

  Future<void> _pause() async {
    await ref.read(playerProvider.notifier).pause();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.state == PlayerState.playing;
    final isBuffering = playerState.state == PlayerState.buffering;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        title: Text(
          widget.channelName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, color: Colors.white, size: 56),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Recorded Announcement',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: isBuffering ? null : (isPlaying ? _pause : _play),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1D3C78),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D3C78).withOpacity(0.5),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: isBuffering
                    ? const Padding(
                        padding: EdgeInsets.all(28.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
              ),
            ),
            if (playerState.error != null) ...[
              const SizedBox(height: 20),
              Text(
                playerState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
