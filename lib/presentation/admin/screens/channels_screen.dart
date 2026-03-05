import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/firebase/admin/admin_firestore_service.dart';
import '../../../domain/providers/admin_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {

  void _showCreateChannelSheet() {
    final channelNameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final ownerEmailController = TextEditingController();
    String generatedPassword = AdminFirestoreService.generatePassword();
    String? selectedSectionId;
    String? selectedSectionName;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final sectionsAsync = ref.watch(sectionsStreamProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Channel', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: channelNameController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Channel Name (e.g. Coding Club)',
                        hintStyle: const TextStyle(color: AppColors.grey),
                        filled: true, fillColor: AppColors.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Section Dropdown
                    sectionsAsync.when(
                      loading: () => const CircularProgressIndicator(color: AppColors.accentBlue),
                      error: (e, _) => Text('Error loading sections', style: TextStyle(color: AppColors.error)),
                      data: (sections) => DropdownButtonFormField<String>(
                        value: selectedSectionId,
                        dropdownColor: AppColors.cardBg,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Select Section',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          filled: true, fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedSectionId = val;
                            selectedSectionName = sections.firstWhere((s) => s.id == val).name;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('CHANNEL OWNER', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ownerNameController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Owner Name',
                        hintStyle: const TextStyle(color: AppColors.grey),
                        prefixIcon: const Icon(Icons.person, color: AppColors.grey),
                        filled: true, fillColor: AppColors.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ownerEmailController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Owner Email',
                        hintStyle: const TextStyle(color: AppColors.grey),
                        prefixIcon: const Icon(Icons.email, color: AppColors.grey),
                        filled: true, fillColor: AppColors.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    // Password
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: AppColors.grey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(generatedPassword, style: const TextStyle(color: AppColors.white, fontFamily: 'monospace'))),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.grey, size: 20),
                            onPressed: () => setSheetState(() => generatedPassword = AdminFirestoreService.generatePassword()),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.grey, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedPassword));
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Password copied!'), duration: Duration(seconds: 1)),
                              );
                            },
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: isSaving ? null : () async {
                          if (channelNameController.text.trim().isEmpty ||
                              selectedSectionId == null ||
                              ownerNameController.text.trim().isEmpty ||
                              ownerEmailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields.'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          setSheetState(() => isSaving = true);
                          try {
                            await ref.read(adminRepositoryProvider).createChannelWithOwner(
                              channelName: channelNameController.text.trim(),
                              sectionId: selectedSectionId!,
                              sectionName: selectedSectionName ?? '',
                              ownerName: ownerNameController.text.trim(),
                              ownerEmail: ownerEmailController.text.trim(),
                              ownerPassword: generatedPassword,
                              collegeTrust: '',
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          } finally {
                            setSheetState(() => isSaving = false);
                          }
                        },
                        child: isSaving
                            ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                            : const Text('Create Channel & Owner', style: TextStyle(color: AppColors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Channels', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.white),
            onPressed: _showCreateChannelSheet,
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No channels yet. Tap + to create one.', style: TextStyle(color: AppColors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.podcasts, color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(channel.name, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                                child: Text(channel.sectionName, style: const TextStyle(color: AppColors.white, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                channel.ownerName ?? 'No owner',
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
