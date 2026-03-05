import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import 'sections_screen.dart';
import 'channels_screen.dart';
import 'admin_profile_screen.dart';
import 'section_detail_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _AdminHomeTab(),
      const SectionsScreen(),
      const ChannelsScreen(),
      const AdminProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBg,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Sections'),
          BottomNavigationBarItem(
              icon: Icon(Icons.podcasts_rounded),
              label: 'Channels'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends ConsumerWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsStreamProvider);
    final channelsAsync = ref.watch(channelsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    final adminName = currentUser.when(
      data: (u) => u?.name ?? 'Admin',
      loading: () => 'Admin',
      error: (_, __) => 'Admin',
    );

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 14)),
                      Text(adminName,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppColors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Stats Grid ───────────────────────────────
              sectionsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentBlue)),
                error: (_, __) => const SizedBox(),
                data: (sections) => channelsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (channels) {
                    final totalStudents = sections.fold<int>(
                        0, (sum, s) => sum + s.studentCount);
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                            title: 'Sections',
                            value: '${sections.length}',
                            icon: Icons.account_balance_rounded,
                            color: const Color(0xFF4C9EFF)),
                        _StatCard(
                            title: 'Channels',
                            value: '${channels.length}',
                            icon: Icons.podcasts_rounded,
                            color: const Color(0xFF9B59B6)),
                        _StatCard(
                            title: 'Students',
                            value: '$totalStudents',
                            icon: Icons.people_rounded,
                            color: const Color(0xFF2ECC71)),
                        _StatCard(
                            title: 'Channel Owners',
                            value: '${channels.length}',
                            icon: Icons.manage_accounts_rounded,
                            color: const Color(0xFFE67E22)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────
              const Text('QUICK ACTIONS',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                      label: 'Add Section',
                      icon: Icons.add_business_rounded,
                      onTap: () {}),
                  const SizedBox(width: 10),
                  _QuickAction(
                      label: 'Add Channel',
                      icon: Icons.add_circle_rounded,
                      onTap: () {}),
                  const SizedBox(width: 10),
                  _QuickAction(
                      label: 'View Students',
                      icon: Icons.people_alt_rounded,
                      onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Sections ──────────────────────────
              const Text('RECENT SECTIONS',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              sectionsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentBlue)),
                error: (e, _) => Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.error)),
                data: (sections) {
                  if (sections.isEmpty) {
                    return const Text('No sections yet.',
                        style: TextStyle(color: AppColors.grey));
                  }
                  return Column(
                    children: sections.take(3).map((s) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            // ✅ FIXED: uses separate params matching constructor
                            builder: (_) => SectionDetailScreen(
                              sectionId: s.id,
                              sectionName: s.name,
                              collegeTrust: s.collegeTrust,
                              ownerName: s.ownerName,
                              ownerEmail: s.ownerEmail,
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white10, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue
                                      .withOpacity(0.3),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.account_balance_rounded,
                                    color: AppColors.accentBlue,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text(
                                      s.ownerName != null
                                          ? 'Owner: ${s.ownerName}'
                                          : 'No owner assigned',
                                      style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${s.studentCount} students',
                                  style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.grey, size: 18),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Recent Channels ──────────────────────────
              const Text('RECENT CHANNELS',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              channelsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentBlue)),
                error: (e, _) => Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.error)),
                data: (channels) {
                  if (channels.isEmpty) {
                    return const Text('No channels yet.',
                        style: TextStyle(color: AppColors.grey));
                  }
                  return Column(
                    children: channels.take(3).map((c) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white10, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8CD8B8)
                                    .withOpacity(0.3),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.podcasts_rounded,
                                  color: Color(0xFF8CD8B8),
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(
                                    c.ownerName != null &&
                                            c.ownerName!.isNotEmpty
                                        ? 'Owner: ${c.ownerName}'
                                        : 'No owner',
                                    style: const TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue
                                    .withOpacity(0.3),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(c.sectionName,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 10)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentBlue, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}