import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/firebase/admin/admin_firestore_service.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final ChannelModel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  final _adminEmailController = TextEditingController();
  final _apiPasswordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _adminEmailController.text = widget.channel.ownerEmail ?? 'No email set';
    _apiPasswordController.text = '••••••••••••';
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _apiPasswordController.dispose();
    super.dispose();
  }

  void _regeneratePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password regenerated successfully.'), backgroundColor: AppColors.success),
    );
    // Real implementation would update password in auth and DB.
  }

  void _copyPassword() {
    // We would ideally copy the actual API password here if it was available in plain text.
    Clipboard.setData(const ClipboardData(text: 'dummy_password'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied!')),
    );
  }

  void _showChangeOwnerSheet() {
      // Stub for changing owner
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          child: const Text('Change Owner (Placeholder)', style: TextStyle(color: AppColors.white)),
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Channel Detail', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card (Channel Info)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentBlue.withOpacity(0.3), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.hexagon_outlined, color: AppColors.accentBlue, size: 40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(widget.channel.name, style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(widget.channel.sectionName.toUpperCase(), style: const TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('• 1.2k members', style: TextStyle(color: AppColors.grey, fontSize: 14)), // Hardcoded for mockup
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard('248', 'BROADCASTS')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('1,240', 'MEMBERS')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('12', 'POLLS')),
              ],
            ),

            const SizedBox(height: 24),

            // Channel Owner Section
            const Text('CHANNEL OWNER', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentBlue,
                  child: Text((widget.channel.ownerName?.isNotEmpty == true ? widget.channel.ownerName![0] : '?').toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.channel.ownerName ?? 'No Owner', style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(widget.channel.ownerEmail ?? 'No email', style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showChangeOwnerSheet,
                  child: const Text('Change Owner', style: TextStyle(color: AppColors.white, fontSize: 12)),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Credentials Section
            const Text('CREDENTIALS', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Email', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adminEmailController,
                    readOnly: true,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppColors.primaryBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('API Password', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiPasswordController,
                    readOnly: true,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppColors.primaryBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.grey, size: 20),
                        onPressed: _copyPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _regeneratePassword,
                        child: const Text('Regenerate Password', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          // Save credentials
                        },
                        child: const Text('Save Credentials', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Remove Channel Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent, // or a very dark red
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
              ),
              child: TextButton.icon(
                onPressed: () {
                  // Show confirmation dialog before removing
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Remove Channel', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Removing this channel will delete all history, members, and credentials permanently. This action cannot be undone.',
              style: TextStyle(color: AppColors.grey, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.accentBlue, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}
