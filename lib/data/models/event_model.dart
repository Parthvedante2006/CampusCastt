import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String? description;
  final String sectionId;
  final String createdBy;
  final String createdByName;
  final DateTime eventDate;
  final String? location;
  final String? imageUrl;
  final String? paymentLink;
  final String? registrationLink;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.sectionId,
    required this.createdBy,
    required this.createdByName,
    required this.eventDate,
    this.location,
    this.imageUrl,
    this.paymentLink,
    this.registrationLink,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId, {String? sectionId}) {
    return EventModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'],
      sectionId: sectionId ?? map['section_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdByName: map['created_by_name'] ?? '',
      eventDate: (map['event_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'],
      imageUrl: map['image_url'],
      paymentLink: map['payment_link'],
      registrationLink: map['registration_link'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'section_id': sectionId,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'event_date': Timestamp.fromDate(eventDate),
      'location': location,
      'image_url': imageUrl,
      'payment_link': paymentLink,
      'registration_link': registrationLink,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';
  }
}
