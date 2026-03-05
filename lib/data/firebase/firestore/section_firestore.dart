import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/section_model.dart';
import '../../models/announcement_model.dart';
import '../../models/event_model.dart';
import '../../models/channel_model.dart';
import '../../models/user_model.dart';

class SectionFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  // ── SECTION INFO ─────────────────────────────────────────────

  /// Get the section owned by the current user
  Future<SectionModel?> getOwnedSection() async {
    final uid = _currentUid;
    if (uid == null) return null;

    // Get user doc to find section_id
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final sectionId = userDoc.data()?['section_id'];
    if (sectionId == null) return null;

    final sectionDoc =
        await _firestore.collection('sections').doc(sectionId).get();
    if (!sectionDoc.exists) return null;

    return SectionModel.fromMap(sectionDoc.data()!, sectionDoc.id);
  }

  /// Stream the section owned by the current user
  Stream<SectionModel?> watchOwnedSection(String sectionId) {
    return _firestore
        .collection('sections')
        .doc(sectionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SectionModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ── STUDENTS ─────────────────────────────────────────────────

  /// Get count of students in a section
  Stream<int> watchStudentCount(String sectionId) {
    return _firestore
        .collection('users')
        .where('joined_sections', arrayContains: sectionId)
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get all students in a section
  Stream<List<UserModel>> watchStudents(String sectionId) {
    return _firestore
        .collection('users')
        .where('joined_sections', arrayContains: sectionId)
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── CHANNELS ─────────────────────────────────────────────────

  /// Get channels belonging to a section
  Stream<List<ChannelModel>> watchSectionChannels(String sectionId) {
    return _firestore
        .collection('channels')
        .where('section_id', isEqualTo: sectionId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── ANNOUNCEMENTS ────────────────────────────────────────────

  /// Get all announcements for a section
  Stream<List<AnnouncementModel>> watchAnnouncements(String sectionId) {
    return _firestore
        .collection('broadcasts')
        .where('section_id', isEqualTo: sectionId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get live announcements for a section
  Stream<AnnouncementModel?> watchLiveAnnouncement(String sectionId) {
    return _firestore
        .collection('broadcasts')
        .where('section_id', isEqualTo: sectionId)
        .where('status', isEqualTo: 'live')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return AnnouncementModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  /// Create a new announcement / broadcast
  Future<String> createAnnouncement({
    required String title,
    String? description,
    required String sectionId,
    required String status,
    String? audioUrl,
    DateTime? scheduledAt,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not authenticated');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown';

    final docRef = await _firestore.collection('broadcasts').add({
      'title': title,
      'description': description,
      'section_id': sectionId,
      'created_by': uid,
      'created_by_name': userName,
      'status': status,
      'listeners': 0,
      'duration_minutes': 0,
      'audio_url': audioUrl,
      'created_at': FieldValue.serverTimestamp(),
      if (scheduledAt != null)
        'scheduled_at': Timestamp.fromDate(scheduledAt),
    });

    return docRef.id;
  }

  /// End a live announcement
  Future<void> endAnnouncement(String announcementId) async {
    await _firestore.collection('broadcasts').doc(announcementId).update({
      'status': 'ended',
    });
  }

  // ── EVENTS ───────────────────────────────────────────────────

  /// Get all events for a section from subcollection
  Stream<List<EventModel>> watchEvents(String sectionId) {
    return _firestore
        .collection('sections')
        .doc(sectionId)
        .collection('events')
        .orderBy('event_date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id, sectionId: sectionId))
            .toList());
  }

  /// Create a new event in the section's events subcollection
  Future<String> createEvent({
    required String title,
    String? description,
    required String sectionId,
    required DateTime eventDate,
    String? location,
    String? imageUrl,
    String? paymentLink,
    String? registrationLink,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not authenticated');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown';

    final docRef = await _firestore
        .collection('sections')
        .doc(sectionId)
        .collection('events')
        .add({
      'title': title,
      'description': description,
      'created_by': uid,
      'created_by_name': userName,
      'event_date': Timestamp.fromDate(eventDate),
      'location': location,
      'image_url': imageUrl,
      'payment_link': paymentLink,
      'registration_link': registrationLink,
      'created_at': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ── RECENT ACTIVITY ──────────────────────────────────────────

  /// Get recent activity (mix of announcements and events), limited
  Future<List<Map<String, dynamic>>> getRecentActivity(String sectionId) async {
    final List<Map<String, dynamic>> activities = [];

    // Get recent broadcasts
    final broadcasts = await _firestore
        .collection('broadcasts')
        .where('section_id', isEqualTo: sectionId)
        .orderBy('created_at', descending: true)
        .limit(5)
        .get();

    for (final doc in broadcasts.docs) {
      final data = doc.data();
      activities.add({
        'type': 'announcement',
        'title': data['title'] ?? '',
        'subtitle': data['created_by_name'] ?? '',
        'created_at': data['created_at'],
        'status': data['status'] ?? 'ended',
      });
    }

    // Get recent events from subcollection
    final events = await _firestore
        .collection('sections')
        .doc(sectionId)
        .collection('events')
        .orderBy('created_at', descending: true)
        .limit(5)
        .get();

    for (final doc in events.docs) {
      final data = doc.data();
      activities.add({
        'type': 'event',
        'title': data['title'] ?? '',
        'subtitle': data['location'] ?? '',
        'created_at': data['created_at'],
      });
    }

    // Sort by created_at descending
    activities.sort((a, b) {
      final aTime = a['created_at'] as Timestamp?;
      final bTime = b['created_at'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return activities.take(5).toList();
  }
}
