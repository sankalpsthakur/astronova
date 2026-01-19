import logging
from datetime import datetime, timedelta
from threading import RLock
from typing import Any, Dict, Optional

from errors import SwissEphemerisUnavailableError

logger = logging.getLogger(__name__)

try:
    import swisseph as swe

    SWE_AVAILABLE = True
except ImportError:
    logger.error("Swiss Ephemeris (pyswisseph) not available. Astrology calculations are disabled.")
    SWE_AVAILABLE = False
    swe = None

_CACHE_LOCK = RLock()
_POSITIONS_CACHE: Dict[tuple, tuple[Dict[str, Any], datetime]] = {}
_CACHE_MAX_ENTRIES = 256


def _require_swe() -> None:
    if not SWE_AVAILABLE or swe is None:
        raise SwissEphemerisUnavailableError(
            "Swiss Ephemeris (pyswisseph) is required for astrology calculations. "
            "Install it with `pip install pyswisseph`."
        )


def _cache_key(dt: datetime, lat: Optional[float], lon: Optional[float], system: str) -> tuple:
    # Bucket to minute to improve hit rate without meaningful accuracy loss.
    dt_key = dt.replace(second=0, microsecond=0)
    return (dt_key.isoformat(), lat, lon, system)


def _cache_ttl_seconds(dt: datetime) -> int:
    today = datetime.utcnow().date()
    return 300 if dt.date() == today else 86400


def _get_cached_positions(key: tuple) -> Optional[Dict[str, Any]]:
    now = datetime.utcnow()
    with _CACHE_LOCK:
        cached = _POSITIONS_CACHE.get(key)
        if not cached:
            return None
        payload, expires_at = cached
        if expires_at <= now:
            _POSITIONS_CACHE.pop(key, None)
            return None
        return payload


def _set_cached_positions(key: tuple, payload: Dict[str, Any], ttl_seconds: int) -> None:
    expires_at = datetime.utcnow() + timedelta(seconds=ttl_seconds)
    with _CACHE_LOCK:
        _POSITIONS_CACHE[key] = (payload, expires_at)
        if len(_POSITIONS_CACHE) > _CACHE_MAX_ENTRIES:
            oldest_key = min(_POSITIONS_CACHE.items(), key=lambda item: item[1][1])[0]
            _POSITIONS_CACHE.pop(oldest_key, None)

ZODIAC_SIGNS = [
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
]

# Sidereal (Vedic) sign names (Lahiri ayanamsha).
VEDIC_SIGNS = [
    "Mesha",
    "Vrishabha",
    "Mithuna",
    "Karka",
    "Simha",
    "Kanya",
    "Tula",
    "Vrischika",
    "Dhanu",
    "Makara",
    "Kumbha",
    "Meena",
]

PLANET_NAMES = (
    "sun",
    "moon",
    "mercury",
    "venus",
    "mars",
    "jupiter",
    "saturn",
    "uranus",
    "neptune",
    "pluto",
    # Lunar nodes (north node / Rahu). Ketu is derived as the opposite point.
    "rahu",
)


def _planet_codes() -> Dict[str, int]:
    _require_swe()
    # Most Vedic apps use the mean node for Rahu/Ketu.
    return {
        "sun": swe.SUN,  # type: ignore[union-attr]
        "moon": swe.MOON,  # type: ignore[union-attr]
        "mercury": swe.MERCURY,  # type: ignore[union-attr]
        "venus": swe.VENUS,  # type: ignore[union-attr]
        "mars": swe.MARS,  # type: ignore[union-attr]
        "jupiter": swe.JUPITER,  # type: ignore[union-attr]
        "saturn": swe.SATURN,  # type: ignore[union-attr]
        "uranus": swe.URANUS,  # type: ignore[union-attr]
        "neptune": swe.NEPTUNE,  # type: ignore[union-attr]
        "pluto": swe.PLUTO,  # type: ignore[union-attr]
        "rahu": swe.MEAN_NODE,  # type: ignore[union-attr]
    }


def _julian_day(dt: datetime) -> float:
    """Convert datetime to Julian Day."""
    _require_swe()
    return float(swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600))  # type: ignore[union-attr]


def _compute_lahiri_ayanamsa(jd: float) -> float:
    """Return Lahiri ayanamsha (degrees)."""
    _require_swe()
    try:
        swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)  # type: ignore[union-attr]
        if hasattr(swe, "get_ayanamsa_ut"):  # type: ignore[union-attr]
            return float(swe.get_ayanamsa_ut(jd))  # type: ignore[union-attr]
        if hasattr(swe, "get_ayanamsa"):  # type: ignore[union-attr]
            return float(swe.get_ayanamsa(jd))  # type: ignore[union-attr]
    except Exception as exc:
        raise SwissEphemerisUnavailableError(f"Swiss Ephemeris ayanamsha calculation failed: {exc}") from exc
    raise SwissEphemerisUnavailableError("Swiss Ephemeris ayanamsha calculation is unavailable in this build.")


