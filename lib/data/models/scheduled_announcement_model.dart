import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledAnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String channelId;
  final String createdBy;
  final String createdByName;
  final DateTime scheduledAt;
  final bool notifyMembers;
  final String audioPath;
  final String? audioUrl; // After upload to Firebase Storage
  final String status; // 'scheduled' | 'sent' | 'cancelled'
  final DateTime createdAt;

  ScheduledAnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.createdBy,
    required this.createdByName,
    required this.scheduledAt,
    required this.notifyMembers,
    required this.audioPath,
    this.audioUrl,
    required this.status,
    required this.createdAt,
  });

  factory ScheduledAnnouncementModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return ScheduledAnnouncementModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      channelId: map['channel_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdByName: map['created_by_name'] ?? '',
      scheduledAt:
          (map['scheduled_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notifyMembers: map['notify_members'] ?? false,
      audioPath: map['audio_path'] ?? '',
      audioUrl: map['audio_url'],
      status: map['status'] ?? 'scheduled',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'channel_id': channelId,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'notify_members': notifyMembers,
      'audio_path': audioPath,
      if (audioUrl != null) 'audio_url': audioUrl,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  ScheduledAnnouncementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? channelId,
    String? createdBy,
    String? createdByName,
    DateTime? scheduledAt,
    bool? notifyMembers,
    String? audioPath,
    String? audioUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return ScheduledAnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      channelId: channelId ?? this.channelId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notifyMembers: notifyMembers ?? this.notifyMembers,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
