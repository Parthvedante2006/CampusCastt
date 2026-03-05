import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/domain/repositories/channel_repository.dart';
import 'package:campuscast/data/models/channel_model.dart';

final _repo = ChannelRepository();

// ── Channel stream provider ────────────────────────────────────
/// Watches a Firestore channel doc in real time.
/// Usage: ref.watch(channelProvider('ch001'))
final channelProvider =
    StreamProvider.family<ChannelModel, String>((ref, channelId) {
  return _repo.streamChannel(channelId);
});

// ── Listener count provider ────────────────────────────────────
/// Watches the listener count for a broadcast in real time.
/// Usage: ref.watch(listenerCountProvider('broadcast_id'))
final listenerCountProvider =
    StreamProvider.family<int, String>((ref, broadcastId) {
  return _repo.streamListenerCount(broadcastId);
});

// ── All channels provider (home screen) ───────────────────────
/// Watches ALL channels in real time.
final allChannelsProvider =
    StreamProvider<List<ChannelModel>>((ref) {
  return _repo.streamAllChannels();
});

// ── Channel broadcasts provider ────────────────────────────────
/// Watches broadcasts for a specific channel.
final channelBroadcastsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, channelId) {
  return _repo.streamChannelBroadcasts(channelId);
});
