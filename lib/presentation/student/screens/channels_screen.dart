import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/providers/student_provider.dart';
import '../../../domain/providers/auth_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Basic setup for Explore/Channels tab
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF112240),
        elevation: 0,
        title: const Text('Channels', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF112240),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search channels',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('DEFAULT CHANNELS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildDefaultChannels(),

            const SizedBox(height: 32),
            
            const Text('JOINED CHANNELS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildJoinedChannels(),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SUGGESTED FOR YOU', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text('See all', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Suggested channels list (Coming Soon)', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultChannels() {
    final globalChannelsAsync = ref.watch(studentGlobalChannelsProvider);
    return globalChannelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) return const Text('No default channels', style: TextStyle(color: Colors.white));
        final filtered = channels.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();
        return Column(
          children: filtered.map((c) => ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.school, color: Colors.white)),
            title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Default Global Channel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Text('Error loading channels', style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildJoinedChannels() {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || user.joinedChannels.isEmpty) {
          return const Text('No joined channels yet', style: TextStyle(color: Colors.white));
        }

        final joinedChannelsAsync = ref.watch(studentJoinedChannelsProvider(user.joinedChannels));
        
        return joinedChannelsAsync.when(
          data: (channels) {
            if (channels.isEmpty) return const Text('No joined channels yet', style: TextStyle(color: Colors.white));
            final filtered = channels.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();
            if (filtered.isEmpty) return const SizedBox.shrink();

            return Column(
              children: filtered.map((c) => ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.radio, color: Colors.white)),
                title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${c.memberCount} members', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                onTap: () => context.push('/student/channel/${c.id}'),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Text('Error loading joined channels', style: TextStyle(color: Colors.red)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Text('Error loading user profile', style: TextStyle(color: Colors.red)),
    );
  }
}
