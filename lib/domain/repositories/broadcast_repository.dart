import 'package:uuid/uuid.dart';
import 'package:campuscast/data/socket/socket_client.dart';
import 'package:campuscast/data/firebase/firestore/channel_firestore.dart';
import 'package:campuscast/data/api/broadcast_api.dart';

class BroadcastRepository {
  final _socket    = SocketClient.instance;
  final _firestore = ChannelFirestore();
  final _api       = BroadcastApi();
  final _uuid      = const Uuid();

  /// Start a new broadcast for [channelId].
  /// Returns the generated [broadcastId] so the caller can track it.
  Future<String> startBroadcast(String channelId) async {
    // 1. Generate a unique broadcast ID
    final broadcastId = _uuid.v4();

    // 2. Connect to Socket.IO and tell the server to spin up FFmpeg
    _socket.connect();
    _socket.emitBroadcastStart(broadcastId, channelId);

    // 3. Wait briefly for FFmpeg to start writing the playlist
    await Future.delayed(const Duration(seconds: 1));

    // 4. Fetch the HLS stream URL from the backend
    String streamUrl = '';
    try {
      streamUrl = await _api.getStreamUrl(broadcastId);
    } catch (_) {
      // URL may not be ready yet — Firestore doc will be updated by the backend later
      streamUrl = '';
    }

    // 5. Write the broadcast document to Firestore
    await _firestore.createBroadcast(
      broadcastId: broadcastId,
      channelId:   channelId,
      streamUrl:   streamUrl,
    );

    // 6. Mark the channel as live
    await _firestore.setIsLive(
      channelId,
      true,
      activeBroadcastId: broadcastId,
    );

    return broadcastId;
  }

  /// Stop the currently active broadcast.
  Future<void> stopBroadcast(String broadcastId, String channelId) async {
    // 1. Tell the server to close FFmpeg stdin and stop the process
    _socket.emitBroadcastStop(broadcastId);

    // 2. Mark broadcast as ended in Firestore
    await _firestore.endBroadcast(broadcastId);

    // 3. Mark channel as no longer live
    await _firestore.setIsLive(channelId, false);

    // 4. Disconnect the socket cleanly
    _socket.disconnect();
  }
}
