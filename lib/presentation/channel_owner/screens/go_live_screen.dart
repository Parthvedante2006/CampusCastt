import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:campuscast/domain/providers/broadcast_provider.dart';
import 'package:campuscast/domain/providers/channel_provider.dart';
import 'package:campuscast/presentation/common/widgets/live_badge.dart';
import 'package:campuscast/presentation/common/widgets/listener_counter.dart';
import 'package:campuscast/presentation/common/widgets/broadcast_timer.dart';
import 'package:campuscast/presentation/common/widgets/audio_waveform.dart';

class GoLiveScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const GoLiveScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  StreamSubscription<Uint8List>? _micSub;

  // ──────────────────────────────────────────────
  // GO LIVE
  // ──────────────────────────────────────────────

  Future<void> _goLive() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      _showSnack('Please enter announcement title.');
      return;
    }

    // 1. Request mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack('Microphone permission denied.');
      return;
    }

    // 2. Start broadcast on server (Socket.IO + Firestore)
    await ref.read(broadcastProvider.notifier).goLive(
      widget.channelId,
      title: title,
      description: description,
    );

    final broadcastId =
        ref.read(broadcastProvider).broadcastId;
    if (broadcastId == null) return;

    // 3. Start mic recording stream (raw PCM s16le, 44100 Hz, mono)
    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder:     AudioEncoder.pcm16bits,
        sampleRate:  44100,
        numChannels: 1,
      ),
    );

    // 4. Pipe each chunk from mic → Socket.IO → FFmpeg
    await _micSub?.cancel();
    _micSub = micStream.listen((chunk) {
      ref.read(broadcastProvider.notifier).sendAudioChunk(chunk);
    });
  }

  // ──────────────────────────────────────────────
  // STOP
  // ──────────────────────────────────────────────

  Future<void> _stopLive() async {
    await _recorder.stop();
    await _micSub?.cancel();
    _micSub = null;
    await ref.read(broadcastProvider.notifier).stopLive(widget.channelId);
    _showSnack('Broadcast ended.');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _micSub?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final broadcastState = ref.watch(broadcastProvider);
    final isLive         = broadcastState.state == BroadcastState.live;
    final isLoading      = broadcastState.state == BroadcastState.starting ||
                           broadcastState.state == BroadcastState.stopping;

    final listenerCount = broadcastState.broadcastId != null
        ? ref.watch(listenerCountProvider(broadcastState.broadcastId!))
        : null;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isLive) ...[
                  const Text(
                    'Announcement Title',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Ex: Daily Coding Session',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF151515),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    enabled: !isLoading,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'What will you announce on this live broadcast?',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF151515),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                ],

                // ── Live badge ──────────────────────────
                if (isLive) ...[
                  const LiveBadge(),
                  const SizedBox(height: 24),
                ],

                // ── Waveform ────────────────────────────
                AnimatedOpacity(
                  opacity:  isLive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: const AudioWaveform(barCount: 7, maxHeight: 60),
                ),
                const SizedBox(height: 32),

                // ── Timer ───────────────────────────────
                if (isLive) const BroadcastTimer(),
                const SizedBox(height: 12),

                // ── Listener count ──────────────────────
                if (isLive && listenerCount != null)
                  listenerCount.when(
                    data:    (count) => ListenerCounter(count: count),
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                  ),
                const SizedBox(height: 34),

                // ── GO LIVE / STOP button ───────────────
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : (isLive ? _stopLive : _goLive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width:  isLive ? 120 : 140,
                    height: isLive ? 120 : 140,
                    margin: const EdgeInsets.symmetric(horizontal: 70),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isLive
                            ? [Colors.red.shade700, Colors.red.shade900]
                            : [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:      (isLive ? Colors.red : Colors.deepPurple)
                              .withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white))
                        : Center(
                            child: Text(
                              isLive ? 'STOP' : 'GO\nLIVE',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   20,
                                fontWeight: FontWeight.bold,
                                height:     1.2,
                              ),
                            ),
                          ),
                  ),
                ),

                if (!isLive) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Title and description will be visible in student broadcasts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],

                // ── Error message ───────────────────────
                if (broadcastState.error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    broadcastState.error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
