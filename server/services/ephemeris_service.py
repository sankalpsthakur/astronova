import logging
from datetime import datetime, timedelta
from threading import RLock
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)

try:
    import swisseph as swe

    SWE_AVAILABLE = True
except ImportError:
    logger.warning("Swiss Ephemeris not available. Using fallback calculations.")
    SWE_AVAILABLE = False
    swe = None

_CACHE_LOCK = RLock()
_POSITIONS_CACHE: Dict[tuple, tuple[Dict[str, Any], datetime]] = {}
_CACHE_MAX_ENTRIES = 256


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

PLANETS = {
    "sun": swe.SUN if SWE_AVAILABLE else 0,
    "moon": swe.MOON if SWE_AVAILABLE else 1,
    "mercury": swe.MERCURY if SWE_AVAILABLE else 2,
    "venus": swe.VENUS if SWE_AVAILABLE else 3,
    "mars": swe.MARS if SWE_AVAILABLE else 4,
    "jupiter": swe.JUPITER if SWE_AVAILABLE else 5,
    "saturn": swe.SATURN if SWE_AVAILABLE else 6,
    "uranus": swe.URANUS if SWE_AVAILABLE else 7,
    "neptune": swe.NEPTUNE if SWE_AVAILABLE else 8,
    "pluto": swe.PLUTO if SWE_AVAILABLE else 9,
    # Lunar nodes (north node / Rahu). Ketu is derived as the opposite point.
    "rahu": swe.TRUE_NODE if SWE_AVAILABLE else 10,
}


def _julian_day(dt: datetime) -> float:
    """Convert datetime to Julian Day."""
    if SWE_AVAILABLE:
        return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)
    else:
        # Simple Julian Day calculation for fallback
        a = (14 - dt.month) // 12
        y = dt.year + 4800 - a
        m = dt.month + 12 * a - 3
        jdn = dt.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
        return jdn + (dt.hour - 12) / 24.0 + dt.minute / 1440.0 + dt.second / 86400.0


def _compute_lahiri_ayanamsa(jd: float) -> float:
    """Return Lahiri ayanamsha (degrees) or a safe fallback."""
    if not SWE_AVAILABLE or swe is None:
        return 24.0
    try:
        swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
        if hasattr(swe, "get_ayanamsa_ut"):
            return float(swe.get_ayanamsa_ut(jd))
        if hasattr(swe, "get_ayanamsa"):
            return float(swe.get_ayanamsa(jd))
    except Exception:
        return 24.0
    return 24.0


