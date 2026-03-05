import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:campuscast/core/constants/app_config.dart';

class SocketClient {
  SocketClient._();
  static final SocketClient instance = SocketClient._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  // ──────────────────────────────────────────────
  // Connection
  // ──────────────────────────────────────────────

  void connect() {
    if (isConnected) return;

    _socket = io.io(
      AppConfig.serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('[socket] Connected to server');
    });

    _socket!.on('connection_ack', (data) {
      print('[socket] Ack: $data');
    });

    _socket!.on('broadcast_ack', (data) {
      print('[socket] Broadcast ack: $data');
    });

    _socket!.onDisconnect((_) {
      print('[socket] Disconnected from server');
    });

    _socket!.onError((err) {
      print('[socket] Error: $err');
    });

    _socket!.connect();
  }

  // ──────────────────────────────────────────────
  // Events — Flutter → Server
  // ──────────────────────────────────────────────

  /// Sent when the moderator taps GO LIVE.
  void emitBroadcastStart(String broadcastId, String channelId) {
    _socket?.emit('broadcast_start', {
      'broadcast_id': broadcastId,
      'channel_id':   channelId,
    });
    print('[socket] Emitted broadcast_start for $broadcastId');
  }

  /// Sent continuously by the mic stream.
  /// [chunk] is raw PCM bytes from the record package.
  void emitAudioChunk(String broadcastId, Uint8List chunk) {
    _socket?.emit('audio_chunk', {
      'broadcast_id': broadcastId,
      'chunk':        chunk,
    });
  }

  /// Sent when the moderator taps STOP.
  void emitBroadcastStop(String broadcastId) {
    _socket?.emit('broadcast_stop', {
      'broadcast_id': broadcastId,
    });
    print('[socket] Emitted broadcast_stop for $broadcastId');
  }

  // ──────────────────────────────────────────────
  // Listeners — Server → Flutter
  // ──────────────────────────────────────────────

  /// Register a callback for when the server confirms start/stop.
  void onBroadcastAck(void Function(Map<String, dynamic>) callback) {
    _socket?.on('broadcast_ack', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Register a callback for server errors.
  void onError(void Function(String message) callback) {
    _socket?.on('error', (data) {
      final msg = (data as Map)['message'] as String? ?? 'Unknown error';
      callback(msg);
    });
  }

  // ──────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('[socket] Disconnected and disposed.');
  }
}
