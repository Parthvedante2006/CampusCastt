import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
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
  ConsumerState<SectionDetailScreen> createState() =>
      _SectionDetailScreenState();
}

class _SectionDetailScreenState
    extends ConsumerState<SectionDetailScreen> {
  bool _isUploadingCsv = false;

  // ── Credentials popup ───────────────────────────────────
  void _showCredentialsDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('✅ Owner Saved',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Copy and save these credentials:',
                style:
                    TextStyle(color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            _credRow(Icons.email, email, ctx),
            const SizedBox(height: 10),
            _credRow(Icons.lock, password, ctx),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done',
                style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }

  Widget _credRow(IconData icon, String value, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'monospace',
                      fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.copy,
                color: AppColors.accentBlue, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied!')));
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Set Section Owner ───────────────────────────────────
  void _showSetOwnerSheet() async {
    // Fetch existing password from Firestore
    String existingPassword = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sections')
          .doc(widget.sectionId)
          .get();
      existingPassword = doc.data()?['owner_password'] ?? '';
    } catch (_) {}

    if (!mounted) return;

    final nameController =
        TextEditingController(text: widget.ownerName ?? '');
    final emailController =
        TextEditingController(text: widget.ownerEmail ?? '');
    // ✅ Pre-fill existing password — admin can edit it
    final passwordController =
        TextEditingController(text: existingPassword);
    bool obscurePassword = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.ownerName == null ||
                          widget.ownerName!.isEmpty)
                      ? 'Assign Section Owner'
                      : 'Edit Section Owner',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Owner Name',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.person,
                        color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // Email
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Owner Email',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.email,
                        color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                // ✅ Manual editable password
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: AppColors.white),
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Set Password (min 6 characters)',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.lock,
                        color: AppColors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.grey,
                      ),
                      onPressed: () => setSheetState(() =>
                          obscurePassword = !obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameController.text
                                    .trim()
                                    .isEmpty ||
                                emailController.text
                                    .trim()
                                    .isEmpty ||
                                passwordController.text
                                    .trim()
                                    .isEmpty) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please fill all fields.')));
                              return;
                            }
                            if (passwordController.text.trim().length < 6) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Password must be at least 6 characters.')));
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            final savedEmail =
                                emailController.text.trim();
                            final savedPassword =
                                passwordController.text.trim();
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .setSectionOwner(
                                    sectionId: widget.sectionId,
                                    name: nameController.text.trim(),
                                    email: savedEmail,
                                    password: savedPassword,
                                    collegeTrust: widget.collegeTrust,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _showCredentialsDialog(
                                    savedEmail, savedPassword);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx)
                                    .showSnackBar(SnackBar(
                                        content:
                                            Text('Error: $e')));
                              }
                            } finally {
                              setSheetState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2)
                        : const Text('Save Owner',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CSV Upload ──────────────────────────────────────────
  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;
      setState(() => _isUploadingCsv = true);

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);

      final startIndex = (rows.isNotEmpty &&
              rows[0].any((cell) =>
                  cell.toString().toLowerCase() == 'name'))
          ? 1
          : 0;

      final students = <Map<String, String>>[];
      for (int i = startIndex; i < rows.length; i++) {
        if (rows[i].length >= 2) {
          final email = rows[i][1].toString().trim();
          if (email.isEmpty || !email.contains('@')) continue;
          students.add({
            'name': rows[i][0].toString().trim(),
            'email': email,
            'college': rows[i].length >= 3
                ? rows[i][2].toString().trim()
                : widget.sectionName,
          });
        }
      }

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No valid records found in CSV.'),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }

      final uploadResult = await ref
          .read(adminRepositoryProvider)
          .uploadStudentWhitelist(
            sectionId: widget.sectionId,
            students: students,
          );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('✅ CSV Upload Complete',
              style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.person_add,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Text('${uploadResult['added']} new students added',
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 15)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.skip_next,
                    color: AppColors.grey, size: 20),
                const SizedBox(width: 10),
                Text('${uploadResult['existed']} already existed',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 15)),
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.accentBlue)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isUploadingCsv = false);
    }
  }

  // ── Create Channel ──────────────────────────────────────
  void _showCreateChannelSheet() {
    final nameController = TextEditingController();
    final ownerNameController = TextEditingController();
    final ownerEmailController = TextEditingController();
    final ownerPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool isSaving = false;
    bool isDefault = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Channel',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Channel Name
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Channel Name',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.podcasts,
                        color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isDefault,
                      onChanged: (val) => setSheetState(
                          () => isDefault = val ?? false),
                      activeColor: AppColors.accentBlue,
                    ),
                    const Expanded(
                      child: Text(
                        'Global Channel (Default for all students)',
                        style: TextStyle(
                            color: AppColors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('CHANNEL OWNER',
                    style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                // Owner Name
                TextField(
                  controller: ownerNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Owner Name',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.person,
                        color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // Owner Email
                TextField(
                  controller: ownerEmailController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Owner Email',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.email,
                        color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                // ✅ Manual password field
                TextField(
                  controller: ownerPasswordController,
                  style: const TextStyle(color: AppColors.white),
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Set Password (min 6 characters)',
                    hintStyle:
                        const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.lock,
                        color: AppColors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.grey,
                      ),
                      onPressed: () => setSheetState(() =>
                          obscurePassword = !obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameController.text.isEmpty ||
                                ownerNameController.text.isEmpty ||
                                ownerEmailController.text.isEmpty ||
                                ownerPasswordController
                                    .text.isEmpty) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please fill all fields.')));
                              return;
                            }
                            if (ownerPasswordController.text.trim().length < 6) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Password must be at least 6 characters.')));
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            final savedEmail =
                                ownerEmailController.text.trim();
                            final savedPassword =
                                ownerPasswordController.text.trim();
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .createChannelWithOwner(
                                    channelName:
                                        nameController.text.trim(),
                                    sectionId: widget.sectionId,
                                    sectionName: widget.sectionName,
                                    ownerName: ownerNameController
                                        .text
                                        .trim(),
                                    ownerEmail: savedEmail,
                                    ownerPassword: savedPassword,
                                    collegeTrust: widget.collegeTrust,
                                    isDefault: isDefault,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _showCredentialsDialog(
                                    savedEmail, savedPassword);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx)
                                    .showSnackBar(SnackBar(
                                        content:
                                            Text('Error: $e')));
                              }
                            } finally {
                              setSheetState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(
                            color: AppColors.white)
                        : const Text('Create Channel',
                            style:
                                TextStyle(color: AppColors.white)),
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
        title: Text(widget.sectionName,
            style: const TextStyle(
                color: AppColors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Section Owner Card ──────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white12, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SECTION OWNER',
                      style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 16),
                  if (widget.ownerName == null ||
                      widget.ownerName!.isEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: _showSetOwnerSheet,
                        icon: const Icon(Icons.person_add,
                            color: AppColors.accentBlue),
                        label: const Text('Assign Section Owner',
                            style: TextStyle(
                                color: AppColors.accentBlue)),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accentBlue,
                          child: Text(
                              widget.ownerName![0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(widget.ownerName!,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(widget.ownerEmail ?? '',
                                  style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                            ),
                            onPressed: _showSetOwnerSheet,
                            icon: const Icon(Icons.edit,
                                color: AppColors.white, size: 18),
                            label: const Text('Edit Owner',
                                style: TextStyle(
                                    color: AppColors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                            ),
                            // ✅ Fetch latest from Firestore
                            onPressed: () async {
                              final doc = await FirebaseFirestore
                                  .instance
                                  .collection('sections')
                                  .doc(widget.sectionId)
                                  .get();
                              final data = doc.data();
                              if (data != null && mounted) {
                                _showCredentialsDialog(
                                  data['owner_email'] ?? '',
                                  data['owner_password'] ?? '',
                                );
                              }
                            },
                            icon: const Icon(Icons.copy,
                                color: AppColors.white, size: 18),
                            label: const Text('View Creds',
                                style: TextStyle(
                                    color: AppColors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── CSV Upload ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.accentBlue.withOpacity(0.2),
                  foregroundColor: AppColors.accentBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isUploadingCsv ? null : _uploadCsv,
                icon: _isUploadingCsv
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                    : const Icon(Icons.file_upload, size: 20),
                label: Text(_isUploadingCsv
                    ? 'Uploading...'
                    : 'Upload Students CSV'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Channels List ───────────────────────────
            channelsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentBlue)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(
                          color: AppColors.error))),
              data: (allChannels) {
                final sectionChannels = allChannels
                    .where((c) => c.sectionId == widget.sectionId)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Channels in this Section',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius:
                                  BorderRadius.circular(12)),
                          child: Text(
                              '${sectionChannels.length} Total',
                              style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sectionChannels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(
                            child: Text('No channels yet.',
                                style: TextStyle(
                                    color: AppColors.grey))),
                      )
                    else
                      ...sectionChannels
                          .map((channel) => InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChannelDetailScreen(
                                            channel: channel),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 12),
                                  padding:
                                      const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: channel.isDefault
                                          ? Colors.green
                                              .withOpacity(0.3)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                            color: const Color(
                                                0xFF8CD8B8),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(12)),
                                        child: Center(
                                          child: Text(
                                            channel.name[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 20,
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(channel.name,
                                                style: const TextStyle(
                                                    color: AppColors
                                                        .white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600)),
                                            const SizedBox(
                                                height: 4),
                                            Row(children: [
                                              if (channel.isDefault)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: Colors
                                                          .green
                                                          .withOpacity(
                                                              0.2),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  4)),
                                                  child: const Text(
                                                      '🌐 Global',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .green,
                                                          fontSize:
                                                              10)),
                                                ),
                                              if (channel.isDefault)
                                                const SizedBox(
                                                    width: 6),
                                              Text(
                                                channel.ownerName ??
                                                    'No owner',
                                                style: const TextStyle(
                                                    color: AppColors
                                                        .grey,
                                                    fontSize: 12),
                                              ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: AppColors.grey,
                                              size: 20),
                                          onPressed: () =>
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ChannelDetailScreen(
                                                          channel:
                                                              channel),
                                                ),
                                              )),
                                      IconButton(
                                          icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.grey,
                                              size: 20),
                                          onPressed: () async {
                                            await FirebaseFirestore
                                                .instance
                                                .collection('channels')
                                                .doc(channel.id)
                                                .delete();
                                          }),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                  ],
                );
              },
            ),
            const SizedBox(height: 100),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showCreateChannelSheet,
            icon: const Icon(Icons.add_circle,
                color: AppColors.white),
            label: const Text('Add New Channel',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}