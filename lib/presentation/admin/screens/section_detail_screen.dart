import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/firebase/admin/admin_firestore_service.dart';
import '../../../domain/providers/admin_provider.dart';

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
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  String _generatedPassword = '';
  bool _isSavingOwner = false;
  bool _isUploadingCsv = false;

  @override
  void initState() {
    super.initState();
    _generatedPassword = AdminFirestoreService.generatePassword();
    if (widget.ownerName != null) _ownerNameController.text = widget.ownerName!;
    if (widget.ownerEmail != null) _ownerEmailController.text = widget.ownerEmail!;
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveOwnerCredentials() async {
    if (_ownerNameController.text.trim().isEmpty || _ownerEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name and email.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSavingOwner = true);

    try {
      await ref.read(adminRepositoryProvider).setSectionOwner(
        sectionId: widget.sectionId,
        name: _ownerNameController.text.trim(),
        email: _ownerEmailController.text.trim(),
        password: _generatedPassword,
        collegeTrust: widget.collegeTrust,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section owner created successfully!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSavingOwner = false);
    }
  }

  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploadingCsv = true);

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);

      // Skip header row if present
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
      
      final added = uploadResult['added'] ?? 0;
      final existed = uploadResult['existed'] ?? 0;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added new students added, $existed already existed'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCsv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(widget.sectionName, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_balance, color: AppColors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.sectionName, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.collegeTrust, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Owner Credentials Card
            const Text('SECTION OWNER', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                    controller: _ownerNameController,
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
                    controller: _ownerEmailController,
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
                  // Password row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_generatedPassword, style: const TextStyle(color: AppColors.white, fontFamily: 'monospace'))),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.grey, size: 20),
                          onPressed: () => setState(() => _generatedPassword = AdminFirestoreService.generatePassword()),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.grey, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password copied!'), duration: Duration(seconds: 1)),
                            );
                          },
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: _isSavingOwner ? null : _saveOwnerCredentials,
                      child: _isSavingOwner
                          ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                          : const Text('Save Credentials', style: TextStyle(color: AppColors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CSV Upload Card
            const Text('STUDENT CSV', style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Icon(Icons.upload_file, color: AppColors.grey, size: 40),
                  const SizedBox(height: 12),
                  const Text('Upload student emails to whitelist', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('CSV format: name, email, college', style: TextStyle(color: AppColors.grey, fontSize: 11)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: _isUploadingCsv ? null : _uploadCsv,
                      icon: _isUploadingCsv ? const SizedBox.shrink() : const Icon(Icons.file_upload, color: AppColors.white),
                      label: _isUploadingCsv
                          ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                          : const Text('Upload Student CSV', style: TextStyle(color: AppColors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
