import 'package:cloud_firestore/cloud_firestore.dart';

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
}
