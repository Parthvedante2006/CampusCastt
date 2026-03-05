import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/section_model.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/user_model.dart';

class StudentFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -- Sections --
  Stream<List<SectionModel>> streamAllSections() {
    return _firestore.collection('sections').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SectionModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // -- Channels --
  Stream<List<ChannelModel>> streamChannelsBySection(String sectionId) {
    if (sectionId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('channels')
        .where('section_id', isEqualTo: sectionId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChannelModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<ChannelModel>> streamGlobalChannels() {
    return _firestore
        .collection('channels')
        .where('is_global', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChannelModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<ChannelModel>> streamJoinedChannels(List<String> joinedIds) {
    if (joinedIds.isEmpty) return Stream.value([]);
    // Firestore 'whereIn' limits to 10. If more, need to chunk or retrieve all and filter.
    // For now, assume < 10 or fetch all and filter client side.
    return _firestore
        .collection('channels')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
          .where((channel) => joinedIds.contains(channel.id))
          .toList();
    });
  }

  // -- User Actions --
  Future<void> joinChannel(String channelId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'joined_channels': FieldValue.arrayUnion([channelId]),
    });
    // Update channel member count
    await _firestore.collection('channels').doc(channelId).update({
      'member_count': FieldValue.increment(1),
    });
  }

  // -- Broadcasts --
  Stream<List<Map<String, dynamic>>> streamLiveBroadcasts() {
    return _firestore
        .collection('broadcasts')
        .where('is_live', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> streamReplays() {
    return _firestore
        .collection('broadcasts')
        .where('is_live', isEqualTo: false)
        .orderBy('endedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // -- Events --
  /// Currently fetching all events from all channels and filtering by date.
  /// Note: Firestore doesn't easily support collection group queries without indexes,
  /// so we'll query events via a collectionGroup if index is added, or fetch all if small.
  /// For robust production, use collectionGroup('events') with required index.
  Stream<List<EventModel>> streamAllEvents() {
    return _firestore.collectionGroup('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
