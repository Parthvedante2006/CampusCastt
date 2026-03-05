import 'package:campuscast/data/firebase/firestore/channel_firestore.dart';
import 'package:campuscast/data/models/channel_model.dart';
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
}
