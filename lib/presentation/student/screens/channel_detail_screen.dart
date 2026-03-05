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
  ConsumerState<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> with SingleTickerProviderStateMixin {
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
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.white)),
          error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: channelAsync.when(
        data: (channel) => _buildBody(channel, isSubscribed),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildBody(ChannelModel channel, bool isSubscribed) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3C78), // Blueish banner
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        if (channel.isDefault)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                
                // Title and Join Button row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          channel.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (!isSubscribed) {
                            await ref.read(studentFirestoreProvider).joinChannel(channel.id);
                            ref.invalidate(currentUserProvider);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSubscribed ? const Color(0xFF2E3D52) : const Color(0xFF1D3C78),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        child: Text(
                          isSubscribed ? 'Joined' : 'Join',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${channel.memberCount} members • ${channel.sectionName.isNotEmpty ? channel.sectionName : 'VIT Pune'}',
                    style: const TextStyle(color: Color(0xFF6B8DC3), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'The official community of ${channel.name}. Join us for updates, announcements, and high-quality broadcasts.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                
                // TabBar
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3D52), width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF1D3C78),
                    labelColor: const Color(0xFF4C7AD3),
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Events'),
                      Tab(text: 'Polls'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Fixed height for TabBarView to allow scrolling within a Column.
                // Using a Container with a generic robust height.
                SizedBox(
                  height: 600, 
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnnouncementsTab(),
                      _buildEventsTab(),
                      const Center(child: Text('Polls (Coming Soon)', style: TextStyle(color: Colors.white))),
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

  Widget _buildAnnouncementsTab() {
    final broadcastsAsync = ref.watch(channelBroadcastsProvider(widget.channelId));
    final scheduledAsync = ref.watch(channelScheduledAnnouncementsProvider(widget.channelId));
    final replaysAsync = ref.watch(channelAnnouncementReplaysProvider(widget.channelId));

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        // Live Broadcasts Section
        broadcastsAsync.when(
          data: (broadcasts) {
            final liveBroadcasts = broadcasts.where((b) => b['status'] == 'live').toList();
            if (liveBroadcasts.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: [
                ...liveBroadcasts.map((broadcast) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildLiveBroadcastCard(broadcast),
                )),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Scheduled Announcements Section
        scheduledAsync.when(
          data: (scheduled) {
            if (scheduled.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: [
                ...scheduled.map((announcement) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildScheduledAnnouncementCard(announcement),
                )),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Past Section: Ended Broadcasts + Announcement Replays
        broadcastsAsync.when(
          data: (broadcasts) {
            final endedBroadcasts = broadcasts.where((b) => b['status'] == 'ended').toList();
            
            return replaysAsync.when(
              data: (replays) {
                // Combine ended broadcasts and announcement replays
                final allPastItems = <Map<String, dynamic>>[];
                
                // Add ended broadcasts with a type marker
                for (final broadcast in endedBroadcasts) {
                  allPastItems.add({...broadcast, '_type': 'broadcast'});
                }
                
                // Add announcement replays with a type marker
                for (final replay in replays) {
                  allPastItems.add({...replay, '_type': 'announcement'});
                }
                
                if (allPastItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No past announcements yet',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  );
                }
                
                // Sort by time (most recent first)
                allPastItems.sort((a, b) {
                  DateTime? aDate;
                  DateTime? bDate;
                  
                  if (a['_type'] == 'broadcast') {
                    final endedAt = a['endedAt'];
                    if (endedAt is Timestamp) {
                      aDate = endedAt.toDate();
                    }
                  } else {
                    final scheduledAt = a['scheduled_at'];
                    if (scheduledAt is Timestamp) {
                      aDate = scheduledAt.toDate();
                    }
                  }
                  
                  if (b['_type'] == 'broadcast') {
                    final endedAt = b['endedAt'];
                    if (endedAt is Timestamp) {
                      bDate = endedAt.toDate();
                    }
                  } else {
                    final scheduledAt = b['scheduled_at'];
                    if (scheduledAt is Timestamp) {
                      bDate = scheduledAt.toDate();
                    }
                  }
                  
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate); // Most recent first
                });
                
                return Column(
                  children: [
                    ...allPastItems.map((item) {
                      if (item['_type'] == 'broadcast') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildPastBroadcastCard(item),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildReplayAnnouncementCard(item),
                        );
                      }
                    }),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Error loading past announcements: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Error loading announcements: $e',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    final eventsAsync = ref.watch(channelEventsProvider(widget.channelId));
    
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No events yet', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ),
          );
        }

        // Sort events by date (upcoming first)
        final sortedEvents = List<EventModel>.from(events)
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: sortedEvents.length + 1,
          itemBuilder: (context, index) {
            if (index == sortedEvents.length) {
              return const SizedBox(height: 32);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildEventCard(sortedEvents[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      error: (e, st) => Center(
        child: Text('Error loading events: $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final now = DateTime.now();
    final isUpcoming = event.eventDate.isAfter(now);
    final dateStr = DateFormat('MMM dd, yyyy').format(event.eventDate);
    final timeStr = DateFormat('h:mm a').format(event.eventDate);
    final daysUntil = event.eventDate.difference(now).inDays;

    return GestureDetector(
      onTap: () {
        context.push(
          '/student/event/${event.id}',
          extra: {'event': event},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2330),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUpcoming ? const Color(0xFF3B67AA) : const Color(0xFF2E3D52),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUpcoming ? const Color(0xFF1A263B) : const Color(0xFF2E3D52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUpcoming ? 'UPCOMING' : 'PAST',
                    style: TextStyle(
                      color: isUpcoming ? const Color(0xFF3B67AA) : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isUpcoming && daysUntil <= 7)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            // Event title
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF3B67AA), size: 14),
                const SizedBox(width: 8),
                Text(
                  '$dateStr at $timeStr',
                  style: const TextStyle(
                    color: Color(0xFF6B8DC3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            if (event.location != null && event.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF3B67AA), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(
                          color: Color(0xFF6B8DC3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Description
            if (event.description != null && event.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  event.description!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (event.registrationLink != null && event.registrationLink!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Open registration link
                        // launchUrl(Uri.parse(event.registrationLink!));
                      },
                      icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                      label: const Text('Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D3C78),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                if (event.paymentLink != null && event.paymentLink!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Open payment link
                        // launchUrl(Uri.parse(event.paymentLink!));
                      },
                      icon: const Icon(Icons.payment, size: 14, color: Colors.white),
                      label: const Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C4A6B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
            ),
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
          context.push(
            AppRoutes.livePlayer,
            extra: {'broadcastId': broadcastId},
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C191D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4A252A), width: 1),
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
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE NOW',
                  style: TextStyle(
                    color: Color(0xFFFF4B4D),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Waveform animation
                Row(
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 4,
                      height: 12.0 + (index % 3) * 6,
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
                      context.push(
                        AppRoutes.livePlayer,
                        extra: {'broadcastId': broadcastId},
                      );
                    }
                  },
                  icon: const Icon(Icons.headphones, color: Colors.white, size: 16),
                  label: const Text(
                    'Listen',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B4D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledAnnouncementCard(Map<String, dynamic> announcement) {
    final title = announcement['title']?.toString() ?? 'Untitled Announcement';
    final description = announcement['description']?.toString() ?? '';
    final scheduledAt = announcement['scheduled_at'];
    
    DateTime? scheduledDate;
    if (scheduledAt is Timestamp) {
      scheduledDate = scheduledAt.toDate();
    }

    String timeText = 'SCHEDULED';
    if (scheduledDate != null) {
      final now = DateTime.now();
      final difference = scheduledDate.difference(now);
      
      if (scheduledDate.day == now.day &&
          scheduledDate.month == now.month &&
          scheduledDate.year == now.year) {
        timeText = 'SCHEDULED • TODAY, ${DateFormat('h:mm a').format(scheduledDate)}';
      } else if (difference.inDays == 1) {
        timeText = 'SCHEDULED • TOMORROW, ${DateFormat('h:mm a').format(scheduledDate)}';
      } else if (difference.inDays < 7) {
        timeText = 'SCHEDULED • ${DateFormat('EEEE, h:mm a').format(scheduledDate)}';
      } else {
        timeText = 'SCHEDULED • ${DateFormat('MMM dd, h:mm a').format(scheduledDate)}';
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
              const Icon(Icons.access_time, color: Color(0xFF3B67AA), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timeText,
                  style: const TextStyle(
                    color: Color(0xFF3B67AA),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // TODO: Implement reminder functionality
              },
              icon: const Icon(Icons.notifications_active, color: Color(0xFF3B67AA), size: 16),
              label: const Text(
                'Remind Me',
                style: TextStyle(color: Color(0xFF3B67AA), fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1A263B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final channelName = channelAsync.value?.name ?? 'Channel';

    DateTime? endedDate;
    if (endedAt is Timestamp) {
      endedDate = endedAt.toDate();
    }

    String timeAgo = 'Past';
    if (endedDate != null) {
      final now = DateTime.now();
      final difference = now.difference(endedDate);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          timeAgo = '${difference.inMinutes} min ago';
        } else {
          timeAgo = '${difference.inHours} hours ago';
        }
      } else if (difference.inDays == 1) {
        timeAgo = 'Yesterday';
      } else if (difference.inDays < 7) {
        timeAgo = '${difference.inDays} days ago';
      } else {
        timeAgo = DateFormat('MMM dd').format(endedDate);
      }
    }

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D52),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PAST BROADCAST',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
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
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          color: Color(0xFF3B67AA),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
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
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplayAnnouncementCard(Map<String, dynamic> announcement) {
    final title = announcement['title']?.toString() ?? 'Untitled Announcement';
    final description = announcement['description']?.toString() ?? '';
    final audioUrl = announcement['audio_url']?.toString() ?? '';
    final scheduledAt = announcement['scheduled_at'];
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final channelName = channelAsync.value?.name ?? 'Channel';

    DateTime? scheduledDate;
    if (scheduledAt is Timestamp) {
      scheduledDate = scheduledAt.toDate();
    }

    String timeAgo = 'Past';
    if (scheduledDate != null) {
      final now = DateTime.now();
      final difference = now.difference(scheduledDate);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          timeAgo = '${difference.inMinutes} min ago';
        } else {
          timeAgo = '${difference.inHours} hours ago';
        }
      } else if (difference.inDays == 1) {
        timeAgo = 'Yesterday';
      } else if (difference.inDays < 7) {
        timeAgo = '${difference.inDays} days ago';
      } else {
        timeAgo = DateFormat('MMM dd').format(scheduledDate);
      }
    }

    return GestureDetector(
      onTap: () {
        if (audioUrl.isNotEmpty) {
          context.push(
            AppRoutes.replayPlayer,
            extra: {
              'audioUrl': audioUrl,
              'title': title,
              'channelName': channelName,
            },
          );
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
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
                        Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            color: Color(0xFF3B67AA),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Play button
            GestureDetector(
              onTap: () {
                if (audioUrl.isNotEmpty) {
                  context.push(
                    AppRoutes.replayPlayer,
                    extra: {
                      'audioUrl': audioUrl,
                      'title': title,
                      'channelName': channelName,
                    },
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D3C78),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D52),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tap to play',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveNowCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C191D), // Dark reddish tint
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4A252A), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFFFF4B4D), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('LIVE NOW', style: TextStyle(color: Color(0xFFFF4B4D), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Pre-Hackathon Briefing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Discussing rules and team formations for upcoming VIT-Hacks.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Waveform Dummy
              Row(
                children: List.generate(5, (index) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 4,
                  height: 12.0 + (index % 3) * 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.headphones, color: Colors.white, size: 16),
                label: const Text('Listen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16202E), // Dark blueish tint
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: Color(0xFF3B67AA), size: 14),
              SizedBox(width: 6),
              Text('SCHEDULED • TODAY, 6:00 PM', style: TextStyle(color: Color(0xFF3B67AA), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Weekly DSA Session', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Topic: Advanced Dynamic Programming. Guest: Alumnus from Google.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_active, color: Color(0xFF3B67AA), size: 16),
              label: const Text('Remind Me', style: TextStyle(color: Color(0xFF3B67AA), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1A263B), // Button Bg
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReplayCard(String title, String timeAgo, String summary) {
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
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              Text(timeAgo, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          // AI Summary Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121822),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF3B67AA), size: 14),
                    const SizedBox(width: 6),
                    const Text('AI SUMMARY', style: TextStyle(color: Color(0xFF3B67AA), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('"$summary"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Player Mock
          Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1D3C78),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3D52),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3C78),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('12:45', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