def _calculate_rising_sign(dt: datetime, lat: float, lon: float, system: str = "western") -> Dict[str, Any]:
    """Calculate rising sign (ascendant), optionally sidereal (vedic) using Lahiri ayanamsha."""
    _require_swe()
    system = (system or "western").lower()
    use_sidereal = system in ("vedic", "sidereal", "kundali")

    jd = _julian_day(dt)
    # Ascendant is returned in ascmc[0]. Prefer `houses_ex` to match Swiss Ephemeris sidereal handling.
    ascendant_lon: float
    if use_sidereal:
        try:
            swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)  # type: ignore[union-attr]
            _cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", swe.FLG_SIDEREAL)  # type: ignore[union-attr]
            ascendant_lon = float(ascmc[0]) % 360.0
        except Exception:
            # Fallback to tropical houses + explicit ayanamsha subtraction.
            _houses, ascmc = swe.houses(jd, lat, lon, b"P")  # type: ignore[union-attr]
            ascendant_lon = (float(ascmc[0]) - _compute_lahiri_ayanamsa(jd)) % 360.0
    else:
        try:
            _cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", 0)  # type: ignore[union-attr]
            ascendant_lon = float(ascmc[0]) % 360.0
        except Exception:
            _houses, ascmc = swe.houses(jd, lat, lon, b"P")  # type: ignore[union-attr]
            ascendant_lon = float(ascmc[0]) % 360.0
    sign_index = int(ascendant_lon // 30) % 12
    degree = ascendant_lon % 30

    sign_names = VEDIC_SIGNS if use_sidereal else ZODIAC_SIGNS
    return {"sign": sign_names[sign_index], "degree": round(degree, 2), "longitude": round(ascendant_lon, 2)}


class EphemerisService:
    ZODIAC_SIGNS = ZODIAC_SIGNS
    VEDIC_SIGNS = VEDIC_SIGNS
    PLANETS = PLANET_NAMES

    def get_current_positions(self, lat: Optional[float] = None, lon: Optional[float] = None, system: str = "western"):
        """Get current planetary positions using Swiss Ephemeris."""
        _require_swe()
        dt = datetime.utcnow()
        return self.get_positions_for_date(dt, lat, lon, system=system)

    def get_positions_for_date(
        self, dt: datetime, lat: Optional[float] = None, lon: Optional[float] = None, system: str = "western"
    ):
        """Get planetary positions for specific date, optionally sidereal (vedic)."""
        _require_swe()
        system = (system or "western").lower()
        use_sidereal = system in ("vedic", "sidereal", "kundali")
        sign_names = VEDIC_SIGNS if use_sidereal else ZODIAC_SIGNS
        positions = {}

        cache_key = _cache_key(dt, lat, lon, system)
        cached = _get_cached_positions(cache_key)
        if cached is not None:
            return cached

        jd = _julian_day(dt)
        ayanamsha: float | None = None

        flags = 0
        try:
            flags |= int(getattr(swe, "FLG_SWIEPH", 0))  # type: ignore[union-attr]
            flags |= int(getattr(swe, "FLG_SPEED", 0))  # type: ignore[union-attr]
        except Exception:
            flags = 0

        if use_sidereal:
            try:
                swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)  # type: ignore[union-attr]
                flags |= int(swe.FLG_SIDEREAL)  # type: ignore[union-attr]
                ayanamsha = round(_compute_lahiri_ayanamsa(jd), 6)
            except Exception as exc:
                raise SwissEphemerisUnavailableError(f"Swiss Ephemeris sidereal mode init failed: {exc}") from exc

        for name, planet_code in _planet_codes().items():
            try:
                xx, _ = swe.calc_ut(jd, planet_code, flags)  # type: ignore[union-attr]
                lon_deg = float(xx[0]) % 360.0
                speed = float(xx[3]) if len(xx) > 3 else 0.0

                sign_index = int(lon_deg // 30) % 12
                degree = lon_deg % 30

                positions[name] = {
                    "sign": sign_names[sign_index],
                    "degree": round(degree, 2),
                    "longitude": round(lon_deg, 2),
                    "speed": round(speed, 4),
                    "retrograde": speed < 0,
                }
            except Exception as exc:
                raise SwissEphemerisUnavailableError(f"Swiss Ephemeris calculation failed for {name}: {exc}") from exc

        # Derive Ketu as the opposite node.
        if "rahu" in positions and "ketu" not in positions:
            try:
                rahu_lon = float(positions["rahu"].get("longitude", 0.0))
            except Exception:
                rahu_lon = 0.0
            ketu_lon = (rahu_lon + 180.0) % 360.0
            sign_index = int(ketu_lon // 30) % 12
            degree = ketu_lon % 30
            positions["ketu"] = {
                "sign": sign_names[sign_index],
                "degree": round(degree, 2),
                "longitude": round(ketu_lon, 2),
                "speed": positions["rahu"].get("speed", 0.0),
                "retrograde": True,
            }

        # Add rising sign if location provided
        if lat is not None and lon is not None:
            try:
                positions["ascendant"] = _calculate_rising_sign(dt, lat, lon, system=system)
            except Exception as exc:
                raise SwissEphemerisUnavailableError(f"Swiss Ephemeris ascendant calculation failed: {exc}") from exc

        payload = {"planets": positions, "ayanamsha": ayanamsha} if use_sidereal else {"planets": positions}
        _set_cached_positions(cache_key, payload, _cache_ttl_seconds(dt))
        return payload
