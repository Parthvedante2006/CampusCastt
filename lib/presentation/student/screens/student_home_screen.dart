import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../../core/routes/app_router.dart';
import '../widgets/student_bottom_nav_bar.dart';
import 'student_dashboard_tab.dart';
import 'channels_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: const Color(0xFF080E1A),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentDashboardTab(),
          StudentBroadcastsTab(),
          ChannelsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ── BROADCASTS TAB ──────────────────────────────────────────────────────────

class StudentBroadcastsTab extends ConsumerWidget {
  const StudentBroadcastsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (user) {
        if (user == null || user.joinedChannels.isEmpty) {
          return _EmptyBroadcastsScaffold();
        }
        return _BroadcastsScaffold(
            user: user, joinedChannelIds: user.joinedChannels);
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF080E1A),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080E1A),
        body: Center(
            child:
                Text(message, style: const TextStyle(color: Colors.red))),
      );
}

class _EmptyBroadcastsScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Broadcasts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.filter_list,
                            color: Color(0xFF3B82F6), size: 16),
                        SizedBox(width: 4),
                        Text('Filter',
                            style: TextStyle(
                                color: Color(0xFF3B82F6), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2540),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.broadcast_on_personal_rounded,
                        color: Color(0xFF3B82F6),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No broadcasts yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join channels to see their broadcasts',
                      style: TextStyle(
                          color: Color(0xFF6B8DC3), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastsScaffold extends ConsumerWidget {
  final dynamic user;
  final List<String> joinedChannelIds;
  const _BroadcastsScaffold(
      {required this.user, required this.joinedChannelIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Broadcasts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2540),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF2E3D52), width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.filter_list,
                              color: Color(0xFF3B82F6), size: 16),
                          SizedBox(width: 4),
                          Text('Filter',
                              style: TextStyle(
                                  color: Color(0xFF3B82F6), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Section Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    _LiveDot(),
                    SizedBox(width: 8),
                    Text(
                      'LIVE NOW',
                      style: TextStyle(
                        color: Color(0xFFFF4B4D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Broadcasts list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final channelId = joinedChannelIds[index];
                  return _ChannelBroadcastSection(channelId: channelId);
                },
                childCount: joinedChannelIds.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFF4B4D),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChannelBroadcastSection extends ConsumerWidget {
  final String channelId;
  const _ChannelBroadcastSection({required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastsAsync = ref.watch(channelBroadcastsProvider(channelId));
    final replaysAsync =
        ref.watch(channelAnnouncementReplaysProvider(channelId));
    final channelAsync = ref.watch(channelProvider(channelId));

    final channelName = channelAsync.maybeWhen(
      data: (ch) => ch.name,
      orElse: () => 'Channel',
    );

    return broadcastsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (broadcasts) {
        final live =
            broadcasts.where((b) => b['status'] == 'live').toList();
        final past =
            broadcasts.where((b) => b['status'] != 'live').toList();

        return Column(
          children: [
            ...live.map((b) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _BroadcastCard(
                    broadcast: b,
                    channelName: channelName,
                    isLive: true,
                    context: context,
                  ),
                )),
            ...past.map((b) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _BroadcastCard(
                    broadcast: b,
                    channelName: channelName,
                    isLive: false,
                    context: context,
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  final Map<String, dynamic> broadcast;
  final String channelName;
  final bool isLive;
  final BuildContext context;

  const _BroadcastCard({
    required this.broadcast,
    required this.channelName,
    required this.isLive,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        broadcast['title'] ?? broadcast['broadcastId'] ?? 'Broadcast';
    final description =
        (broadcast['description'] as String?)?.trim() ?? '';
    final listeners = broadcast['listeners'] ?? 0;
    final broadcastId =
        (broadcast['broadcastId'] ?? broadcast['id'] ?? '').toString();
    final replayUrl =
        (broadcast['audio_url'] ?? broadcast['streamUrl'] ?? '').toString();
    final startedAt = broadcast['startedAt'];

    String dateText = '';
    if (startedAt != null) {
      try {
        dateText = DateFormat('MMM dd • h:mm a').format(startedAt.toDate());
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? const Color(0xFFFF4B4D).withOpacity(0.25)
              : const Color(0xFF1E2D42),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isLive
                  ? const Color(0xFFFF4B4D).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (isLive) const _LiveDot(),
                if (isLive) const SizedBox(width: 6),
                Text(
                  isLive ? 'LIVE' : channelName,
                  style: TextStyle(
                    color: isLive
                        ? const Color(0xFFFF4B4D)
                        : const Color(0xFF6B8DC3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (!isLive && dateText.isNotEmpty)
                  Text(dateText,
                      style: const TextStyle(
                          color: Color(0xFF4A5568), fontSize: 11)),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart,
                            color: Color(0xFFFF4B4D), size: 12),
                        const SizedBox(width: 4),
                        Text('$listeners',
                            style: const TextStyle(
                                color: Color(0xFFFF4B4D),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                        color: Color(0xFF6B8DC3), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isLive && broadcastId.isNotEmpty) {
                        context.push(AppRoutes.livePlayer, extra: {
                          'broadcastId': broadcastId,
                          'channelName': channelName,
                        });
                      } else if (replayUrl.isNotEmpty) {
                        context.push(AppRoutes.replayPlayer, extra: {
                          'audioUrl': replayUrl,
                          'title': title,
                          'channelName': channelName,
                        });
                      }
                    },
                    icon: Icon(
                      isLive ? Icons.headphones : Icons.play_arrow_rounded,
                      size: 16,
                    ),
                    label: Text(isLive ? 'Listen Live' : 'Play Replay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive
                          ? const Color(0xFFFF4B4D)
                          : const Color(0xFF1D3C78),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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
}

