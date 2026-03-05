import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String? description;
  final String sectionId;
  final String createdBy;       // uid
  final String createdByName;
  final String status;          // "live" | "ended" | "scheduled"
  final int listeners;
  final int durationMinutes;
  final String? audioUrl;
  final DateTime createdAt;
  final DateTime? scheduledAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    this.description,
    required this.sectionId,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    this.listeners = 0,
    this.durationMinutes = 0,
    this.audioUrl,
    required this.createdAt,
    this.scheduledAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnnouncementModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'],
      sectionId: map['section_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdByName: map['created_by_name'] ?? '',
      status: map['status'] ?? 'ended',
      listeners: map['listeners'] ?? 0,
      durationMinutes: map['duration_minutes'] ?? 0,
      audioUrl: map['audio_url'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (map['scheduled_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'section_id': sectionId,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'status': status,
      'listeners': listeners,
      'duration_minutes': durationMinutes,
      'audio_url': audioUrl,
      'created_at': Timestamp.fromDate(createdAt),
      if (scheduledAt != null) 'scheduled_at': Timestamp.fromDate(scheduledAt!),
    };
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  String get formattedListeners {
    if (listeners >= 1000) {
      return '${(listeners / 1000).toStringAsFixed(1)}k';
    }
    return listeners.toString();
  }

  String get formattedDuration {
    if (durationMinutes > 0) return '$durationMinutes mins';
    return '';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formattedDate;
  }
}
