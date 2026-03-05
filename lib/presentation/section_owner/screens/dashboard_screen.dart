import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuscast/core/constants/app_colors.dart';
import 'package:campuscast/domain/providers/auth_provider.dart';
import 'package:campuscast/domain/providers/section_provider.dart';
import 'package:campuscast/data/models/announcement_model.dart';

class SectionOwnerHomeTab extends ConsumerWidget {
  const SectionOwnerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final sectionAsync = ref.watch(ownedSectionProvider);
    final studentCountAsync = ref.watch(studentCountProvider);
    final announcementsAsync = ref.watch(sectionAnnouncementsProvider);
    final eventsAsync = ref.watch(sectionEventsProvider);
    final liveAsync = ref.watch(liveAnnouncementProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────────────────
              _buildTopBar(sectionAsync),
              const SizedBox(height: 24),

              // ── Welcome card ─────────────────────────────────
              _buildWelcomeCard(userAsync, sectionAsync),
              const SizedBox(height: 24),

              // ── Stats row ────────────────────────────────────
              _buildStatsRow(studentCountAsync, announcementsAsync, eventsAsync),
              const SizedBox(height: 24),

              // ── Live announcement card ───────────────────────
              _buildLiveCard(liveAsync),
              const SizedBox(height: 28),

              // ── Recent Activity ──────────────────────────────
              _buildRecentActivitySection(activityAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AsyncValue sectionAsync) {
    final sectionName = sectionAsync.value?.name ?? 'Campus';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.graphic_eq_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            sectionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 22),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(AsyncValue userAsync, AsyncValue sectionAsync) {
    final userName = userAsync.value?.name ?? 'Loading...';
    final sectionName = sectionAsync.value?.name ?? '';

    return Row(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Section Owner • $sectionName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    AsyncValue<int> studentCount,
    AsyncValue<List<AnnouncementModel>> announcements,
    AsyncValue events,
  ) {
    final students = studentCount.value ?? 0;
    final updates = announcements.value?.length ?? 0;
    final eventCount = (events.value as List?)?.length ?? 0;

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.people_outline_rounded,
          label: 'STUDENTS',
          value: _formatCount(students),
          color: const Color(0xFF4A9EFF),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.campaign_outlined,
          label: 'UPDATES',
          value: _formatCount(updates),
          color: const Color(0xFF4AE68A),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.event_outlined,
          label: 'EVENTS',
          value: _formatCount(eventCount),
          color: const Color(0xFFFFAA4A),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCard(AsyncValue<AnnouncementModel?> liveAsync) {
    final liveAnnouncement = liveAsync.value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF112240),
            const Color(0xFF1A3A6B).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Stack(
        children: [
          // Waveform background decoration
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _WaveformPainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live badge
                if (liveAnnouncement != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (liveAnnouncement == null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NO LIVE BROADCAST',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const SizedBox(height: 60),
                Text(
                  liveAnnouncement?.title ?? 'No Active Broadcast',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (liveAnnouncement != null)
                  Row(
                    children: [
                      Icon(Icons.headphones_rounded,
                          color: Colors.white.withOpacity(0.6), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${liveAnnouncement.formattedListeners} students listening',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          liveAnnouncement != null
                              ? 'Join Live'
                              : 'Start Broadcast',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    if (liveAnnouncement != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.stop_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
      AsyncValue<List<Map<String, dynamic>>> activityAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        activityAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error loading activity',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          data: (activities) {
            if (activities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded,
                          color: Colors.white.withOpacity(0.3), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: activities.map((activity) {
                return _buildActivityTile(activity);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final isAnnouncement = activity['type'] == 'announcement';
    final title = activity['title'] as String;
    final subtitle = activity['subtitle'] as String;
    final createdAt = activity['created_at'] as Timestamp?;
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAnnouncement
                  ? const Color(0xFF2563EB).withOpacity(0.15)
                  : const Color(0xFFFFAA4A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAnnouncement
                  ? Icons.campaign_rounded
                  : Icons.event_rounded,
              color: isAnnouncement
                  ? const Color(0xFF4A9EFF)
                  : const Color(0xFFFFAA4A),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeAgo • $subtitle',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3), size: 20),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${diff.inDays ~/ 7} weeks ago';
  }
}

// ── Waveform background painter ──────────────────────────────

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * 0.3 + (i * 20.0);
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset +
            (15 * (i + 1)) *
                _sine(x / (60 + i * 20));
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  double _sine(double x) {
    // Simple sine approximation
    x = x % (2 * 3.14159);
    return (x < 3.14159)
        ? (4 * x * (3.14159 - x)) / (3.14159 * 3.14159)
        : -(4 * (x - 3.14159) * (2 * 3.14159 - x)) / (3.14159 * 3.14159);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
