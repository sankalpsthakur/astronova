"""Expose API routers for FastAPI app initialization."""

from .chat import router as chat_router
from .horoscope import router as horoscope_router
from .match import router as match_router
from .chart import router as chart_router
from .reports import router as reports_router
from .ephemeris import router as ephemeris_router
from .locations import router as locations_router
from .misc import router as misc_router

__all__ = [
    "chat_router",
    "horoscope_router",
    "match_router",
    "chart_router",
    "reports_router",
    "ephemeris_router",
    "locations_router",
    "misc_router",
]

