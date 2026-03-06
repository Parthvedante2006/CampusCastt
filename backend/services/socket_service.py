import socketio
import logging

import services.ffmpeg_service as ffmpeg_service
import services.hls_service as hls_service
import services.notification_service as notification_service

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────
# Socket.IO server instance
# Exported to main.py where it is mounted as an ASGI app
# ──────────────────────────────────────────────────────────────
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",   # lock this down in production
    logger=False,
    engineio_logger=False,
)


# ──────────────────────────────────────────────────────────────
# Connection lifecycle
# ──────────────────────────────────────────────────────────────

@sio.event
async def connect(sid, environ, auth=None):
    logger.info(f"[socket] Client connected: {sid}")
    await sio.emit("connection_ack", {"status": "connected", "sid": sid}, to=sid)


@sio.event
async def disconnect(sid):
    logger.info(f"[socket] Client disconnected: {sid}")


# ──────────────────────────────────────────────────────────────
# EVENT 1 — broadcast_start
# Sent by Flutter moderator when GO LIVE is tapped.
#
# Expected payload:
#   { "broadcast_id": "abc123", "channel_id": "ch001" }
# ──────────────────────────────────────────────────────────────

@sio.event
async def broadcast_start(sid, data):
    broadcast_id = data.get("broadcast_id", "").strip()
    channel_id   = data.get("channel_id", "").strip()

    if not broadcast_id:
        await sio.emit("error", {"message": "broadcast_id is required"}, to=sid)
        return

    print(f"\n[broadcast_start] broadcast_id={broadcast_id}  channel_id={channel_id}")

    # 1. Create the HLS output folder
    hls_service.create_hls_folder(broadcast_id)

    # 2. Launch FFmpeg with stdin pipe open
    success = ffmpeg_service.start_broadcast(broadcast_id)

    if success:
        print(f"[broadcast_start] ✅ FFmpeg started for '{broadcast_id}'")
        
        # Send push notifications to subscribers
        try:
            notification_service.send_live_broadcast_notification(
                channel_id=channel_id,
                broadcast_id=broadcast_id
            )
        except Exception as e:
            logger.error(f"[broadcast_start] Failed to send notifications: {e}")
        
        await sio.emit(
            "broadcast_ack",
            {"status": "started", "broadcast_id": broadcast_id},
            to=sid,
        )
    else:
        print(f"[broadcast_start] ❌ Failed to start FFmpeg for '{broadcast_id}'")
        await sio.emit(
            "error",
            {"message": f"Could not start broadcast '{broadcast_id}'"},
            to=sid,
        )


# ──────────────────────────────────────────────────────────────
# EVENT 2 — audio_chunk
# Sent continuously by Flutter while mic is recording.
#
# Expected payload:
#   { "broadcast_id": "abc123", "chunk": <bytes> }
# ──────────────────────────────────────────────────────────────

@sio.event
async def audio_chunk(sid, data):
    broadcast_id = data.get("broadcast_id", "").strip()
    chunk        = data.get("chunk")

    if not broadcast_id or chunk is None:
        return  # silently ignore malformed chunks

    # chunk arrives as bytes or bytearray from Socket.IO
    if isinstance(chunk, (bytes, bytearray)):
        ffmpeg_service.write_chunk(broadcast_id, bytes(chunk))
    else:
        logger.warning(
            f"[audio_chunk] Unexpected chunk type: {type(chunk)} "
            f"for broadcast '{broadcast_id}'"
        )


# ──────────────────────────────────────────────────────────────
# EVENT 3 — broadcast_stop
# Sent by Flutter moderator when STOP is tapped.
#
# Expected payload:
#   { "broadcast_id": "abc123" }
# ──────────────────────────────────────────────────────────────

@sio.event
async def broadcast_stop(sid, data):
    broadcast_id = data.get("broadcast_id", "").strip()

    if not broadcast_id:
        await sio.emit("error", {"message": "broadcast_id is required"}, to=sid)
        return

    print(f"\n[broadcast_stop] Stopping broadcast '{broadcast_id}' ...")

    # 1. Close FFmpeg stdin and wait for clean exit
    success = ffmpeg_service.stop_broadcast(broadcast_id)

    if success:
        print(f"[broadcast_stop] ✅ FFmpeg stopped for '{broadcast_id}'")
        await sio.emit(
            "broadcast_ack",
            {"status": "stopped", "broadcast_id": broadcast_id},
            to=sid,
        )
    else:
        print(f"[broadcast_stop] ⚠️  No active process found for '{broadcast_id}'")
        await sio.emit(
            "error",
            {"message": f"No active broadcast found for '{broadcast_id}'"},
            to=sid,
        )
