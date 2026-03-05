import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    # ── Server ──────────────────────────────────────────────
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", 8000))

    # ── HLS ─────────────────────────────────────────────────
    # Base folder where HLS segments & playlists are written
    HLS_OUTPUT_DIR: str = os.getenv("HLS_OUTPUT_DIR", "/tmp/hls")

    # Duration of each .ts segment in seconds
    HLS_SEGMENT_TIME: int = int(os.getenv("HLS_SEGMENT_TIME", 2))

    # How many segments to keep in the playlist (rolling window)
    HLS_LIST_SIZE: int = int(os.getenv("HLS_LIST_SIZE", 5))

    # ── FFmpeg ───────────────────────────────────────────────
    FFMPEG_PATH: str = os.getenv("FFMPEG_PATH", "ffmpeg")

    # ── CORS ─────────────────────────────────────────────────
    # Add your ngrok URL here once it's running
    ALLOWED_ORIGINS: list = [
        "*",  # ← open during development; lock down in production
    ]


# Single shared instance — import this everywhere
config = Config()
