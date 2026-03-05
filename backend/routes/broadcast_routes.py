from fastapi import APIRouter, HTTPException, Request
import services.hls_service as hls_service
import services.ffmpeg_service as ffmpeg_service

router = APIRouter()


@router.get("/broadcast/{broadcast_id}/url")
async def get_stream_url(broadcast_id: str, request: Request):
    """
    Return the HLS stream URL for a given broadcast ID.

    Returns the URL as long as:
    - FFmpeg is actively running for this broadcast, OR
    - The HLS playlist already exists on disk.

    This avoids a race condition where Flutter fetches the URL immediately
    after broadcast_start, before FFmpeg has written its first segment.
    """
    ffmpeg_running   = ffmpeg_service.is_broadcast_active(broadcast_id)
    playlist_exists  = hls_service.playlist_exists(broadcast_id)

    if not ffmpeg_running and not playlist_exists:
        raise HTTPException(
            status_code=404,
            detail=f"No active stream found for broadcast_id '{broadcast_id}'.",
        )

    # Build the URL from the incoming request so ngrok URLs work automatically
    host       = str(request.base_url).rstrip("/")
    stream_url = hls_service.get_stream_url(broadcast_id, host)

    return {
        "broadcast_id":   broadcast_id,
        "stream_url":     stream_url,
        "ffmpeg_running": ffmpeg_running,
        "playlist_ready": playlist_exists,
    }


@router.get("/broadcast/active")
async def list_active_broadcasts():
    """List all broadcast IDs that currently have an HLS playlist on disk."""
    return {
        "active_broadcasts": hls_service.list_active_broadcasts(),
    }
