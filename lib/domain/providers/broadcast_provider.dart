import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/domain/repositories/broadcast_repository.dart';
import 'package:campuscast/data/socket/socket_client.dart';
import 'dart:typed_data';

// ── State ──────────────────────────────────────────────────────
enum BroadcastState { idle, starting, live, stopping, stopped }

class BroadcastNotifierState {
  final BroadcastState state;
  final String? broadcastId;
  final String? error;

  const BroadcastNotifierState({
    this.state = BroadcastState.idle,
    this.broadcastId,
    this.error,
  });

  BroadcastNotifierState copyWith({
    BroadcastState? state,
    String?         broadcastId,
    String?         error,
  }) {
    return BroadcastNotifierState(
      state:       state       ?? this.state,
      broadcastId: broadcastId ?? this.broadcastId,
      error:       error,
    );
  }
}

// ── Notifier (Riverpod 3.x API) ────────────────────────────────
class BroadcastNotifier extends Notifier<BroadcastNotifierState> {
  final _repo   = BroadcastRepository();
  final _socket = SocketClient.instance;

  @override
  BroadcastNotifierState build() => const BroadcastNotifierState();

  /// Called when the moderator taps GO LIVE.
  Future<void> goLive(String channelId) async {
    state = state.copyWith(state: BroadcastState.starting);
    try {
      final broadcastId = await _repo.startBroadcast(channelId);
      state = state.copyWith(
        state:       BroadcastState.live,
        broadcastId: broadcastId,
      );
    } catch (e) {
      state = state.copyWith(
        state: BroadcastState.idle,
        error: e.toString(),
      );
    }
  }

  /// Send a raw PCM audio chunk from the mic to the server.
  void sendAudioChunk(Uint8List chunk) {
    final id = state.broadcastId;
    if (id != null && state.state == BroadcastState.live) {
      _socket.emitAudioChunk(id, chunk);
    }
  }

  /// Called when the moderator taps STOP.
  Future<void> stopLive(String channelId) async {
    final id = state.broadcastId;
    if (id == null) return;
    state = state.copyWith(state: BroadcastState.stopping);
    try {
      await _repo.stopBroadcast(id, channelId);
      state = state.copyWith(state: BroadcastState.stopped);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void reset() => state = const BroadcastNotifierState();
}

// ── Provider (Riverpod 3.x) ────────────────────────────────────
final broadcastProvider =
    NotifierProvider<BroadcastNotifier, BroadcastNotifierState>(
  BroadcastNotifier.new,
);
