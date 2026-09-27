from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import analysis_service, router
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("revalue")

app = FastAPI(
    title="ReValue API",
    version="0.1.0",
    description="AI analysis backend for the ReValue recovery platform.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://10.0.2.2:8000",
        "http://localhost",
        "http://127.0.0.1",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_event() -> None:
    logger.info("SERVER STARTED")
    logger.info("Vision model will initialize on the first analysis request.")


@app.get("/api/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "model_loaded": analysis_service.model_loaded,
        "vision_provider": settings.vision_provider,
        "service": "ReValue API",
        "host": settings.api_host,
        "port": settings.api_port,
    }


app.include_router(router)
