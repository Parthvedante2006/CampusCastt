import subprocess
import os
import logging
import threading
from config import config

logger = logging.getLogger(__name__)

# Active FFmpeg processes: { broadcast_id: subprocess.Popen }
_active_processes: dict[str, subprocess.Popen] = {}
_locks: dict[str, threading.Lock] = {}


# ──────────────────────────────────────────────────────────────
# PUBLIC API
# ──────────────────────────────────────────────────────────────

def start_broadcast(broadcast_id: str) -> bool:
    """
    Create the HLS output folder for this broadcast, then launch FFmpeg
    with its stdin open so we can pipe audio chunks into it.

    Input format: raw PCM s16le, 44100 Hz, 1 channel
    Output: HLS playlist + .ts segments in  <HLS_OUTPUT_DIR>/<broadcast_id>/
    """
    if broadcast_id in _active_processes:
        logger.warning(f"[ffmpeg] Broadcast '{broadcast_id}' is already running.")
        return False

    # 1. Create HLS output folder
    output_dir = _hls_dir(broadcast_id)
    os.makedirs(output_dir, exist_ok=True)
    playlist_path = os.path.join(output_dir, "stream.m3u8")

    # 2. Build the FFmpeg command
    #    -f s16le      → raw signed 16-bit little-endian PCM (what Flutter record gives us)
    #    -ar 44100     → sample rate 44 100 Hz
    #    -ac 1         → mono channel
    #    -i pipe:0     → read from stdin
    #    -c:a aac      → encode to AAC for HLS
    #    -b:a 128k     → 128 kbps audio
    command = [
        config.FFMPEG_PATH,
        "-y",                         # overwrite files without asking
        "-f", "s16le",                # input format: raw PCM
        "-ar", "44100",               # sample rate
        "-ac", "1",                   # mono
        "-i", "pipe:0",               # read from stdin
        "-c:a", "aac",                # encode to AAC
        "-b:a", "128k",
        "-f", "hls",
        "-hls_time", str(config.HLS_SEGMENT_TIME),
        "-hls_list_size", str(config.HLS_LIST_SIZE),
        "-hls_flags", "delete_segments+append_list",
        playlist_path,
    ]

    # 3. Launch FFmpeg — stdin=PIPE so we can write chunks
    try:
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        _active_processes[broadcast_id] = process
        _locks[broadcast_id] = threading.Lock()

        # Log FFmpeg stderr in a background thread (for debugging)
        _start_stderr_logger(broadcast_id, process)

        logger.info(
            f"[ffmpeg] Started broadcast '{broadcast_id}' "
            f"(PID {process.pid}) → {playlist_path}"
        )
        return True

    except FileNotFoundError:
        logger.error(
            "[ffmpeg] FFmpeg not found. "
            "Make sure it is installed and available in PATH."
        )
        return False
    except Exception as exc:
        logger.error(f"[ffmpeg] Failed to start broadcast '{broadcast_id}': {exc}")
        return False


def write_chunk(broadcast_id: str, chunk: bytes) -> bool:
    """
    Write an incoming audio chunk (raw PCM bytes from Flutter) into
    FFmpeg's stdin pipe.
    """
    process = _active_processes.get(broadcast_id)
    lock = _locks.get(broadcast_id)

    if not process or process.poll() is not None:
        logger.warning(
            f"[ffmpeg] Cannot write chunk — no active process for '{broadcast_id}'."
        )
        return False

    try:
        with lock:
            process.stdin.write(chunk)
            process.stdin.flush()
        return True
    except BrokenPipeError:
        logger.error(f"[ffmpeg] Broken pipe for broadcast '{broadcast_id}'.")
        _cleanup(broadcast_id)
        return False
    except Exception as exc:
        logger.error(f"[ffmpeg] Error writing chunk for '{broadcast_id}': {exc}")
        return False


def stop_broadcast(broadcast_id: str) -> bool:
    """
    Close FFmpeg's stdin pipe gracefully, wait for it to flush remaining
    segments, then clean up tracking state.
    """
    process = _active_processes.get(broadcast_id)
    if not process:
        logger.warning(f"[ffmpeg] No active process found for '{broadcast_id}'.")
        return False

    try:
        # Closing stdin signals FFmpeg that the input stream is finished
        if process.stdin and not process.stdin.closed:
            process.stdin.close()

        # Wait up to 10 s for FFmpeg to flush remaining HLS segments
        process.wait(timeout=10)
        logger.info(f"[ffmpeg] Broadcast '{broadcast_id}' stopped cleanly.")

    except subprocess.TimeoutExpired:
        logger.warning(
            f"[ffmpeg] FFmpeg for '{broadcast_id}' did not exit in time — killing."
        )
        process.kill()
        process.wait()

    finally:
        _cleanup(broadcast_id)

    return True


def get_active_broadcasts() -> list[str]:
    """Return a list of currently active broadcast IDs."""
    return list(_active_processes.keys())


def is_broadcast_active(broadcast_id: str) -> bool:
    process = _active_processes.get(broadcast_id)
    return process is not None and process.poll() is None


# ──────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ──────────────────────────────────────────────────────────────

def _hls_dir(broadcast_id: str) -> str:
    return os.path.join(config.HLS_OUTPUT_DIR, broadcast_id)


def _cleanup(broadcast_id: str):
    _active_processes.pop(broadcast_id, None)
    _locks.pop(broadcast_id, None)


def _start_stderr_logger(broadcast_id: str, process: subprocess.Popen):
    """Read FFmpeg's stderr in a daemon thread so it doesn't block."""
    def _read():
        for line in process.stderr:
            decoded = line.decode(errors="replace").rstrip()
            if decoded:
                logger.debug(f"[ffmpeg:{broadcast_id}] {decoded}")

    t = threading.Thread(target=_read, daemon=True)
    t.start()
