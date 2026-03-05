import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// ── State ──────────────────────────────────────────────────────
enum PlayerState { idle, buffering, playing, stopped, error }

class PlayerNotifierState {
  final PlayerState state;
  final String?     streamUrl;
  final String?     error;

  const PlayerNotifierState({
    this.state    = PlayerState.idle,
    this.streamUrl,
    this.error,
  });

  PlayerNotifierState copyWith({
    PlayerState? state,
    String?      streamUrl,
    String?      error,
  }) {
    return PlayerNotifierState(
      state:     state     ?? this.state,
      streamUrl: streamUrl ?? this.streamUrl,
      error:     error,
    );
  }
}

// ── Notifier (Riverpod 3.x API) ────────────────────────────────
class PlayerNotifier extends Notifier<PlayerNotifierState> {
  late final AudioPlayer _audioPlayer;

  @override
  PlayerNotifierState build() {
    _audioPlayer = AudioPlayer();
    // Dispose the player automatically when the provider is destroyed
    ref.onDispose(() => _audioPlayer.dispose());
    return const PlayerNotifierState();
  }

  AudioPlayer get audioPlayer => _audioPlayer;

  /// Start playing an HLS stream.
  Future<void> play(String streamUrl) async {
    print('[Player Provider] Setting URL: $streamUrl');
    state = state.copyWith(state: PlayerState.buffering, streamUrl: streamUrl);
    try {
      await _audioPlayer.setUrl(streamUrl);
      print('[Player Provider] URL set successfully, starting playback');
      await _audioPlayer.play();
      print('[Player Provider] Playback started');
      state = state.copyWith(state: PlayerState.playing);
    } catch (e) {
      print('[Player Provider] Error playing audio: $e');
      state = state.copyWith(
        state: PlayerState.error,
        error: e.toString(),
      );
    }
  }

  /// Pause playback.
  Future<void> pause() async {
    await _audioPlayer.pause();
    state = state.copyWith(state: PlayerState.idle);
  }

  /// Stop and reset the player.
  Future<void> stop() async {
    await _audioPlayer.stop();
    state = state.copyWith(state: PlayerState.stopped);
  }
}

// ── Provider (Riverpod 3.x) ────────────────────────────────────
final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerNotifierState>(
  PlayerNotifier.new,
);
