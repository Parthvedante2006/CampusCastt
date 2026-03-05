import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/providers/student_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/models/event_model.dart';
import '../../../core/routes/app_router.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelDetailScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final joinedChannels = currentUserAsync.value?.joinedChannels ?? [];
    final isSubscribed = joinedChannels.contains(widget.channelId);
    final isDefault =
        channelAsync.value?.isDefault ?? false; // global channels can't be left

    return Scaffold(
      backgroundColor: const Color(0xFF141922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141922),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: channelAsync.when(
          data: (channel) => Text(
            channel.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          loading: () =>
              const Text('Loading...', style: TextStyle(color: Colors.white)),
          error: (_, __) =>
              const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: channelAsync.when(
        data: (channel) =>
            _buildBody(channel, isSubscribed, isDefault),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (e, st) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildBody(ChannelModel channel, bool isSubscribed, bool isDefault) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3C78),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        if (isDefault)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'OFFICIAL CHANNEL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title + Join/Leave Button ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          channel.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Global/default channels: always joined, no leave button
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E3D52),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            if (isSubscribed) {
                              // Leave channel
                              await ref
                                  .read(studentFirestoreProvider)
                                  .leaveChannel(channel.id);
                              ref.invalidate(currentUserProvider);
                            } else {
                              // Join channel
                              await ref
                                  .read(studentFirestoreProvider)
                                  .joinChannel(channel.id);
                              ref.invalidate(currentUserProvider);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscribed
                                ? const Color(0xFF2E3D52)
                                : const Color(0xFF1D3C78),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: Text(
                            isSubscribed ? 'Joined' : 'Join',
                            style: TextStyle(
                              color: isSubscribed
                                  ? Colors.white54
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Subtitle ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${channel.memberCount} members • ${channel.sectionName.isNotEmpty ? channel.sectionName : 'VIT Pune'}',
                    style: const TextStyle(
                        color: Color(0xFF6B8DC3),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Description ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'The official community of ${channel.name}. Join us for updates, announcements, and high-quality broadcasts.',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tabs ─────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Color(0xFF2E3D52), width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF1D3C78),
                    labelColor: const Color(0xFF4C7AD3),
                    unselectedLabelColor: Colors.white54,
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Events'),
                      Tab(text: 'Suggested'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnnouncementsTab(),
                      _buildEventsTab(),
                      _buildSuggestedTab(channel),
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

  // ── Suggested Tab ─────────────────────────────────────────────────────────
  // Shows channels from the same section as this channel, excluding ones
  // already joined and excluding global/default channels.

  Widget _buildSuggestedTab(ChannelModel thisChannel) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final joinedChannels =
        currentUserAsync.value?.joinedChannels ?? [];

    // If this channel belongs to a section, fetch that section's channels.
    // Otherwise fall back to global channels as suggestions.
    final sectionId = thisChannel.sectionId;

    if (sectionId == null || sectionId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No suggestions available',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    final sectionChannelsAsync =
        ref.watch(sectionChannelsProvider(sectionId));

    return sectionChannelsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.red, fontSize: 13))),
      data: (channels) {
        // Filter out: current channel, global/default channels, already joined
        final suggestions = channels
            .where((c) =>
                c.id != widget.channelId &&
                !c.isDefault &&
                !joinedChannels.contains(c.id))
            .toList();

        if (suggestions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No more channels to suggest in this section',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          itemBuilder: (context, i) {
            final ch = suggestions[i];
            return _buildSuggestedChannelCard(ch);
          },
        );
      },
    );
  }

  Widget _buildSuggestedChannelCard(ChannelModel channel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2330),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E3D52), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1D3C78),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.radio_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${channel.memberCount} members • ${channel.sectionName.isNotEmpty ? channel.sectionName : 'Same section'}',
                  style: const TextStyle(
                      color: Color(0xFF6B8DC3), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Join button
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(studentFirestoreProvider)
                  .joinChannel(channel.id);
              ref.invalidate(currentUserProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3C78),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Join',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Announcements Tab ─────────────────────────────────────────────────────

  Widget _buildAnnouncementsTab() {
    final broadcastsAsync =
        ref.watch(channelBroadcastsProvider(widget.channelId));
    final scheduledAsync =
        ref.watch(channelScheduledAnnouncementsProvider(widget.channelId));
    final replaysAsync =
        ref.watch(channelAnnouncementReplaysProvider(widget.channelId));

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Live Broadcasts
        broadcastsAsync.when(
          data: (broadcasts) {
            final live =
                broadcasts.where((b) => b['status'] == 'live').toList();
            if (live.isEmpty) return const SizedBox.shrink();
            return Column(
              children: live
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildLiveBroadcastCard(b),
                      ))
                  .toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Scheduled
        scheduledAsync.when(
          data: (scheduled) {
            if (scheduled.isEmpty) return const SizedBox.shrink();
            return Column(
              children: scheduled
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildScheduledAnnouncementCard(a),
                      ))
                  .toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Past (ended broadcasts + replays combined)
        broadcastsAsync.when(
          data: (broadcasts) {
            final ended =
                broadcasts.where((b) => b['status'] == 'ended').toList();
            return replaysAsync.when(
              data: (replays) {
                final all = <Map<String, dynamic>>[
                  ...ended.map((b) => {...b, '_type': 'broadcast'}),
                  ...replays.map((r) => {...r, '_type': 'announcement'}),
                ];
                if (all.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No past announcements yet',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 14)),
                    ),
                  );
                }
                all.sort((a, b) {
                  final aDate = _extractDate(a);
                  final bDate = _extractDate(b);
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });
                return Column(
                  children: [
                    ...all.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: item['_type'] == 'broadcast'
                              ? _buildPastBroadcastCard(item)
                              : _buildReplayAnnouncementCard(item),
                        )),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: Colors.blueAccent))),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Text('Error: $e',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13))),
              ),
            );
          },
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: Colors.blueAccent))),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
                child: Text('Error: $e',
                    style: const TextStyle(
                        color: Colors.red, fontSize: 13))),
          ),
        ),
      ],
    );
  }

  DateTime? _extractDate(Map<String, dynamic> item) {
    if (item['_type'] == 'broadcast') {
      final ts = item['endedAt'];
      if (ts is Timestamp) return ts.toDate();
    } else {
      final ts = item['scheduled_at'];
      if (ts is Timestamp) return ts.toDate();
    }
    return null;
  }

  // ── Events Tab ────────────────────────────────────────────────────────────

  Widget _buildEventsTab() {
    final eventsAsync =
        ref.watch(channelEventsProvider(widget.channelId));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No events yet',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 14)),
            ),
          );
        }
        final sorted = List<EventModel>.from(events)
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sorted.length + 1,
          itemBuilder: (context, index) {
            if (index == sorted.length) return const SizedBox(height: 32);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventCard(sorted[index]),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style:
                  const TextStyle(color: Colors.red, fontSize: 13))),
    );
  }

  // ── Card Builders ─────────────────────────────────────────────────────────

  Widget _buildEventCard(EventModel event) {
    final now = DateTime.now();
    final isUpcoming = event.eventDate.isAfter(now);
    final dateStr = DateFormat('MMM dd, yyyy').format(event.eventDate);
    final timeStr = DateFormat('h:mm a').format(event.eventDate);
    final daysUntil = event.eventDate.difference(now).inDays;

    return GestureDetector(
      onTap: () =>
          context.push('/student/event/${event.id}', extra: {'event': event}),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2330),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUpcoming
                ? const Color(0xFF3B67AA)
                : const Color(0xFF2E3D52),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? const Color(0xFF1A263B)
                        : const Color(0xFF2E3D52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUpcoming ? 'UPCOMING' : 'PAST',
                    style: TextStyle(
                      color: isUpcoming
                          ? const Color(0xFF3B67AA)
                          : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isUpcoming && daysUntil <= 7)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C191D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      daysUntil == 0 ? 'TODAY' : 'In $daysUntil days',
                      style: const TextStyle(
                        color: Color(0xFFFF4B4D),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF3B67AA), size: 14),
                const SizedBox(width: 8),
                Text('$dateStr at $timeStr',
                    style: const TextStyle(
                        color: Color(0xFF6B8DC3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF3B67AA), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(event.location!,
                        style: const TextStyle(
                            color: Color(0xFF6B8DC3),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (event.description != null &&
                event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.description!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBroadcastCard(Map<String, dynamic> broadcast) {
    final title = broadcast['title']?.toString() ?? 'Untitled Broadcast';
    final description = broadcast['description']?.toString() ?? '';
    final broadcastId = broadcast['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (broadcastId.isNotEmpty) {
          context.push(AppRoutes.livePlayer,
              extra: {'broadcastId': broadcastId});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C191D),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: const Color(0xFF4A252A), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF4B4D),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('LIVE NOW',
                    style: TextStyle(
                        color: Color(0xFFFF4B4D),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 4,
                      height: 12.0 + (i % 3) * 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (broadcastId.isNotEmpty) {
                      context.push(AppRoutes.livePlayer,
                          extra: {'broadcastId': broadcastId});
                    }
                  },
                  icon: const Icon(Icons.headphones,
                      color: Colors.white, size: 16),
                  label: const Text('Listen',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B4D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledAnnouncementCard(
      Map<String, dynamic> announcement) {
    final title =
        announcement['title']?.toString() ?? 'Untitled Announcement';
    final description = announcement['description']?.toString() ?? '';
    final scheduledAt = announcement['scheduled_at'];

    DateTime? scheduledDate;
    if (scheduledAt is Timestamp) scheduledDate = scheduledAt.toDate();

    String timeText = 'SCHEDULED';
    if (scheduledDate != null) {
      final now = DateTime.now();
      final diff = scheduledDate.difference(now);
      if (scheduledDate.day == now.day &&
          scheduledDate.month == now.month &&
          scheduledDate.year == now.year) {
        timeText =
            'SCHEDULED • TODAY, ${DateFormat('h:mm a').format(scheduledDate)}';
      } else if (diff.inDays == 1) {
        timeText =
            'SCHEDULED • TOMORROW, ${DateFormat('h:mm a').format(scheduledDate)}';
      } else if (diff.inDays < 7) {
        timeText =
            'SCHEDULED • ${DateFormat('EEEE, h:mm a').format(scheduledDate)}';
      } else {
        timeText =
            'SCHEDULED • ${DateFormat('MMM dd, h:mm a').format(scheduledDate)}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16202E),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time,
                  color: Color(0xFF3B67AA), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(timeText,
                    style: const TextStyle(
                        color: Color(0xFF3B67AA),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_active,
                  color: Color(0xFF3B67AA), size: 16),
              label: const Text('Remind Me',
                  style: TextStyle(
                      color: Color(0xFF3B67AA),
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1A263B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastBroadcastCard(Map<String, dynamic> broadcast) {
    final title = broadcast['title']?.toString() ?? 'Untitled Broadcast';
    final description = broadcast['description']?.toString() ?? '';
    final endedAt = broadcast['endedAt'];

    DateTime? endedDate;
    if (endedAt is Timestamp) endedDate = endedAt.toDate();
    final timeAgo = _formatTimeAgo(endedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2330),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D52),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PAST BROADCAST',
                    style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5)),
              ),
              Text(timeAgo,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            _descriptionBox(description),
          ],
          const SizedBox(height: 12),
          _noRecordingBox(),
        ],
      ),
    );
  }

  Widget _buildReplayAnnouncementCard(Map<String, dynamic> announcement) {
    final title =
        announcement['title']?.toString() ?? 'Untitled Announcement';
    final description = announcement['description']?.toString() ?? '';
    final audioUrl = announcement['audio_url']?.toString() ?? '';
    final scheduledAt = announcement['scheduled_at'];
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final channelName = channelAsync.value?.name ?? 'Channel';

    DateTime? date;
    if (scheduledAt is Timestamp) date = scheduledAt.toDate();
    final timeAgo = _formatTimeAgo(date);

    return GestureDetector(
      onTap: () {
        if (audioUrl.isNotEmpty) {
          context.push(AppRoutes.replayPlayer, extra: {
            'audioUrl': audioUrl,
            'title': title,
            'channelName': channelName,
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2330),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(timeAgo,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _descriptionBox(description),
            ],
            const SizedBox(height: 16),
            // Play row
            Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF1D3C78), shape: BoxShape.circle),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2E3D52),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Tap to play',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Past';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return diff.inHours == 0
          ? '${diff.inMinutes} min ago'
          : '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  Widget _descriptionBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121822),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF3B67AA), size: 14),
              SizedBox(width: 6),
              Text('DESCRIPTION',
                  style: TextStyle(
                      color: Color(0xFF3B67AA),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _noRecordingBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121822),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.info, color: Color(0xFF6B8DC3), size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This was a live broadcast. Recording not available.',
              style: TextStyle(
                  color: Color(0xFF6B8DC3),
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

