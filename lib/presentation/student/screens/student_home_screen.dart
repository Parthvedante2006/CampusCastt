import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../core/routes/app_router.dart';
import '../widgets/student_bottom_nav_bar.dart';

// Tabs
import 'student_dashboard_tab.dart';
import 'channels_screen.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const StudentDashboardTab(),
          const StudentBroadcastsTab(), // Or Replay Screen / Live
          const ChannelsScreen(), // Let's call it Explore
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class StudentBroadcastsTab extends ConsumerWidget {
  const StudentBroadcastsTab({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (user) {
        if (user == null || user.joinedChannels.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A1628),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A1628),
              elevation: 0,
              title: const Text('Broadcasts', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broadcast_on_personal, color: Colors.white.withOpacity(0.3), size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No broadcasts yet',
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join channels to see their broadcasts',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1628),
            elevation: 0,
            title: const Text('Broadcasts', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Broadcasts
                _buildBroadcastsSection(
                  context,
                  ref,
                  user.joinedChannels,
                  filter: 'live',
                  title: 'LIVE NOW',
                ),
                const SizedBox(height: 32),

                // Past Broadcasts
                _buildBroadcastsSection(
                  context,
                  ref,
                  user.joinedChannels,
                  filter: 'past',
                  title: 'PAST BROADCASTS',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBroadcastsSection(
    BuildContext context,
    WidgetRef ref,
    List<String> joinedChannelIds,
    {required String filter, required String title}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: joinedChannelIds.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildBroadcasts(context, ref, joinedChannelIds[index], filter),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBroadcasts(BuildContext context, WidgetRef ref, String channelId, String filter) {
    final broadcastsAsync = ref.watch(channelBroadcastsProvider(channelId));
    final replaysAsync = ref.watch(channelAnnouncementReplaysProvider(channelId));
    final channelAsync = ref.watch(channelProvider(channelId));

    final channelName = channelAsync.maybeWhen(
      data: (channel) => channel.name,
      orElse: () => 'Channel',
    );

    if (filter == 'past') {
      return replaysAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (replays) {
          return broadcastsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (broadcasts) {
              final filteredBroadcasts = broadcasts.where((b) {
                final status = (b['status'] ?? 'ended') as String;
                return status != 'live';
              }).toList();

              final cards = <Widget>[];

              for (final replay in replays) {
                cards.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildAnnouncementReplayCard(context, replay, channelName),
                  ),
                );
              }

              for (final broadcast in filteredBroadcasts) {
                cards.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildBroadcastCard(context, broadcast, channelAsync, channelName),
                  ),
                );
              }

              if (cards.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards,
              );
            },
          );
        },
      );
    }

    return broadcastsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      error: (e, st) => const SizedBox.shrink(),
      data: (broadcasts) {
        // Filter broadcasts
        final filtered = broadcasts.where((b) {
          final status = (b['status'] ?? 'ended') as String;
          if (filter == 'live') {
            return status == 'live';
          } else {
            return status != 'live';
          }
        }).toList();

        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filtered.map((broadcast) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildBroadcastCard(context, broadcast, channelAsync, channelName),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBroadcastCard(
    BuildContext context,
    Map<String, dynamic> broadcast,
    AsyncValue<dynamic> channelAsync,
    String channelName,
  ) {
    final title = broadcast['title'] ?? broadcast['broadcastId'] ?? 'Broadcast';
    final description = (broadcast['description'] as String?)?.trim() ?? '';
    final status = broadcast['status'] ?? 'ended';
    final listeners = broadcast['listeners'] ?? 0;
    final broadcastId = (broadcast['broadcastId'] ?? broadcast['id'] ?? '').toString();
    final replayUrl = (broadcast['audio_url'] ?? broadcast['streamUrl'] ?? '').toString();
    final startedAt = broadcast['startedAt'];
    final endedAt = broadcast['endedAt'];

    // Format duration
    String durationText = 'N/A';
    if (startedAt != null && status == 'ended' && endedAt != null) {
      try {
        final startTime = startedAt.toDate();
        final endTime = endedAt.toDate();
        final duration = endTime.difference(startTime);
        final minutes = duration.inMinutes;
        durationText = '$minutes mins';
      } catch (e) {
        durationText = 'N/A';
      }
    }

    final dateText = startedAt != null ? DateFormat('MMM dd, yyyy').format(startedAt.toDate()) : 'N/A';
    final timeText = startedAt != null ? DateFormat('h:mm a').format(startedAt.toDate()) : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2330),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'live' ? const Color(0xFFFF4B4D).withOpacity(0.3) : const Color(0xFF2E3D52),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with channel name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Channel name
              channelAsync.when(
                data: (channel) => Text(
                  channel?.name ?? 'Unknown Channel',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                error: (_, __) => const Text('Unknown', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'live'
                      ? const Color(0xFFFF4B4D).withOpacity(0.2)
                      : const Color(0xFF3B67AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status == 'live' ? const Color(0xFFFF4B4D) : const Color(0xFF3B67AA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status == 'live' ? 'LIVE' : 'PAST',
                      style: TextStyle(
                        color: status == 'live' ? const Color(0xFFFF4B4D) : const Color(0xFF3B67AA),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Broadcast title
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          // Date and time
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.5), size: 12),
              const SizedBox(width: 4),
              Text(
                '$dateText at $timeText',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration and listeners
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white.withOpacity(0.5), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    durationText,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
              if (status == 'live')
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.5), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$listeners listening',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Play button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (status == 'live' && broadcastId.isNotEmpty) {
                  context.push(AppRoutes.livePlayer, extra: {
                    'broadcastId': broadcastId,
                    'channelName': channelName,
                  });
                  return;
                }

                if (replayUrl.isNotEmpty) {
                  context.push(AppRoutes.replayPlayer, extra: {
                    'audioUrl': replayUrl,
                    'title': title,
                    'channelName': channelName,
                  });
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Replay audio is not available yet for this broadcast.')),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(status == 'live' ? 'Watch Live' : 'Watch Replay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'live' ? const Color(0xFFFF4B4D) : const Color(0xFF1D3C78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementReplayCard(
    BuildContext context,
    Map<String, dynamic> announcement,
    String channelName,
  ) {
    final title = (announcement['title'] ?? 'Announcement Replay').toString();
    final description = (announcement['description'] ?? '').toString().trim();
    final audioUrl = (announcement['audio_url'] ?? '').toString();
    final scheduledAt = announcement['scheduled_at'];

    String dateText = 'N/A';
    if (scheduledAt != null) {
      try {
        final dt = scheduledAt.toDate();
        dateText = DateFormat('MMM dd, yyyy • h:mm a').format(dt);
      } catch (_) {
        dateText = 'N/A';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2330),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B67AA).withOpacity(0.4), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                channelName,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B67AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ANNOUNCEMENT',
                  style: TextStyle(color: Color(0xFF3B67AA), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            dateText,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: audioUrl.isEmpty
                  ? null
                  : () {
                      context.push(AppRoutes.replayPlayer, extra: {
                        'audioUrl': audioUrl,
                        'title': title,
                        'channelName': channelName,
                      });
                    },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Play Announcement Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D3C78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
