import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/admin_provider.dart';
import 'sections_screen.dart';
import 'channels_screen.dart';
import 'admin_profile_screen.dart';
import 'section_detail_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _AdminHomeTab(),
    const SectionsScreen(),
    const ChannelsScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBg,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Sections'),
          BottomNavigationBarItem(icon: Icon(Icons.podcasts), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────
class _AdminHomeTab extends ConsumerWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsStreamProvider);
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('CampusCast Admin', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Sections',
                    value: sectionsAsync.when(data: (s) => '${s.length}', loading: () => '...', error: (_, __) => '0'),
                    icon: Icons.account_balance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Channels',
                    value: channelsAsync.when(data: (c) => '${c.length}', loading: () => '...', error: (_, __) => '0'),
                    icon: Icons.podcasts,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Sections
            const Text('RECENT SECTIONS', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            sectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              data: (sections) {
                if (sections.isEmpty) return const Text('No sections yet.', style: TextStyle(color: AppColors.grey));
                final recent = sections.take(3).toList();
                return Column(
                  children: recent.map((s) => GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SectionDetailScreen(
                          sectionId: s.id,
                          sectionName: s.name,
                          collegeTrust: s.collegeTrust,
                          ownerName: s.ownerName,
                          ownerEmail: s.ownerEmail,
                        ),
                      ));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance, color: AppColors.accentBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s.name, style: const TextStyle(color: AppColors.white, fontSize: 14))),
                          Text('${s.studentCount} students', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent Channels
            const Text('RECENT CHANNELS', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              data: (channels) {
                if (channels.isEmpty) return const Text('No channels yet.', style: TextStyle(color: AppColors.grey));
                final recent = channels.take(3).toList();
                return Column(
                  children: recent.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.podcasts, color: AppColors.accentBlue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(c.name, style: const TextStyle(color: AppColors.white, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                          child: Text(c.sectionName, style: const TextStyle(color: AppColors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
