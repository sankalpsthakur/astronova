from __future__ import annotations

import logging
import os
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from services.redis_rate_limiter import get_rate_limiter, RateLimitExceeded as RedisRateLimitExceeded
from services.cache_service import cache

from config import Config
from routes.chat import router as chat_router
from routes.horoscope import router as horoscope_router
from routes.match import router as match_router
from routes.chart import router as chart_router
from routes.reports import router as reports_router
from routes.ephemeris import router as ephemeris_router
from routes.locations import router as locations_router
from routes.content import router as content_router
from routes.misc import router as misc_router
from services.reports_service import ReportsService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if api_key:
        app.state.reports_service = ReportsService(api_key)
    
    # Initialize Redis rate limiter
    app.state.rate_limiter = get_rate_limiter()
    yield
    # Shutdown - cleanup if needed

def create_app():
    app = FastAPI(
        title="AstroNova API",
        description="Astrological services and calculations API",
        version="1.0.0",
        lifespan=lifespan
    )
    
    # CORS configuration with environment-driven whitelist
    cors_origins = os.environ.get("CORS_ORIGINS", "*").split(",")
    cors_origins = [origin.strip() for origin in cors_origins if origin.strip()]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

    # Rate limiting
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)

    # Include routers
    app.include_router(chat_router, prefix="/api/v1/chat", tags=["chat"])
    app.include_router(horoscope_router, prefix="/api/v1/horoscope", tags=["horoscope"])
    app.include_router(match_router, prefix="/api/v1/match", tags=["match"])
    app.include_router(chart_router, prefix="/api/v1/chart", tags=["chart"])
    app.include_router(reports_router, prefix="/api/v1/reports", tags=["reports"])
    app.include_router(ephemeris_router, prefix="/api/v1/ephemeris", tags=["ephemeris"])
    app.include_router(locations_router, prefix="/api/v1/locations", tags=["locations"])
    app.include_router(content_router, prefix="/api/v1/content", tags=["content"])
    app.include_router(misc_router, prefix="/api/v1/misc", tags=["misc"])

    @app.get("/health")
    async def health():
        # Include rate limiter health check
        rate_limiter_health = app.state.rate_limiter.health_check()
        return {
            "status": "ok",
            "rate_limiter": rate_limiter_health
        }
    
    @app.exception_handler(RedisRateLimitExceeded)
    async def redis_rate_limit_handler(request, exc: RedisRateLimitExceeded):
        response = {
            "error": "Rate limit exceeded",
            "message": exc.message,
            "reset_time": exc.reset_time,
            "remaining": exc.remaining
        }
        return JSONResponse(
            status_code=429,
            content=response,
            headers={
                "X-RateLimit-Reset": str(exc.reset_time),
                "X-RateLimit-Remaining": str(exc.remaining),
                "Retry-After": str(max(0, exc.reset_time - int(time.time())))
            }
        )

    return app

app = create_app()

if __name__ == '__main__':
    import uvicorn
    debug_mode = os.environ.get("DEBUG", "False").lower() == "true"
    uvicorn.run(app, host='0.0.0.0', port=8080, reload=debug_mode)
