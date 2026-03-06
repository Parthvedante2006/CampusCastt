import os
import uvicorn
import socketio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import config
from services.socket_service import sio
from services.notification_service import initialize_firebase_admin
from routes.health_routes import router as health_router
from routes.broadcast_routes import router as broadcast_router

# ──────────────────────────────────────────────────────────────
# Initialize Firebase Admin SDK
# ──────────────────────────────────────────────────────────────
initialize_firebase_admin()

# ──────────────────────────────────────────────────────────────
# FastAPI app
# ──────────────────────────────────────────────────────────────
app = FastAPI(
    title="CampusCastt Backend",
    description="Live audio streaming backend for CampusCastt",
    version="1.0.0",
)

# ── CORS ──────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────
app.include_router(health_router,    tags=["Health"])
app.include_router(broadcast_router, tags=["Broadcast"])

# ── Serve HLS files as static under /stream/<broadcast_id>/ ───
# Flutter students will hit  GET /stream/{broadcast_id}/stream.m3u8
os.makedirs(config.HLS_OUTPUT_DIR, exist_ok=True)
app.mount(
    "/stream",
    StaticFiles(directory=config.HLS_OUTPUT_DIR),
    name="hls",
)

# ──────────────────────────────────────────────────────────────
# Mount Socket.IO — wrap the FastAPI app
# Must be done AFTER all routes and mounts are registered
# ──────────────────────────────────────────────────────────────
socket_app = socketio.ASGIApp(sio, other_asgi_app=app)


# ──────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "main:socket_app",
        host=config.HOST,
        port=config.PORT,
        reload=True,
        log_level="info",
    )
