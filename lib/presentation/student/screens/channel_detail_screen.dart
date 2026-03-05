import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/providers/student_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/models/event_model.dart';

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
    return ListView(
      physics: const NeverScrollableScrollPhysics(), // Scroll managed by outer scroll view
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        // Live Now Card Mockup
        _buildLiveNowCard(),
        const SizedBox(height: 16),
        // Scheduled Card Mockup
        _buildScheduledCard(),
        const SizedBox(height: 16),
        // Replay/Past Broadcast Mockup
        _buildReplayCard("GSOC 2024 Roadmap", "2 days ago", "Step-by-step guide for open-source contributions. Key deadlines mentioned: Jan 15th for initial drafts."),
        const SizedBox(height: 16),
        _buildReplayCard("Web3 & Blockchain Basics", "Last Friday", "Intro to Ethereum, Smart Contracts, and the future of decentralized apps. Q&A session at the end."),
        const SizedBox(height: 32),
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