def _calculate_rising_sign(dt: datetime, lat: float, lon: float, system: str = "western") -> Dict[str, Any]:
    """Calculate rising sign (ascendant), optionally sidereal (vedic) using Lahiri ayanamsha."""
    system = (system or "western").lower()
    use_sidereal = system in ("vedic", "sidereal", "kundali")
    if SWE_AVAILABLE:
        jd = _julian_day(dt)
        # Ascendant is returned in ascmc[0]. Prefer `houses_ex` to match Swiss Ephemeris sidereal handling.
        ascendant_lon: float
        if use_sidereal:
            try:
                swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
                _cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", swe.FLG_SIDEREAL)
                ascendant_lon = float(ascmc[0]) % 360.0
            except Exception:
                # Fallback to tropical houses + explicit ayanamsha subtraction.
                _houses, ascmc = swe.houses(jd, lat, lon, b"P")
                ascendant_lon = (float(ascmc[0]) - _compute_lahiri_ayanamsa(jd)) % 360.0
        else:
            try:
                _cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", 0)
                ascendant_lon = float(ascmc[0]) % 360.0
            except Exception:
                _houses, ascmc = swe.houses(jd, lat, lon, b"P")
                ascendant_lon = float(ascmc[0]) % 360.0
        sign_index = int(ascendant_lon // 30) % 12
        degree = ascendant_lon % 30

        sign_names = VEDIC_SIGNS if use_sidereal else ZODIAC_SIGNS
        return {"sign": sign_names[sign_index], "degree": round(degree, 2), "longitude": round(ascendant_lon, 2)}
    else:
        # Simplified fallback calculation
        # This is a very rough approximation and should not be used for serious astrology
        hour_angle = (dt.hour + dt.minute / 60.0) * 15.0  # Convert to degrees
        base_asc = (hour_angle + lon) % 360

        # Adjust for latitude (rough approximation)
        lat_factor = abs(lat) / 90.0
        adjusted_asc = (base_asc + lat_factor * 30) % 360

        if use_sidereal:
            adjusted_asc = (adjusted_asc - 24.0) % 360.0

        sign_index = int(adjusted_asc // 30) % 12
        degree = adjusted_asc % 30

        sign_names = VEDIC_SIGNS if use_sidereal else ZODIAC_SIGNS
        return {"sign": sign_names[sign_index], "degree": round(degree, 2), "longitude": round(adjusted_asc, 2)}


class EphemerisService:
    ZODIAC_SIGNS = ZODIAC_SIGNS
    VEDIC_SIGNS = VEDIC_SIGNS
    PLANETS = PLANETS

    def get_current_positions(self, lat: Optional[float] = None, lon: Optional[float] = None, system: str = "western"):
        """Get current planetary positions using Swiss Ephemeris."""
        dt = datetime.utcnow()
        return self.get_positions_for_date(dt, lat, lon, system=system)

    def get_positions_for_date(
        self, dt: datetime, lat: Optional[float] = None, lon: Optional[float] = None, system: str = "western"
    ):
        """Get planetary positions for specific date, optionally sidereal (vedic)."""
        system = (system or "western").lower()
        use_sidereal = system in ("vedic", "sidereal", "kundali")
        sign_names = VEDIC_SIGNS if use_sidereal else ZODIAC_SIGNS
        positions = {}

        cache_key = _cache_key(dt, lat, lon, system)
        cached = _get_cached_positions(cache_key)
        if cached is not None:
            return cached

        if SWE_AVAILABLE:
            jd = _julian_day(dt)
            flags = 0
            if use_sidereal:
                try:
                    swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
                    flags = swe.FLG_SIDEREAL
                except Exception:
                    flags = 0
            for name, planet_code in PLANETS.items():
                try:
                    result = swe.calc_ut(jd, planet_code, flags) if flags else swe.calc_ut(jd, planet_code)
                    # Extract longitude - result[0] is a tuple (longitude, latitude, distance, ...)
                    lon_deg = result[0][0] if isinstance(result[0], (tuple, list)) else result[0]
                    lon_deg = float(lon_deg)

                    sign_index = int(lon_deg // 30) % 12
                    degree = lon_deg % 30

                    # Extract speed for retrograde calculation
                    speed = result[0][3] if isinstance(result[0], (tuple, list)) and len(result[0]) > 3 else 1.0

                    positions[name] = {
                        "sign": sign_names[sign_index],
                        "degree": round(degree, 2),
                        "longitude": round(lon_deg, 2),
                        "retrograde": speed < 0,
                    }
                except Exception:
                    # Fallback for any calculation errors
                    positions[name] = {"sign": "Unknown", "degree": 0.0, "longitude": 0.0, "retrograde": False}
        else:
            # Fallback calculations when Swiss Ephemeris is not available
            # These are simplified approximations
            day_of_year = dt.timetuple().tm_yday
            year_progress = day_of_year / 365.25

            # Approximate positions based on average speeds
            planet_speeds = {
                "sun": 1.0,  # ~1 degree per day
                "moon": 13.2,  # ~13.2 degrees per day
                "mercury": 1.6,
                "venus": 1.2,
                "mars": 0.52,
                "jupiter": 0.08,
                "saturn": 0.03,
                "uranus": 0.01,
                "neptune": 0.006,
                "pluto": 0.004,
                # Nodes complete ~360° in ~18.6 years (~19.35°/year) and are retrograde.
                "rahu": 0.0,  # handled as a special-case below
            }

            for name in PLANETS.keys():
                # Calculate approximate position
                if name == "rahu":
                    years_since_2000 = (dt.year - 2000) + year_progress
                    base_pos = (200.0 - years_since_2000 * 19.35) % 360.0
                else:
                    base_pos = (year_progress * 360 * planet_speeds.get(name, 1.0)) % 360

                # Add some variation based on planet
                if name == "moon":
                    base_pos = (base_pos + dt.day * 13.2) % 360
                elif name == "mercury":
                    base_pos = (base_pos + dt.day * 1.6) % 360

                if use_sidereal:
                    base_pos = (base_pos - 24.0) % 360.0

                sign_index = int(base_pos // 30) % 12
                degree = base_pos % 30

                positions[name] = {
                    "sign": sign_names[sign_index],
                    "degree": round(degree, 2),
                    "longitude": round(base_pos, 2),
                    "retrograde": True if name == "rahu" else False,  # Nodes are retrograde
                }

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
                "retrograde": True,
            }

        # Add rising sign if location provided
        if lat is not None and lon is not None:
            try:
                positions["ascendant"] = _calculate_rising_sign(dt, lat, lon, system=system)
            except Exception:
                positions["ascendant"] = {"sign": "Unknown", "degree": 0.0, "longitude": 0.0}

        payload = {"planets": positions}
        _set_cached_positions(cache_key, payload, _cache_ttl_seconds(dt))
        return payload
