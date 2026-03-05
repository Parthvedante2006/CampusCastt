import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/firebase/admin/admin_firestore_service.dart';
import '../../../domain/providers/admin_provider.dart';
import 'channel_detail_screen.dart';

class SectionDetailScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String sectionName;
  final String collegeTrust;
  final String? ownerName;
  final String? ownerEmail;

  const SectionDetailScreen({
    super.key,
    required this.sectionId,
    required this.sectionName,
    required this.collegeTrust,
    this.ownerName,
    this.ownerEmail,
  });

  @override
  ConsumerState<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen> {
  bool _isUploadingCsv = false;

  void _showSetOwnerSheet() {
    final nameController = TextEditingController(text: widget.ownerName ?? '');
    final emailController = TextEditingController(text: widget.ownerEmail ?? '');
    String generatedPassword = AdminFirestoreService.generatePassword();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set Section Owner', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Owner Name',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  filled: true, fillColor: AppColors.primaryBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Owner Email',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  filled: true, fillColor: AppColors.primaryBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;
                    setSheetState(() => isSaving = true);
                    try {
                      await ref.read(adminRepositoryProvider).setSectionOwner(
                        sectionId: widget.sectionId,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: generatedPassword,
                        collegeTrust: widget.collegeTrust,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section owner set! Please copy the password.')));
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      setSheetState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                      : const Text('Save Owner', style: TextStyle(color: AppColors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;
      setState(() => _isUploadingCsv = true);

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);

      final startIndex = (rows.isNotEmpty && rows[0].any((cell) => cell.toString().toLowerCase() == 'name')) ? 1 : 0;
      final students = <Map<String, String>>[];
      for (int i = startIndex; i < rows.length; i++) {
        if (rows[i].length >= 2) {
          students.add({
            'name': rows[i][0].toString().trim(),
            'email': rows[i][1].toString().trim(),
            'college': rows[i].length >= 3 ? rows[i][2].toString().trim() : widget.sectionName,
          });
        }
      }

      final uploadResult = await ref.read(adminRepositoryProvider).uploadStudentWhitelist(
        sectionId: widget.sectionId,
        students: students,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${uploadResult['added']} new, ${uploadResult['existed']} existed students'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isUploadingCsv = false);
    }
  }

  void _showCreateChannelSheet() {
    final nameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final ownerEmailController = TextEditingController();
    String generatedPassword = AdminFirestoreService.generatePassword();
    bool isSaving = false;
    bool isDefault = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                  controller: nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Channel Name',
                    filled: true, fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isDefault,
                      onChanged: (val) => setSheetState(() => isDefault = val ?? false),
                      activeColor: AppColors.accentBlue,
                    ),
                    const Expanded(
                      child: Text(
                        'Global Channel (Default to everyone enrolled)',
                        style: TextStyle(color: AppColors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('CHANNEL OWNER', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: ownerNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Owner Name',
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
                    filled: true, fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: isSaving ? null : () async {
                      if (nameController.text.isEmpty || ownerNameController.text.isEmpty) return;
                      setSheetState(() => isSaving = true);
                      try {
                        await ref.read(adminRepositoryProvider).createChannelWithOwner(
                          channelName: nameController.text.trim(),
                          sectionId: widget.sectionId,
                          sectionName: widget.sectionName,
                          ownerName: ownerNameController.text.trim(),
                          ownerEmail: ownerEmailController.text.trim(),
                          ownerPassword: generatedPassword,
                          collegeTrust: widget.collegeTrust,
                          isDefault: isDefault,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        setSheetState(() => isSaving = false);
                      }
                    },
                    child: isSaving ? const CircularProgressIndicator(color: AppColors.white) : const Text('Create Channel', style: TextStyle(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(widget.sectionName, style: const TextStyle(color: AppColors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              // Action if needed, maybe edit section details
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Section Owner Card
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
                  const Text('SECTION OWNER', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  if (widget.ownerName == null || widget.ownerName!.isEmpty)
                    Center(
                      child: TextButton(
                        onPressed: _showSetOwnerSheet,
                        child: const Text('Assign Section Owner', style: TextStyle(color: AppColors.accentBlue)),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accentBlue,
                          child: Text(widget.ownerName![0].toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.ownerName!, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(widget.ownerEmail ?? '', style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _showSetOwnerSheet,
                            child: const Text('Edit Owner', style: TextStyle(color: AppColors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBg, // Actually mock shows a dark button with icon
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                               // Open credentials sheet or notify password sent
                            },
                            icon: const Icon(Icons.copy, color: AppColors.white, size: 18),
                            label: const Text('Credentials', style: TextStyle(color: AppColors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue.withOpacity(0.2),
                      foregroundColor: AppColors.accentBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isUploadingCsv ? null : _uploadCsv,
                    icon: _isUploadingCsv 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_upload, size: 20),
                    label: Text(_isUploadingCsv ? 'Uploading...' : 'Upload Students CSV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Channels List
            channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
              error: (e, _) => Center(child: Text('Error loading channels: $e', style: const TextStyle(color: AppColors.error))),
              data: (allChannels) {
                final sectionChannels = allChannels.where((c) => c.sectionId == widget.sectionId).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Channels in this Section', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
                          child: Text('${sectionChannels.length} Total', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sectionChannels.isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text('No channels yet.', style: TextStyle(color: AppColors.grey))))
                    else
                      ...sectionChannels.map((channel) => InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ChannelDetailScreen(channel: channel),
                          ));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: const Color(0xFF8CD8B8), borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Icon(Icons.podcasts, color: Colors.black54)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(channel.name, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    const Text('Technical workshops and...', style: TextStyle(color: AppColors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.edit, color: AppColors.grey, size: 20), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.delete, color: AppColors.grey, size: 20), onPressed: () {}),
                            ],
                          ),
                        ),
                      )).toList(),
                  ],
                );
              },
            ),
            const SizedBox(height: 100), // spacing for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppColors.primaryBg,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showCreateChannelSheet,
            icon: const Icon(Icons.add_circle, color: AppColors.white),
            label: const Text('Add New Channel', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
