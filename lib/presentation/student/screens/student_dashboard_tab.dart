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
    // We fetch sections to show pills
    final sectionsAsync = ref.watch(studentSectionsProvider);
    final selectedSectionId = ref.watch(selectedSectionIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: _buildAppBar(),
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
              const SizedBox(height: 16),
              // Sections Pill List
              sectionsAsync.when(
                data: (sections) {
                  if (sections.isEmpty) return const SizedBox.shrink();
                  // Automatically select the first section if none is selected
                  if (selectedSectionId.isEmpty) {
                    Future.microtask(() => ref.read(selectedSectionIdProvider.notifier).updateId(sections.first.id));
                  }
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: sections.map((section) {
                        final isSelected = selectedSectionId == section.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(selectedSectionIdProvider.notifier).updateId(section.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.white24,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                section.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Text('Error loading sections', style: TextStyle(color: Colors.red)),
              ),
              
              const SizedBox(height: 32),
              
              // Section Channels
              _buildSectionChannels(ref),
              
              const SizedBox(height: 32),
              
              // Live Now
              _buildLiveNowSection(ref),
              
              const SizedBox(height: 32),
              
              // Today's Events
              _buildEventsSection(ref, isToday: true),
              
              const SizedBox(height: 32),
              
              // Upcoming Events
              _buildEventsSection(ref, isToday: false),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A1628),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E3A5F),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'VIT Pune', // Make dynamic if college name varies
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0, left: 8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF2563EB),
            radius: 16,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionChannels(WidgetRef ref) {
    final selectedSectionId = ref.watch(selectedSectionIdProvider);
    if (selectedSectionId.isEmpty) return const SizedBox.shrink();

    final channelsAsync = ref.watch(sectionChannelsProvider(selectedSectionId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final joinedChannels = currentUserAsync.value?.joinedChannels ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Channels in Section',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        channelsAsync.when(
          data: (channels) {
            if (channels.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No channels in this section', style: TextStyle(color: Colors.white54)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2563EB),
                    child: Icon(Icons.radio, color: Colors.white),
                  ),
                  title: Text(
                    channel.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${channel.memberCount} members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: joinedChannels.contains(channel.id)
                      ? const Text('Subscribed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : ElevatedButton(
                    onPressed: () async {
                      await ref.read(studentFirestoreProvider).joinChannel(channel.id);
                      ref.invalidate(currentUserProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Subscribe', style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error loading channels: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildLiveNowSection(WidgetRef ref) {
    final liveBroadcastsAsync = ref.watch(studentLiveBroadcastsProvider);
    final selectedSectionId = ref.watch(selectedSectionIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Now',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'VIEW ALL',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        liveBroadcastsAsync.when(
          data: (broadcasts) {
            // Ideally filter by selected section's channels.
            if (broadcasts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No live broadcasts', style: TextStyle(color: Colors.white54)),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: broadcasts.length,
                itemBuilder: (context, index) {
                  final b = broadcasts[index];
                  // If we need to filter by section_id, we'd look up the channel info
                  return _buildLiveCard(context, b);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildLiveCard(BuildContext context, Map<String, dynamic> broadcast) {
    // Dummy / Missing info fallback
    final channelName = broadcast['channelName'] ?? 'Unknown Channel';
    final broadcastTitle = broadcast['title'] ?? 'Live Broadcast';
    final listeners = broadcast['listeners'] ?? 0;

    return Container(
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                channelName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                broadcastTitle,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text('$listeners listening', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 16,
            child: GestureDetector(
              onTap: () {
                // Navigate to live player
                // context.push(AppRoutes.studentLivePlayer, extra: {'broadcastId': broadcast['id']} )
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(WidgetRef ref, {required bool isToday}) {
    final eventsAsync = ref.watch(studentEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            isToday ? "Today's Events" : "Upcoming Events",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        eventsAsync.when(
          data: (events) {
            final now = DateTime.now();
            final filtered = events.where((e) {
              final isEventToday = e.eventDate.year == now.year && e.eventDate.month == now.month && e.eventDate.day == now.day;
              return isToday ? isEventToday : !isEventToday && e.eventDate.isAfter(now);
            }).toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No events found', style: TextStyle(color: Colors.white54)),
              );
            }

            return SizedBox(
              height: isToday ? 150 : 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return isToday ? _buildTodayEventCard(filtered[index]) : _buildUpcomingEventCard(filtered[index]);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildTodayEventCard(EventModel event) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(20),
        // Add image background if imageUrl provided properly
        image: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(event.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${DateFormat('h:mm a').format(event.eventDate)} • ${event.location ?? 'TBA'}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard(EventModel event) {
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
            child: const Icon(Icons.sports_basketball, color: Colors.blueAccent, size: 24), // Dynamic icon based on category ideally
          ),
          const Spacer(),
          Text(
            DateFormat('E, h a').format(event.eventDate).toUpperCase(),
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
