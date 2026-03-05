import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/channel_model.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final ChannelModel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState
    extends ConsumerState<ChannelDetailScreen> {
  // ── Editable controllers ─────────────────────────────────
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerEmailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isSaving = false;
  bool _isLoadingPassword = true;

  @override
  void initState() {
    super.initState();
    _ownerNameController =
        TextEditingController(text: widget.channel.ownerName ?? '');
    _ownerEmailController =
        TextEditingController(text: widget.channel.ownerEmail ?? '');
    _passwordController = TextEditingController();
    _loadPassword();
  }

  // ✅ Load real password from Firestore
  Future<void> _loadPassword() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channel.id)
          .get();
      final password = doc.data()?['owner_password'] ?? '';
      _passwordController.text = password;
    } catch (_) {
      _passwordController.text = '';
    } finally {
      if (mounted) setState(() => _isLoadingPassword = false);
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Save credentials to Firestore + Firebase Auth
  Future<void> _saveCredentials() async {
    if (_ownerEmailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email and password cannot be empty.')));
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 6 characters.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Update Firestore channel doc
      await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channel.id)
          .update({
        'owner_name': _ownerNameController.text.trim(),
        'owner_email': _ownerEmailController.text.trim(),
        'owner_password': _passwordController.text.trim(),
      });

      // Update Firestore users doc if ownerUid exists
     // Update users doc by querying email
final usersQuery = await FirebaseFirestore.instance
    .collection('users')
    .where('email', isEqualTo: widget.channel.ownerEmail ?? '')
    .limit(1)
    .get();
if (usersQuery.docs.isNotEmpty) {
  await usersQuery.docs.first.reference.update({
    'name': _ownerNameController.text.trim(),
    'email': _ownerEmailController.text.trim(),
    'password': _passwordController.text.trim(),
  });
}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Credentials saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ✅ Delete channel from Firestore
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Remove Channel',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${widget.channel.name}"? This cannot be undone.',
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
                  .doc(widget.channel.id)
                  .delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(widget.channel.name,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Channel Info Card ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white12, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8CD8B8)
                          .withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.channel.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF8CD8B8),
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.channel.name,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.accentBlue
                                .withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(6)),
                        child: Text(
                            widget.channel.sectionName
                                .toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (widget.channel.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color:
                                  Colors.green.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(6)),
                          child: const Text('🌐 Global',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats Row ─────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: _statCard('0', 'BROADCASTS')),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard(
                        '${widget.channel.memberCount}',
                        'MEMBERS')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('0', 'POLLS')),
              ],
            ),
            const SizedBox(height: 28),

            // ── Credentials Section ───────────────────────
            const Text('OWNER CREDENTIALS',
                style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
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
                  // Owner Name
                  const Text('Owner Name',
                      style: TextStyle(
                          color: AppColors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerNameController,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person,
                          color: AppColors.grey, size: 20),
                      filled: true,
                      fillColor: AppColors.primaryBg,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Owner Email
                  const Text('Owner Email',
                      style: TextStyle(
                          color: AppColors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerEmailController,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email,
                          color: AppColors.grey, size: 20),
                      filled: true,
                      fillColor: AppColors.primaryBg,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Password — manual editable
                  const Text('Password',
                      style: TextStyle(
                          color: AppColors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  _isLoadingPassword
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentBlue))
                      : TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock,
                                color: AppColors.grey, size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Eye toggle
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword =
                                          !_obscurePassword),
                                ),
                                // Copy button
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: AppColors.accentBlue,
                                      size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: _passwordController
                                            .text));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Password copied!')));
                                  },
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor: AppColors.primaryBg,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // ✅ Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8)),
                      ),
                      onPressed:
                          _isSaving ? null : _saveCredentials,
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2)
                          : const Text('Save Credentials',
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Remove Channel ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _confirmDelete,
                icon:
                    const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove Channel',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Removing this channel will delete all history, members, and credentials permanently.',
              style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}