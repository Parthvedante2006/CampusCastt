import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/core/constants/app_colors.dart';
import 'package:campuscast/domain/providers/section_provider.dart';
import 'package:campuscast/data/models/event_model.dart';
import 'package:campuscast/presentation/section_owner/screens/post_event_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/event_detail_screen.dart';

class SectionOwnerEventsTab extends ConsumerWidget {
  const SectionOwnerEventsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(sectionEventsProvider);

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
                  builder: (_) => const PostEventScreen(),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF4A9EFF), size: 22),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading events',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined,
                      color: Colors.white.withOpacity(0.2), size: 60),
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

          // Separate upcoming and past events
          final now = DateTime.now();
          final upcoming =
              events.where((e) => e.eventDate.isAfter(now)).toList();
          final past =
              events.where((e) => !e.eventDate.isAfter(now)).toList();

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
                  ...upcoming.map((e) => _buildEventCard(context, e, isUpcoming: true)),
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
                  ...past.map((e) => _buildEventCard(context, e, isUpcoming: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, {required bool isUpcoming}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event),
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
            // Date badge
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
                        Icon(Icons.location_on_outlined,
                            color: Colors.white.withOpacity(0.4), size: 14),
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
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}
