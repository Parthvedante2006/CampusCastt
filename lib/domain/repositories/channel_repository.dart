import 'package:campuscast/data/firebase/firestore/channel_firestore.dart';
import 'package:campuscast/data/models/channel_model.dart';
import 'package:campuscast/data/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelRepository {
  final _firestore = ChannelFirestore();
  final _db        = FirebaseFirestore.instance;

  /// Real-time stream of a single channel document.
  Stream<ChannelModel> streamChannel(String channelId) {
    return _db
        .collection('channels')
        .doc(channelId)
        .snapshots()
        .map((snap) =>
            ChannelModel.fromMap(snap.data() ?? {}, snap.id));
  }

  /// Real-time stream of the listener count for a broadcast.
  Stream<int> streamListenerCount(String broadcastId) {
    return _firestore.streamListenerCount(broadcastId);
  }

  /// One-shot fetch of a single channel.
  Future<ChannelModel?> getChannel(String channelId) async {
    final snap = await _db.collection('channels').doc(channelId).get();
    if (!snap.exists) return null;
    return ChannelModel.fromMap(snap.data()!, snap.id);
  }

  /// Real-time stream of ALL channels (for the home screen list).
  Stream<List<ChannelModel>> streamAllChannels() {
    return _db
        .collection('channels')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream broadcasts for a specific channel (ordered by startedAt descending).
  Stream<List<Map<String, dynamic>>> streamChannelBroadcasts(String channelId) {
    return _db
        .collection('broadcasts')
        .where('channelId', isEqualTo: channelId)
        .snapshots()
        .map((snap) {
      // Get all broadcasts for this channel
      final broadcasts = snap.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
      
      // Sort by startedAt descending (newest first) - client-side
      broadcasts.sort((a, b) {
        final aTs = a['startedAt'];
        final bTs = b['startedAt'];
        
        final aDate = aTs is Timestamp 
            ? aTs.toDate() 
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bTs is Timestamp 
            ? bTs.toDate() 
            : DateTime.fromMillisecondsSinceEpoch(0);
        
        return bDate.compareTo(aDate); // Descending order
      });
      
      // Limit to 10 most recent
      return broadcasts.take(10).toList();
    });
  }

  /// Stream completed scheduled announcements that have playable audio.
  /// This keeps replay visibility scoped to a specific channel.
  Stream<List<Map<String, dynamic>>> streamChannelAnnouncementReplays(
    String channelId,
  ) {
    return _db
        .collection('scheduled_announcements')
        .where('channel_id', isEqualTo: channelId)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final items = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((data) {
        final audioUrl = (data['audio_url'] ?? '').toString().trim();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final scheduledAt = data['scheduled_at'];

        DateTime? scheduledDate;
        if (scheduledAt is Timestamp) {
          scheduledDate = scheduledAt.toDate();
        }

        final isDone = status == 'sent' ||
            (scheduledDate != null && !scheduledDate.isAfter(now));

        return audioUrl.isNotEmpty && isDone && status != 'cancelled';
      }).toList();

      items.sort((a, b) {
        final aTs = a['scheduled_at'];
        final bTs = b['scheduled_at'];

        final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  /// Stream upcoming scheduled announcements for a specific channel.
  Stream<List<Map<String, dynamic>>> streamChannelScheduledAnnouncements(
    String channelId,
  ) {
    return _db
        .collection('scheduled_announcements')
        .where('channel_id', isEqualTo: channelId)
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final items = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).where((data) {
        final scheduledAt = data['scheduled_at'];
        
        DateTime? scheduledDate;
        if (scheduledAt is Timestamp) {
          scheduledDate = scheduledAt.toDate();
        }

        // Only upcoming announcements
        return scheduledDate != null && scheduledDate.isAfter(now);
      }).toList();

      // Sort by scheduled time (earliest first)
      items.sort((a, b) {
        final aTs = a['scheduled_at'];
        final bTs = b['scheduled_at'];

        final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

      return items;
    });
  }

  /// Stream events for a specific channel from the
  /// channels/{channelId}/events subcollection.
  Stream<List<EventModel>> streamChannelEvents(String channelId) {
    return _firestore.streamChannelEvents(channelId);
  }
}
