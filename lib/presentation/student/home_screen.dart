import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campuscast/core/routes/app_router.dart';
import 'package:campuscast/domain/providers/channel_provider.dart';
import 'package:campuscast/data/models/channel_model.dart';
import 'package:campuscast/presentation/common/widgets/live_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(allChannelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation:        0,
        title: const Text(
          'CampusCastt 🎙️',
          style: TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.bold,
            fontSize:   20,
          ),
        ),
        centerTitle: true,
      ),

      // ── FAB: Quick test button — navigate to GoLiveScreen ────
      // In production this would be role-gated (channel owners only)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(
          AppRoutes.goLive,
          extra: {
            'channelId':   'test_channel_001',
            'channelName': 'CampusCastt Live',
          },
        ),
        backgroundColor: Colors.deepPurple,
        icon:  const Icon(Icons.mic, color: Colors.white),
        label: const Text('Go Live', style: TextStyle(color: Colors.white)),
      ),

      body: channelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(
                'Could not load channels.\n$err',
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.radio, color: Colors.white24, size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'No channels yet.',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap  Go Live  to start broadcasting.',
                    style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding:          const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount:        channels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder:      (ctx, i) => _ChannelCard(channel: channels[i]),
          );
        },
      ),
    );
  }
}

// ── Channel Card ─────────────────────────────────────────────────
class _ChannelCard extends StatelessWidget {
  final ChannelModel channel;
  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: channel.isLive && channel.activeBroadcastId != null
          ? () => context.go(
                AppRoutes.livePlayer,
                extra: {
                  'broadcastId':  channel.activeBroadcastId!,
                  'channelName':  channel.name,
                },
              )
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity:  channel.isLive ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: channel.isLive
                ? Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width:  52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: channel.isLive
                        ? [Colors.red.shade700, Colors.deepPurple.shade700]
                        : [Colors.grey.shade700, Colors.grey.shade900],
                  ),
                ),
                child: const Icon(Icons.radio, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      channel.isLive ? 'Tap to listen' : 'Offline',
                      style: TextStyle(
                        color:    channel.isLive
                            ? Colors.greenAccent.shade400
                            : Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // LIVE badge
              if (channel.isLive) const LiveBadge(),
            ],
          ),
        ),
      ),
    );
  }
}
