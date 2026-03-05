import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firebase/firestore/channel_firestore.dart';
import '../../../domain/providers/auth_provider.dart';

class ChannelOwnerPostEventScreen extends ConsumerStatefulWidget {
  const ChannelOwnerPostEventScreen({super.key});

  @override
  ConsumerState<ChannelOwnerPostEventScreen> createState() =>
      _ChannelOwnerPostEventScreenState();
}

class _ChannelOwnerPostEventScreenState
    extends ConsumerState<ChannelOwnerPostEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _paymentLinkController = TextEditingController();
  final _registrationLinkController = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _isSubmitting = false;

  final _channelFirestore = ChannelFirestore();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _paymentLinkController.dispose();
    _registrationLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  Future<void> _createEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || currentUser.channelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No channel assigned to your account')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final channelId = currentUser.channelId!;

      final eventDateTime = DateTime(
        _eventDate!.year,
        _eventDate!.month,
        _eventDate!.day,
        _eventTime?.hour ?? 0,
        _eventTime?.minute ?? 0,
      );

      await _channelFirestore.createChannelEvent(
        channelId: channelId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        eventDate: eventDateTime,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        paymentLink: _paymentLinkController.text.trim().isNotEmpty
            ? _paymentLinkController.text.trim()
            : null,
        registrationLink: _registrationLinkController.text.trim().isNotEmpty
            ? _registrationLinkController.text.trim()
            : null,
        imageUrl: null,
        createdBy: currentUser.uid,
        createdByName: currentUser.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Post New Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EVENT DETAILS',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildField('Event Name', _titleController, 'Enter event title'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    'Date',
                    _eventDate != null
                        ? '${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.year}'
                        : 'mm/dd/yyyy',
                    Icons.calendar_today_rounded,
                    _pickDate,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDateTimeField(
                    'Time',
                    _eventTime != null
                        ? _eventTime!.format(context)
                        : '--:-- --',
                    Icons.access_time_rounded,
                    _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(
              'Location',
              _locationController,
              'e.g. Main Auditorium',
              prefixIcon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 20),
            _buildField(
              'Description',
              _descriptionController,
              'Tell everyone what the event is about...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildField(
              'Payment Link (Optional)',
              _paymentLinkController,
              'https://payment-link.com',
              prefixIcon: Icons.payment_rounded,
            ),
            const SizedBox(height: 20),
            _buildField(
              'Registration Link',
              _registrationLinkController,
              'https://google.forms/...',
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _createEvent,
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'Post Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor:
                      const Color(0xFF2563EB).withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF112240),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value.contains('--:--') || value == 'mm/dd/yyyy'
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


