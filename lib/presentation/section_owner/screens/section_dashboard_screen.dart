import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/core/constants/app_colors.dart';
import 'package:campuscast/presentation/section_owner/screens/dashboard_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/announce_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/events_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/profile_screen.dart';

class SectionOwnerDashboardScreen extends ConsumerStatefulWidget {
  const SectionOwnerDashboardScreen({super.key});

  @override
  ConsumerState<SectionOwnerDashboardScreen> createState() =>
      _SectionOwnerDashboardScreenState();
}

class _SectionOwnerDashboardScreenState
    extends ConsumerState<SectionOwnerDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SectionOwnerHomeTab(),
    SectionOwnerAnnounceTab(),
    SectionOwnerEventsTab(),
    SectionOwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.campaign_rounded, 'Announce', 1),
                _buildNavItem(Icons.event_rounded, 'Events', 2),
                _buildNavItem(Icons.person_rounded, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.accentBlue.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4A9EFF) : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4A9EFF) : AppColors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
