import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../core/routes/app_router.dart';
import '../widgets/channel_bottom_nav_bar.dart';

class BroadcastScreen extends ConsumerWidget {
  const BroadcastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF112240),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Broadcast',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.red, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile screen coming soon')),
                );
              },
            ),
          ),
        ],
      ),
      body: currentUserAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please login',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final channelId = user.channelId;
          if (channelId == null || channelId.isEmpty) {
            return const Center(
              child: Text(
                'No channel assigned',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return _buildBroadcastBody(context, ref, channelId);
        },
      ),
    );
  }

  Widget _buildBroadcastBody(BuildContext context, WidgetRef ref, String channelId) {
    final broadcastsAsync = ref.watch(channelBroadcastsProvider(channelId));
    final channelAsync = ref.watch(channelProvider(channelId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(channelBroadcastsProvider(channelId));
        ref.invalidate(channelProvider(channelId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Cards
            _buildActionCards(context, ref, channelId, channelAsync),
            const SizedBox(height: 40),

            // Past Broadcasts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Past Broadcasts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All broadcasts coming soon')),
                    );
                  },
                  child: const Text(
                    'SEE ALL',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Broadcasts List
            _buildBroadcastsList(broadcastsAsync, context),
          ],
        ),
      ),
    );
  }


  Widget _buildActionCards(BuildContext context, WidgetRef ref, String channelId, AsyncValue<dynamic> channelAsync) {
    return channelAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading channel',
          style: TextStyle(color: Colors.red),
        ),
      ),
      data: (channel) => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to go live screen
                context.push(AppRoutes.goLive, extra: {
                  'channelId': channelId,
                  'channelName': channel.name,
                });
              },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Go Live Now',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to schedule announcement screen
                    context.push(AppRoutes.scheduleAnnouncement, extra: {
                      'channelId': channelId,
                      'channelName': channel.name,
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Schedule',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBroadcastsList(AsyncValue<List<Map<String, dynamic>>> broadcastsAsync, BuildContext context) {
    return broadcastsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Error loading broadcasts: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (broadcasts) {
        if (broadcasts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.broadcast_on_personal,
                    color: Colors.white24,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No broadcasts yet',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start your first broadcast to see it here',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: broadcasts.asMap().entries.map((entry) {
            return _buildBroadcastCard(entry.value, entry.key, context);
          }).toList(),
        );
      },
    );
  }

  Widget _buildBroadcastCard(Map<String, dynamic> broadcast, int index, BuildContext context) {
    final title = broadcast['title'] ?? broadcast['broadcastId'] ?? 'Broadcast';
    final listeners = broadcast['listeners'] ?? 0;
    final status = broadcast['status'] ?? 'ended';
    final startedAt = broadcast['startedAt'];
    final endedAt = broadcast['endedAt'];

    // Calculate duration
    String durationText = 'N/A';
    if (startedAt != null && status == 'ended' && endedAt != null) {
      try {
        final startTime = startedAt.toDate();
        final endTime = endedAt.toDate();
        final duration = endTime.difference(startTime);
        final minutes = duration.inMinutes;
        durationText = '$minutes mins';
      } catch (e) {
        durationText = 'Unknown';
      }
    }

    // Format date
    String dateText = 'N/A';
    if (startedAt != null) {
      try {
        final dateTime = startedAt.toDate();
        dateText = DateFormat('MMM dd, yyyy').format(dateTime);
      } catch (e) {
        dateText = 'Invalid date';
      }
    }

    // Alternate wave icon colors
    final isRedWave = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
      ),
      child: Row(
        children: [
          // Wave Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (isRedWave ? Colors.red : const Color(0xFF2563EB))
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.graphic_eq,
              color: isRedWave ? Colors.red : const Color(0xFF2563EB),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Broadcast Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$listeners listened',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      durationText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Stats Icon and Chevron
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast details coming soon')),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bar_chart,
                  color: Colors.white38,
                  size: 20,
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
