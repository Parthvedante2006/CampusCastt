import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../domain/providers/auth_provider.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: currentUser.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.accentBlue)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style:
                    const TextStyle(color: AppColors.error))),
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('No user data',
                    style: TextStyle(color: AppColors.grey)));
          }

          // ✅ FIXED: collegeTrust is String? so use ?? ''
          final collegeTrust =
              user.collegeTrust ?? 'VIT Pune Trust';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Avatar ──────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accentBlue
                                  .withOpacity(0.5),
                              width: 3),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user.name,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      // ✅ FIXED: use local variable
                      Text(collegeTrust,
                          style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Text('Super Admin',
                            style: TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Info Card ────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white10, width: 1),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      const Divider(
                          color: Colors.white10, height: 24),
                      const _InfoRow(
                        icon: Icons.shield_outlined,
                        label: 'Role',
                        value: 'Super Admin',
                      ),
                      const Divider(
                          color: Colors.white10, height: 24),
                      // ✅ FIXED: use local variable
                      _InfoRow(
                        icon: Icons.account_balance_outlined,
                        label: 'College Trust',
                        value: collegeTrust,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Settings List ────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white10, width: 1),
                  ),
                  child: Column(
                    children: [
                      _SettingsItem(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Manage Admins',
                        onTap: () {},
                      ),
                      const Divider(
                          color: Colors.white10,
                          height: 1,
                          indent: 56),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Settings',
                        onTap: () {},
                      ),
                      const Divider(
                          color: Colors.white10,
                          height: 1,
                          indent: 56),
                      _SettingsItem(
                        icon: Icons.settings_outlined,
                        label: 'App Settings',
                        onTap: () {},
                      ),
                      const Divider(
                          color: Colors.white10,
                          height: 1,
                          indent: 56),
                      _SettingsItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Logout ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red.withOpacity(0.15),
                      side: const BorderSide(
                          color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await ref
                          .read(authRepositoryProvider)
                          .logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.red),
                    label: const Text('Logout',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.grey, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.grey, size: 20),
    );
  }
}