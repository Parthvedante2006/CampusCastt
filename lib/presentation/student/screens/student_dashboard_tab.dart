import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../domain/providers/student_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../data/models/event_model.dart';

class StudentDashboardTab extends ConsumerWidget {
  const StudentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(studentSectionsProvider);
    final selectedSectionId = ref.watch(selectedSectionIdProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    final userName = currentUserAsync.maybeWhen(
      data: (u) => u?.name?.split(' ').first ?? 'Student',
      orElse: () => 'Student',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentSectionsProvider);
          ref.invalidate(studentLiveBroadcastsProvider);
          ref.invalidate(studentEventsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Logo + College
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E3A5F),
                            ),
                            child: const Icon(Icons.school,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'VIT Pune',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bell icon
                      IconButton(
                        icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                      // Avatar
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Section Pills ────────────────────────
              sectionsAsync.when(
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox.shrink(),
                data: (sections) {
                  if (sections.isEmpty) return const SizedBox.shrink();
                  if (selectedSectionId.isEmpty) {
                    Future.microtask(() => ref
                        .read(selectedSectionIdProvider.notifier)
                        .updateId(sections.first.id));
                  }
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sections.length,
                      itemBuilder: (context, i) {
                        final section = sections[i];
                        final selected = selectedSectionId == section.id;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedSectionIdProvider.notifier)
                              .updateId(section.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              section.name,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0A1628)
                                    : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Section Channels ─────────────────────
              _buildSectionChannels(ref),

              const SizedBox(height: 28),

              // ── Live Now ─────────────────────────────
              _buildLiveNow(ref),

              const SizedBox(height: 28),

              // ── Today's Events ───────────────────────
              _buildEventsSection(ref, isToday: true),

              const SizedBox(height: 28),

              // ── Upcoming Events ───────────────────────
              _buildEventsSection(ref, isToday: false),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Channels ────────────────────────────────────────────────────

  Widget _buildSectionChannels(WidgetRef ref) {
    final selectedSectionId = ref.watch(selectedSectionIdProvider);
    if (selectedSectionId.isEmpty) return const SizedBox.shrink();

    final channelsAsync =
        ref.watch(sectionChannelsProvider(selectedSectionId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final joinedChannels = currentUserAsync.value?.joinedChannels ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Channels in Section',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        channelsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => const SizedBox.shrink(),
          data: (channels) {
            if (channels.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No channels in this section',
                    style: TextStyle(color: Colors.white54)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final subscribed = joinedChannels.contains(channel.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2563EB),
                    child: Icon(Icons.radio, color: Colors.white),
                  ),
                  title: Text(channel.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${channel.memberCount} members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: subscribed
                      ? const Text('Subscribed',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold))
                      : ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(studentFirestoreProvider)
                                .joinChannel(channel.id);
                            ref.invalidate(currentUserProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Subscribe',
                              style: TextStyle(color: Colors.white)),
                        ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── Live Now ─────────────────────────────────────────────────────────────

  Widget _buildLiveNow(WidgetRef ref) {
    final liveBroadcastsAsync = ref.watch(studentLiveBroadcastsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('VIEW ALL',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        liveBroadcastsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No live broadcasts',
                    style: TextStyle(color: Colors.white54)),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: broadcasts.length,
                itemBuilder: (context, i) =>
                    _LiveCard(broadcast: broadcasts[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Events Section ────────────────────────────────────────────────────────

  Widget _buildEventsSection(WidgetRef ref, {required bool isToday}) {
    final eventsAsync = ref.watch(studentEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isToday ? "Today's Events" : "Upcoming Events",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        eventsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (events) {
            final now = DateTime.now();
            final filtered = events.where((e) {
              final isEventToday = e.eventDate.year == now.year &&
                  e.eventDate.month == now.month &&
                  e.eventDate.day == now.day;
              return isToday
                  ? isEventToday
                  : !isEventToday && e.eventDate.isAfter(now);
            }).toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No events found',
                    style: TextStyle(color: Colors.white54)),
              );
            }

            return SizedBox(
              height: isToday ? 150 : 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => isToday
                    ? _TodayEventCard(event: filtered[i])
                    : _UpcomingEventCard(event: filtered[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Live Card ──────────────────────────────────────────────────────────────

class _LiveCard extends StatefulWidget {
  final Map<String, dynamic> broadcast;
  const _LiveCard({required this.broadcast});

  @override
  State<_LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<_LiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelName =
        widget.broadcast['channelName'] ?? 'Unknown Channel';
    final title = widget.broadcast['title'] ?? 'Live Broadcast';
    final listeners = widget.broadcast['listeners'] ?? 0;
    final broadcastId =
        (widget.broadcast['broadcastId'] ?? widget.broadcast['id'] ?? '')
            .toString();

    return GestureDetector(
      onTap: () {
        if (broadcastId.isNotEmpty) {
          context.push(AppRoutes.livePlayer, extra: {
            'broadcastId': broadcastId,
            'channelName': channelName,
          });
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LIVE badge with animated dot
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(channelName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                // Audio wave bars
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Row(
                      children: List.generate(12, (i) {
                        final heights = [8.0, 14.0, 10.0, 18.0, 12.0,
                            16.0, 8.0, 20.0, 10.0, 14.0, 6.0, 16.0];
                        final h = heights[i] *
                            (0.6 +
                                0.4 *
                                    (i % 3 == 0
                                        ? _ctrl.value
                                        : i % 3 == 1
                                            ? 1 - _ctrl.value
                                            : 0.5));
                        return Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 3,
                          height: h,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
            // Play button + listener count
            Positioned(
              right: 0,
              top: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.bar_chart,
                          color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text('$listeners listening',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today Event Card ───────────────────────────────────────────────────────

class _TodayEventCard extends StatelessWidget {
  final EventModel event;
  const _TodayEventCard({required this.event});

  static const _gradients = [
    [Color(0xFF1A3A6B), Color(0xFF0D5C8C)],
    [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    [Color(0xFF4A1942), Color(0xFF7B2D8B)],
    [Color(0xFF7B3F00), Color(0xFFC05A00)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = event.title.hashCode.abs() % _gradients.length;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradients[idx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        image: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(event.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5), BlendMode.darken),
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${DateFormat('h:mm a').format(event.eventDate)}${event.location != null ? ' • ${event.location}' : ''}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Event Card ────────────────────────────────────────────────────

class _UpcomingEventCard extends StatelessWidget {
  final EventModel event;
  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF112240),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_basketball,
                color: Colors.blueAccent, size: 24),
          ),
          const Spacer(),
          Text(
            DateFormat('E, h a').format(event.eventDate).toUpperCase(),
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

