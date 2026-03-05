import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/providers/student_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/channel_provider.dart';       // ← for global/section providers if you have them
import '../../../data/models/channel_model.dart';              // ← THIS WAS MISSING → fixes all ChannelModel errors

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Channels',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF112240),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search channels...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionLabel(icon: Icons.lock_outline, label: 'Default Channels'),
                  _DefaultChannels(searchQuery: _searchQuery),

                  _SectionLabel(icon: Icons.radio, label: 'Joined Channels'),
                  _JoinedChannels(searchQuery: _searchQuery),

                  _SectionLabel(icon: Icons.explore_outlined, label: 'Discover Channels'),
                  _DiscoverChannelsGrid(searchQuery: _searchQuery),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small widgets ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultChannels extends ConsumerWidget {
  final String searchQuery;
  const _DefaultChannels({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(studentGlobalChannelsProvider);

    return channelsAsync.when(
      loading: () => const _LoadingTile(),
      error: (_, __) => const SizedBox.shrink(),
      data: (channels) {
        final filtered = channels.where((c) => c.name.toLowerCase().contains(searchQuery)).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        return Column(
          children: filtered.map((c) => _ChannelRow(
            id: c.id,
            name: c.name,
            subtitle: 'Official campus channel',
            isLocked: true,
            isLive: false,
          )).toList(),
        );
      },
    );
  }
}

class _JoinedChannels extends ConsumerWidget {
  final String searchQuery;
  const _JoinedChannels({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null || user.joinedChannels.isEmpty) {
          return const _EmptyMessage('No joined channels yet');
        }

        final joinedAsync = ref.watch(studentJoinedChannelsProvider(user.joinedChannels));

        return joinedAsync.when(
          loading: () => const _LoadingTile(),
          error: (_, __) => const SizedBox.shrink(),
          data: (channels) {
            final filtered = channels.where((c) => c.name.toLowerCase().contains(searchQuery)).toList();
            if (filtered.isEmpty) return const SizedBox.shrink();

            return Column(
              children: filtered.map((c) => _ChannelRow(
                id: c.id,
                name: c.name,
                subtitle: '${c.memberCount} members • ${c.sectionName.isNotEmpty ? c.sectionName : 'Global'}',
                isLocked: false,
                isLive: false,
              )).toList(),
            );
          },
        );
      },
    );
  }
}

// ── Discover Channels (Grid) ────────────────────────────────────────────────

class _DiscoverChannelsGrid extends ConsumerWidget {
  final String searchQuery;
  const _DiscoverChannelsGrid({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final globalAsync = ref.watch(studentGlobalChannelsProvider);

    return currentUserAsync.when(
      data: (user) {
        final joinedIds = user?.joinedChannels ?? [];

        return globalAsync.when(
          loading: () => const _LoadingTile(),
          error: (_, __) => const _EmptyMessage('Failed to load channels'),
          data: (globalChannels) {
            // You can add more providers here (e.g. section channels) and combine lists
            final allAvailable = globalChannels; // ← extend with section channels if needed

            final filtered = allAvailable.where((c) {
              return !joinedIds.contains(c.id) &&
                     c.name.toLowerCase().contains(searchQuery);
            }).toList();

            if (filtered.isEmpty) {
              return const _EmptyMessage('No new channels match your search');
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final channel = filtered[index];
                final isJoined = joinedIds.contains(channel.id);

                return _SquareChannelCard(
                  channel: channel,
                  isJoined: isJoined,
                  onJoin: () async {
                    try {
                      await ref.read(studentFirestoreProvider).joinChannel(channel.id);
                      ref.invalidate(currentUserProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to join: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
      loading: () => const _LoadingTile(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Square Card ─────────────────────────────────────────────────────────────

class _SquareChannelCard extends StatelessWidget {
  final ChannelModel channel;
  final bool isJoined;
  final VoidCallback onJoin;

  const _SquareChannelCard({
    required this.channel,
    required this.isJoined,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/student/channel/${channel.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF1E3A5F),
              child: const Icon(
                Icons.radio_rounded,
                color: Colors.blueAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              channel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${channel.memberCount} members',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isJoined
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Joined',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D3C78),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Join',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small widgets ──────────────────────────────────────────────────

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;
  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Text(
        message,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final String id;
  final String name;
  final String subtitle;
  final bool isLocked;
  final bool isLive;

  const _ChannelRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isLocked,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/student/channel/$id'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1E3A5F),
                  child: Icon(
                    isLocked ? Icons.school : Icons.radio,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A1628),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white54, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }
}

