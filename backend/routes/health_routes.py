from fastapi import APIRouter
import services.ffmpeg_service as ffmpeg_service

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Basic health check — confirms the server is running.
    Open http://localhost:8000/health to verify.
    """
    return {
        "status": "ok",
        "message": "CampusCast server running",
        "ffmpeg_available": ffmpeg_service.is_broadcast_active.__module__ is not None,
        "active_broadcasts": ffmpeg_service.get_active_broadcasts(),
    }
