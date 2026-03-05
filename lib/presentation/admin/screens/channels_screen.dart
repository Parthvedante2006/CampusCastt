import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/admin_provider.dart';
import 'channel_detail_screen.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // ── Toggle Global Channel in Firestore ──────────────────
  Future<void> _toggleGlobal(String channelId, bool current) async {
    await FirebaseFirestore.instance
        .collection('channels')
        .doc(channelId)
        .update({'is_default': !current});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!current
              ? '✅ Channel set as Global'
              : '❌ Channel removed from Global'),
          backgroundColor:
              !current ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  // ── Delete Channel ───────────────────────────────────────
  void _confirmDelete(String channelId, String channelName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Channel',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "$channelName"?',
          style: const TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('channels')
                  .doc(channelId)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Channel deleted'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);
    final sectionsAsync = ref.watch(sectionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        title: const Text('Channels',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Go to a Section to add a channel')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Search channels...',
                hintStyle:
                    const TextStyle(color: AppColors.grey),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.grey),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // ── Filter Chips ────────────────────────────────
          sectionsAsync.when(
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox(height: 44),
            data: (sections) {
              final filters = [
                'All',
                'Global',
                ...sections.map((s) => s.name)
              ];
              return SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: filters.length,
                  itemBuilder: (ctx, i) {
                    final f = filters[i];
                    final isSelected = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentBlue
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentBlue
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (f == 'Global') ...[
                              const Icon(Icons.public,
                                  size: 12,
                                  color: Colors.green),
                              const SizedBox(width: 4),
                            ],
                            Text(f,
                                style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.grey,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Channels List ───────────────────────────────
          Expanded(
            child: channelsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentBlue)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(
                          color: AppColors.error))),
              data: (channels) {
                // Apply filters
                final filtered = channels.where((c) {
                  final matchSearch = _searchQuery.isEmpty ||
                      c.name
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      c.sectionName
                          .toLowerCase()
                          .contains(_searchQuery);
                  final matchFilter = _selectedFilter == 'All' ||
                      (_selectedFilter == 'Global' &&
                          c.isDefault) ||
                      c.sectionName == _selectedFilter;
                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.podcasts_rounded,
                            color: AppColors.grey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'Global'
                              ? 'No global channels yet'
                              : 'No channels found',
                          style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final channel = filtered[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChannelDetailScreen(
                                  channel: channel))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: channel.isDefault
                                ? Colors.green.withOpacity(0.3)
                                : Colors.white10,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // ── Channel Avatar ────────────
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: channel.isDefault
                                    ? Colors.green.withOpacity(0.15)
                                    : const Color(0xFF8CD8B8)
                                        .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  channel.name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: channel.isDefault
                                          ? Colors.green
                                          : const Color(0xFF8CD8B8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // ── Channel Info ──────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(channel.name,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  // Tags row
                                  Row(
                                    children: [
                                      // Section pill
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentBlue
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                        ),
                                        child: Text(
                                            channel.sectionName,
                                            style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 10)),
                                      ),
                                      if (channel.isDefault) ...[
                                        const SizedBox(width: 6),
                                        // Global pill
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.public,
                                                  size: 10,
                                                  color: Colors.green),
                                              SizedBox(width: 3),
                                              Text('Global',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.green,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    channel.ownerName != null &&
                                            channel
                                                .ownerName!.isNotEmpty
                                        ? 'Owner: ${channel.ownerName}'
                                        : 'No owner assigned',
                                    style: const TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // ── Actions ───────────────────
                            Column(
                              children: [
                                // Global toggle
                                GestureDetector(
                                  onTap: () => _toggleGlobal(
                                      channel.id, channel.isDefault),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: channel.isDefault
                                          ? Colors.green
                                              .withOpacity(0.15)
                                          : AppColors.primaryBg,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: channel.isDefault
                                            ? Colors.green
                                                .withOpacity(0.5)
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.public,
                                      size: 16,
                                      color: channel.isDefault
                                          ? Colors.green
                                          : AppColors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Delete
                                GestureDetector(
                                  onTap: () => _confirmDelete(
                                      channel.id, channel.name),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red
                                              .withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.delete,
                                        size: 16, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}