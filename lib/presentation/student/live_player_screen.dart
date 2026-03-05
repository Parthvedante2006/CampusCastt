import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campuscast/data/api/broadcast_api.dart';
import 'package:campuscast/data/firebase/firestore/channel_firestore.dart';
import 'package:campuscast/domain/providers/player_provider.dart';
import 'package:campuscast/domain/providers/channel_provider.dart';
import 'package:campuscast/presentation/common/widgets/live_badge.dart';
import 'package:campuscast/presentation/common/widgets/listener_counter.dart';

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

class _LivePlayerScreenState extends ConsumerState<LivePlayerScreen> {
  final _api       = BroadcastApi();
  final _firestore = ChannelFirestore();

  // ──────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────

  @override
  void dispose() {
    // Stop player and decrement listeners when screen closes
    ref.read(playerProvider.notifier).stop();
    _firestore.decrementListeners(widget.broadcastId);
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Play
  // ──────────────────────────────────────────────

  Future<void> _play() async {
    try {
      final url = await _api.getStreamUrl(widget.broadcastId);
      await ref.read(playerProvider.notifier).play(url);
      await _firestore.incrementListeners(widget.broadcastId);
    } catch (e) {
      _showSnack('Could not load stream: $e');
    }
  }

  Future<void> _stop() async {
    await ref.read(playerProvider.notifier).stop();
    await _firestore.decrementListeners(widget.broadcastId);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final playerState   = ref.watch(playerProvider);
    final isPlaying     = playerState.state == PlayerState.playing;
    final isBuffering   = playerState.state == PlayerState.buffering;

    final listenerCount =
        ref.watch(listenerCountProvider(widget.broadcastId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation:        0,
        title: Text(
          widget.channelName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── LIVE badge ──────────────────────────
              const LiveBadge(blink: false),
              const SizedBox(height: 32),

              // ── Channel avatar placeholder ───────────
              Container(
                width:  120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.radio, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // ── Channel name ─────────────────────────
              Text(
                widget.channelName,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ── Listener count ───────────────────────
              listenerCount.when(
                data:    (count) => ListenerCounter(count: count),
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 48),

              // ── Play / Pause button ───────────────────
              GestureDetector(
                onTap: isBuffering ? null : (isPlaying ? _stop : _play),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width:  90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isPlaying
                          ? [Colors.grey.shade700, Colors.grey.shade900]
                          : [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: isBuffering
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Icon(
                          isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size:  44,
                        ),
                ),
              ),

              // ── Error message ─────────────────────────
              if (playerState.error != null) ...[
                const SizedBox(height: 24),
                Text(
                  playerState.error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
