import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campuscast/data/models/event_model.dart';

class StudentEventDetailScreen extends StatelessWidget {
  final EventModel event;

  const StudentEventDetailScreen({
    super.key,
    required this.event,
  });

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLinkDialog(String url, String title, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141922),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              url,
              style: const TextStyle(
                color: Color(0xFF4A9EFF),
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              _copyToClipboard(url, context);
              Navigator.pop(context);
            },
            child: const Text(
              'Copy',
              style: TextStyle(color: Color(0xFF4A9EFF)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141922),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Event Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header with Date Badge
            Container(
              color: const Color(0xFF1B2330),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Badge
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3C78).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.eventDate.day.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Color(0xFF3B67AA),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _monthAbbr(event.eventDate.month),
                          style: TextStyle(
                            color: const Color(0xFF3B67AA).withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          event.eventDate.year.toString(),
                          style: TextStyle(
                            color: const Color(0xFF3B67AA).withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Event Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Created by
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3C78).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            event.createdByName.isNotEmpty
                                ? event.createdByName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF3B67AA),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Posted by',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            event.createdByName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Event Details Panel
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Section
                  _buildDetailSection(
                    icon: Icons.access_time_rounded,
                    title: 'Time',
                    content: _formatTime(event.eventDate),
                  ),

                  // Location Section
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      content: event.location!,
                    ),
                  ],

                  // Description Section
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      icon: Icons.description_rounded,
                      title: 'Description',
                      content: event.description!,
                    ),
                  ],

                  // Registration Link Section
                  if (event.registrationLink != null &&
                      event.registrationLink!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildLinkSection(
                      context: context,
                      icon: Icons.app_registration_rounded,
                      title: 'Registration',
                      url: event.registrationLink!,
                    ),
                  ],

                  // Payment Link Section
                  if (event.paymentLink != null && event.paymentLink!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildLinkSection(
                      context: context,
                      icon: Icons.payment_rounded,
                      title: 'Payment Link',
                      url: event.paymentLink!,
                    ),
                  ],

                  // Created At Section
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    icon: Icons.calendar_today_rounded,
                    title: 'Posted On',
                    content: _formatCreatedAt(event.createdAt),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF3B67AA), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF112240),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String url,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF3B67AA), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showLinkDialog(url, title, context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1D3C78).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B67AA).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(
                      color: Color(0xFF3B67AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.open_in_new, color: Color(0xFF3B67AA), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCreatedAt(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${_formatTime(dateTime)}';
  }
}
