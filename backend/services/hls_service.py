import os
import shutil
import logging
from config import config

logger = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────
# PUBLIC API
# ──────────────────────────────────────────────────────────────

def create_hls_folder(broadcast_id: str) -> str:
    """
    Create the HLS output directory for a broadcast.
    Returns the absolute path to the created folder.
    """
    folder = _hls_dir(broadcast_id)
    os.makedirs(folder, exist_ok=True)
    logger.info(f"[hls] Created HLS folder: {folder}")
    return folder


def get_playlist_path(broadcast_id: str) -> str:
    """
    Return the absolute path to the .m3u8 playlist file for this broadcast.
    The file may not exist yet if FFmpeg hasn't started writing.
    """
    return os.path.join(_hls_dir(broadcast_id), "stream.m3u8")


def get_stream_url(broadcast_id: str, server_host: str) -> str:
    """
    Build and return the full HTTP URL a student uses to play the stream.

    Example:
        get_stream_url("abc123", "https://abcd.ngrok-free.app")
        → "https://abcd.ngrok-free.app/stream/abc123/stream.m3u8"
    """
    # Strip trailing slash to keep the URL clean
    host = server_host.rstrip("/")
    url = f"{host}/stream/{broadcast_id}/stream.m3u8"
    logger.info(f"[hls] Stream URL for '{broadcast_id}': {url}")
    return url


def playlist_exists(broadcast_id: str) -> bool:
    """Return True if the .m3u8 file exists (i.e. FFmpeg has started writing)."""
    return os.path.isfile(get_playlist_path(broadcast_id))


def cleanup(broadcast_id: str) -> bool:
    """
    Delete all HLS segments and the playlist for this broadcast.
    Call this after the broadcast has fully stopped.
    Returns True if the folder existed and was deleted, False otherwise.
    """
    folder = _hls_dir(broadcast_id)
    if os.path.isdir(folder):
        shutil.rmtree(folder)
        logger.info(f"[hls] Cleaned up HLS folder: {folder}")
        return True
    logger.warning(f"[hls] No folder found to clean up for '{broadcast_id}'.")
    return False


def list_active_broadcasts() -> list[str]:
    """
    Scan the HLS base dir and return broadcast IDs that have a live playlist.
    Useful for server restarts — lets you see what was left running.
    """
    base = config.HLS_OUTPUT_DIR
    if not os.path.isdir(base):
        return []

    return [
        d for d in os.listdir(base)
        if os.path.isfile(os.path.join(base, d, "stream.m3u8"))
    ]


# ──────────────────────────────────────────────────────────────
# PRIVATE
# ──────────────────────────────────────────────────────────────

def _hls_dir(broadcast_id: str) -> str:
    """Internal: absolute path to the HLS folder for a broadcast."""
    return os.path.join(config.HLS_OUTPUT_DIR, broadcast_id)
