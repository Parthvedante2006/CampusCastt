import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/models/event_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';
import '../../section_owner/screens/event_detail_screen.dart'
    as section_owner;
import 'post_event_screen.dart' as channel_owner;
import '../widgets/channel_bottom_nav_bar.dart';

class ChannelOwnerEventsScreen extends ConsumerWidget {
  const ChannelOwnerEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const channel_owner.ChannelOwnerPostEventScreen(),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF4A9EFF),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentUserAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (user) {
          if (user == null || user.channelId == null || user.channelId!.isEmpty) {
            return const Center(
              child: Text(
                'No channel assigned to your account.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final eventsAsync = ref.watch(channelEventsProvider(user.channelId!));

          return eventsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading events',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            data: (events) => _buildEventsBody(context, events),
          );
        },
      ),
    );
  }

  Widget _buildEventsBody(BuildContext context, List<EventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              color: Colors.white.withOpacity(0.2),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No events yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first event',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final upcoming =
        events.where((e) => e.eventDate.isAfter(now)).toList(growable: false);
    final past =
        events.where((e) => !e.eventDate.isAfter(now)).toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcoming.isNotEmpty) ...[
            const Text(
              'Upcoming Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...upcoming.map(
              (e) => _buildEventCard(
                context,
                e,
                isUpcoming: true,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (past.isNotEmpty) ...[
            const Text(
              'Past Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...past.map(
              (e) => _buildEventCard(
                context,
                e,
                isUpcoming: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventModel event, {
    required bool isUpcoming,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => section_owner.EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpcoming
                ? const Color(0xFF2563EB).withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xFF2563EB).withOpacity(0.15)
                    : const Color(0xFFFFAA4A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    event.eventDate.day.toString(),
                    style: TextStyle(
                      color: isUpcoming
                          ? const Color(0xFF4A9EFF)
                          : const Color(0xFFFFAA4A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _monthAbbr(event.eventDate.month),
                    style: TextStyle(
                      color: isUpcoming
                          ? const Color(0xFF4A9EFF).withOpacity(0.7)
                          : const Color(0xFFFFAA4A).withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (event.location != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withOpacity(0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.location!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _monthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}


