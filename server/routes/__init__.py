from .astrology import astrology_bp
from .auth import auth_bp
from .chart import chart_bp
from .chat import chat_bp
from .compatibility import compat_bp
from .content import content_bp
from .discover import discover_bp
from .ephemeris import ephemeris_bp
from .horoscope import horoscope_bp
from .locations import locations_bp
from .misc import misc_bp
from .reports import reports_bp
from .temple import temple_bp

__all__ = [
    "astrology_bp",
    "auth_bp",
    "chart_bp",
    "chat_bp",
    "compat_bp",
    "content_bp",
    "discover_bp",
    "ephemeris_bp",
    "horoscope_bp",
    "locations_bp",
    "misc_bp",
    "reports_bp",
    "temple_bp",
]
