"""
test_broadcast.py — Step 8
Simulates what Flutter will do: connects via Socket.IO,
starts a broadcast, streams a real audio file in chunks,
then stops.

Usage:
  1. Start the server: uvicorn main:socket_app --host 0.0.0.0 --port 8000
  2. Optionally place a test_audio.webm file in backend/
  3. Run: python test_broadcast.py
  4. Open VLC → Media → Open Network → http://localhost:8000/stream/test001/stream.m3u8
"""

import socketio
import time
import os

SERVER_URL   = "http://localhost:8000"
BROADCAST_ID = "test001"
CHANNEL_ID   = "ch001"
AUDIO_FILE   = "test_audio.webm"   # any audio file — optional

# Use websocket transport (now that websocket-client is installed)
sio = socketio.Client(logger=True, engineio_logger=False)


@sio.event
def connect():
    print("✅ Connected to server!")


@sio.event
def disconnect():
    print("🔌 Disconnected from server.")


@sio.on("connection_ack")
def on_connection_ack(data):
    print(f"📡 Connection ack: {data}")


@sio.on("broadcast_ack")
def on_broadcast_ack(data):
    print(f"📣 Broadcast ack: {data}")


@sio.on("error")
def on_error(data):
    print(f"❌ Server error: {data}")


if __name__ == "__main__":
    print(f"Connecting to {SERVER_URL} ...")

    try:
        # Explicitly specify websocket transport now that the package is installed.
        # Fall back to polling if websocket fails.
        sio.connect(
            SERVER_URL,
            transports=["websocket", "polling"],
            wait_timeout=10,
        )
    except Exception as e:
        print(f"❌ Could not connect: {e}")
        raise SystemExit(1)

    time.sleep(0.5)

    # ── 1. Start broadcast ─────────────────────────────────
    print(f"\n▶  Starting broadcast '{BROADCAST_ID}' ...")
    sio.emit("broadcast_start", {
        "broadcast_id": BROADCAST_ID,
        "channel_id":   CHANNEL_ID,
    })
    time.sleep(1)

    # ── 2. Stream audio in chunks ──────────────────────────
    if os.path.exists(AUDIO_FILE):
        print(f"🎙  Streaming '{AUDIO_FILE}' in 4096-byte chunks ...")
        with open(AUDIO_FILE, "rb") as f:
            sent = 0
            while chunk := f.read(4096):
                sio.emit("audio_chunk", {
                    "broadcast_id": BROADCAST_ID,
                    "chunk":        chunk,
                })
                sent += len(chunk)
                time.sleep(0.05)   # ~20 chunks/sec → realistic mic rate
        print(f"✅ Streamed {sent} bytes total.")
    else:
        # No audio file — just hold for a few seconds so you can see
        # the HLS folder get created
        print(f"ℹ️  No audio file found at '{AUDIO_FILE}'.")
        print("   Holding for 4 seconds (HLS folder should appear on server)...")
        time.sleep(4)

    # ── 3. Stop broadcast ──────────────────────────────────
    print(f"\n⏹  Stopping broadcast '{BROADCAST_ID}' ...")
    sio.emit("broadcast_stop", {"broadcast_id": BROADCAST_ID})
    time.sleep(2)

    sio.disconnect()

    print("\n🎉 Test complete!")
    print(f"   HLS playlist: http://localhost:8000/stream/{BROADCAST_ID}/stream.m3u8")
    if os.path.exists(AUDIO_FILE):
        print(f"   Open in VLC to verify audio plays.")
