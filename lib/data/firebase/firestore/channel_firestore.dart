import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event_model.dart';

class ChannelFirestore {
  final _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // Channels
  // ──────────────────────────────────────────────

  /// Mark a channel as live (or not live) and update its active broadcast ID.
  /// Uses set+merge so it CREATES the document if it doesn't exist yet.
  Future<void> setIsLive(
    String channelId,
    bool isLive, {
    String? activeBroadcastId,
  }) async {
    await _db.collection('channels').doc(channelId).set(
      {
        'isLive':            isLive,
        'activeBroadcastId': isLive ? activeBroadcastId : null,
      },
      SetOptions(merge: true), // ← creates doc if it doesn't exist
    );
  }

  // ──────────────────────────────────────────────
  // Broadcasts
  // ──────────────────────────────────────────────

  /// Write a new broadcast document (creates it fresh).
  Future<void> createBroadcast({
    required String broadcastId,
    required String channelId,
    required String streamUrl,
  }) async {
    await _db.collection('broadcasts').doc(broadcastId).set({
      'broadcastId': broadcastId,
      'channelId':   channelId,
      'streamUrl':   streamUrl,
      'listeners':   0,
      'status':      'live',
      'startedAt':   FieldValue.serverTimestamp(),
    });
    // No merge: true here — we always want a clean fresh doc for a new broadcast
  }

  /// Mark a broadcast as ended.
  Future<void> endBroadcast(String broadcastId) async {
    await _db.collection('broadcasts').doc(broadcastId).set(
      {
        'status':  'ended',
        'endedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true), // ← safe even if doc was partially written
    );
  }

  /// Atomically increment the listener count for a broadcast.
  Future<void> incrementListeners(String broadcastId) async {
    await _db.collection('broadcasts').doc(broadcastId).set(
      {'listeners': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  /// Atomically decrement the listener count (floor at 0).
  Future<void> decrementListeners(String broadcastId) async {
    final ref = _db.collection('broadcasts').doc(broadcastId);
    await _db.runTransaction((txn) async {
      final snap    = await txn.get(ref);
      final current = (snap.data()?['listeners'] as num?)?.toInt() ?? 0;
      txn.set(
        ref,
        {'listeners': current > 0 ? current - 1 : 0},
        SetOptions(merge: true),
      );
    });
  }

  /// Real-time stream of the listener count for a broadcast.
  Stream<int> streamListenerCount(String broadcastId) {
    return _db
        .collection('broadcasts')
        .doc(broadcastId)
        .snapshots()
        .map((snap) => (snap.data()?['listeners'] as num?)?.toInt() ?? 0);
  }

  // ──────────────────────────────────────────────
  // Scheduled Announcements
  // ──────────────────────────────────────────────

  /// Create a new scheduled announcement
  Future<String> createScheduledAnnouncement(
      Map<String, dynamic> announcementData) async {
    final docRef = await _db
        .collection('scheduled_announcements')
        .add(announcementData);
    return docRef.id;
  }

  /// Get scheduled announcements for a channel
  Stream<List<Map<String, dynamic>>> streamScheduledAnnouncements(
      String channelId) {
    return _db
        .collection('scheduled_announcements')
        .where('channel_id', isEqualTo: channelId)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('scheduled_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Update announcement status
  Future<void> updateAnnouncementStatus(String announcementId, String status) async {
    await _db
        .collection('scheduled_announcements')
        .doc(announcementId)
        .update({'status': status});
  }

  /// Delete scheduled announcement
  Future<void> deleteScheduledAnnouncement(String announcementId) async {
    await _db
        .collection('scheduled_announcements')
        .doc(announcementId)
        .delete();
  }

  // ──────────────────────────────────────────────
  // Channel Events (per-channel subcollection)
  // ──────────────────────────────────────────────

  /// Stream events for a specific channel from
  /// channels/{channelId}/events ordered by event_date desc.
  Stream<List<EventModel>> streamChannelEvents(String channelId) {
    return _db
        .collection('channels')
        .doc(channelId)
        .collection('events')
        .orderBy('event_date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => EventModel.fromMap(
                  doc.data(),
                  doc.id,
                  sectionId: channelId, // reuse field to hold channelId
                ),
              )
              .toList(),
        );
  }

  /// Create a new event inside channels/{channelId}/events.
  Future<String> createChannelEvent({
    required String channelId,
    required String title,
    String? description,
    required DateTime eventDate,
    String? location,
    String? imageUrl,
    String? paymentLink,
    String? registrationLink,
    required String createdBy,
    required String createdByName,
  }) async {
    final docRef = await _db
        .collection('channels')
        .doc(channelId)
        .collection('events')
        .add({
      'title': title,
      'description': description,
      'section_id': channelId, // keeps compatibility with existing model
      'created_by': createdBy,
      'created_by_name': createdByName,
      'event_date': Timestamp.fromDate(eventDate),
      'location': location,
      'image_url': imageUrl,
      'payment_link': paymentLink,
      'registration_link': registrationLink,
      'created_at': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
