from datetime import datetime, timedelta, timezone
from typing import Optional
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request

from errors import SwissEphemerisUnavailableError
from services.ephemeris_service import EphemerisService

try:  # Swiss Ephemeris is required at runtime but the import can be deferred.
    import swisseph as _swe  # type: ignore
except Exception:  # pragma: no cover - graceful fallback for environments without swisseph
    _swe = None

ephemeris_bp = Blueprint("ephemeris", __name__)
service = EphemerisService()


@ephemeris_bp.route("", methods=["GET"])
def ephemeris_info():
    """Get ephemeris service information"""
    return jsonify(
        {"service": "ephemeris", "status": "available", "endpoints": {"GET /current": "Get current planetary positions"}}
    )


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


def _compute_positions(dt: datetime, lat: Optional[float], lon: Optional[float], system: str = "western"):
    """Compute planetary positions, optionally in sidereal (vedic/kundali) mode."""
    system = (system or "western").lower()
    if system == "tropical":
        system = "western"
    if system in ("sidereal", "kundali"):
        system = "vedic"

    return service.get_positions_for_date(dt, lat, lon, system=system).get("planets", {})


@ephemeris_bp.route("/current", methods=["GET"])
def current_positions():
    """
    Get current planetary positions for iOS app.
    Optional query parameters:
    - lat: latitude for rising sign calculation
    - lon: longitude for rising sign calculation
    """
    try:
        # Get optional location parameters for rising sign
        lat = request.args.get("lat", type=float)
        lon = request.args.get("lon", type=float)
        system = (request.args.get("system") or "western").lower()
        positions = _compute_positions(datetime.utcnow(), lat, lon, system)

        # Transform data for iOS app format
        planets = []
        for planet_name, planet_data in positions.items():
            planet_entry = {
                "id": planet_name.lower(),
                "symbol": get_planet_symbol(planet_name),
                "name": planet_name.title(),
                "sign": planet_data.get("sign", "Unknown"),
                "degree": planet_data.get("degree", 0.0),
                "retrograde": planet_data.get("retrograde", False),
                "house": planet_data.get("house"),
                "significance": get_planet_significance(planet_name),
            }
            planets.append(planet_entry)

        return jsonify(
            {
                "planets": planets,
                "timestamp": datetime.now().isoformat(),
                "has_rising_sign": lat is not None and lon is not None,
            }
        )

    except SwissEphemerisUnavailableError:
        raise
    except Exception as e:
        return jsonify({"error": f"Failed to get current positions: {str(e)}"}), 500


@ephemeris_bp.route("/at", methods=["GET"])
def positions_at_date():
    """
    Get planetary positions for a specific instant.
    Query parameters:
    - date: YYYY-MM-DD (required)
    - time: HH:MM (optional; defaults to 00:00)
    - tz: IANA timezone (optional; if provided, date/time are interpreted in this timezone)
    - lat: optional latitude
    - lon: optional longitude
    """
    try:
        date_str = request.args.get("date")
        if not date_str:
            return jsonify({"error": "date parameter required (YYYY-MM-DD)"}), 400

        time_str = request.args.get("time")
        tz_str = request.args.get("tz")

        try:
            if time_str:
                dt_local = datetime.strptime(f"{date_str}T{time_str}", "%Y-%m-%dT%H:%M")
            else:
                dt_local = datetime.strptime(f"{date_str}T00:00", "%Y-%m-%dT%H:%M")
        except ValueError:
            return jsonify({"error": "Invalid date/time format, use YYYY-MM-DD and optional HH:MM"}), 400

        if tz_str:
            try:
                tz = ZoneInfo(tz_str)
            except Exception:
                return jsonify({"error": "Invalid tz; expected IANA timezone"}), 400
            dt = dt_local.replace(tzinfo=tz).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
        else:
            # Backward-compatible: interpret as UTC day/time.
            dt = dt_local

        lat = request.args.get("lat", type=float)
        lon = request.args.get("lon", type=float)
        system = (request.args.get("system") or "western").lower()

        positions = _compute_positions(dt, lat, lon, system)

        planets = []
        for planet_name, planet_data in positions.items():
            planet_entry = {
                "id": planet_name.lower(),
                "symbol": get_planet_symbol(planet_name),
                "name": planet_name.title(),
                "sign": planet_data.get("sign", "Unknown"),
                "degree": planet_data.get("degree", 0.0),
                "retrograde": planet_data.get("retrograde", False),
                "house": planet_data.get("house"),
                "significance": get_planet_significance(planet_name),
            }
            planets.append(planet_entry)

        return jsonify(
            {"planets": planets, "timestamp": dt.isoformat(), "has_rising_sign": lat is not None and lon is not None}
        )

    except SwissEphemerisUnavailableError:
        raise
    except Exception as e:
        return jsonify({"error": f"Failed to get positions: {str(e)}"}), 500


# ── Topo terrain substitutions ───────────────────────────────────────────────
#
# Replaces the iOS-side `TerrainComputer.substitute` pseudo-random stubs with
# real Swiss-Ephemeris-derived values so the Today screen reads transit-true:
#
#   {void_end_time}         — moment the Moon next changes sign (ISO 8601 UTC
#                              + a pre-formatted localized clock time).
#   {aspect_partner}        — planet making the tightest major aspect to Moon.
#   {aspect_type} / _angle  — that aspect's classical name + angle.
#   {eclipse_distance_days} — calendar days to the next solar eclipse.
#
# Cached per UTC day server-side via the ephemeris_service positions cache.

_MAJOR_ASPECTS = [
    ("conjunction", 0.0, 8.0),
    ("sextile", 60.0, 6.0),
    ("square", 90.0, 8.0),
    ("trine", 120.0, 8.0),
    ("opposition", 180.0, 8.0),
]
# Planets eligible to play the "aspect_partner" role. Outer luminaries excluded
# so the Today copy stays grounded in personally-relevant transits.
_ASPECT_BODIES = ["sun", "mercury", "venus", "mars", "jupiter", "saturn"]


def _shortest_arc(a: float, b: float) -> float:
    """Smallest absolute angular distance between two zodiac longitudes."""
    diff = abs(a - b) % 360.0
    return diff if diff <= 180.0 else 360.0 - diff


def _moon_next_sign_change(now: datetime) -> datetime:
    """Project forward from `now` to the moment the Moon enters its next sign.

    Uses Moon's longitude + speed at `now` for a linear projection, then
    refines with two Newton-style steps so we land within seconds of the
    exact crossing. Far cheaper than scanning minute-by-minute.
    """
    if _swe is None:
        raise SwissEphemerisUnavailableError("swisseph not available")

    flags = _swe.FLG_SWIEPH | _swe.FLG_SPEED  # type: ignore[union-attr]

    def lon_speed(at: datetime) -> tuple[float, float]:
        jd = _swe.julday(at.year, at.month, at.day,  # type: ignore[union-attr]
                         at.hour + at.minute / 60.0 + at.second / 3600.0)
        xx, _ = _swe.calc_ut(jd, _swe.MOON, flags)  # type: ignore[union-attr]
        return float(xx[0]) % 360.0, float(xx[3])

    moon_lon, moon_speed = lon_speed(now)
    if moon_speed <= 0:
        # Defensive — Moon's mean speed is always positive (12-15 °/day), but if
        # ephemeris reports zero/negative we just project a conservative 24h.
        return now + timedelta(hours=24)

    current_sign_idx = int(moon_lon // 30.0)
    next_boundary = float((current_sign_idx + 1) * 30) % 360.0  # 0 if last sign
    deg_to_go = (next_boundary - moon_lon) % 360.0
    eta_hours = (deg_to_go / moon_speed) * 24.0
    candidate = now + timedelta(hours=eta_hours)

    # Two Newton refinements — typically converges in 1 step but 2 gives margin.
    for _ in range(2):
        clon, cspeed = lon_speed(candidate)
        if cspeed <= 0:
            break
        # How far off the actual boundary are we?
        diff = (next_boundary - clon) % 360.0
        if diff > 180.0:
            diff -= 360.0
        candidate += timedelta(hours=(diff / cspeed) * 24.0)
    return candidate


def _moon_dominant_aspect(now: datetime) -> Optional[dict]:
    """Return a dict {partner, type, angle, orb} for the tightest major aspect
    Moon currently makes to any of `_ASPECT_BODIES`, or None if all orbs exceed
    the aspect's tolerance.
    """
    if _swe is None:
        raise SwissEphemerisUnavailableError("swisseph not available")

    jd = _swe.julday(now.year, now.month, now.day,  # type: ignore[union-attr]
                     now.hour + now.minute / 60.0)
    flags = _swe.FLG_SWIEPH  # type: ignore[union-attr]
    xx, _ = _swe.calc_ut(jd, _swe.MOON, flags)  # type: ignore[union-attr]
    moon_lon = float(xx[0]) % 360.0

    planet_codes = {
        "sun": _swe.SUN, "mercury": _swe.MERCURY, "venus": _swe.VENUS,  # type: ignore[union-attr]
        "mars": _swe.MARS, "jupiter": _swe.JUPITER, "saturn": _swe.SATURN,  # type: ignore[union-attr]
    }

    best = None
    for pname in _ASPECT_BODIES:
        code = planet_codes.get(pname)
        if code is None:
            continue
        xx, _ = _swe.calc_ut(jd, code, flags)  # type: ignore[union-attr]
        plon = float(xx[0]) % 360.0
        arc = _shortest_arc(moon_lon, plon)
        for aspect_name, angle, max_orb in _MAJOR_ASPECTS:
            orb = abs(arc - angle)
            if orb <= max_orb and (best is None or orb < best["orb"]):
                best = {
                    "partner": pname.title(),
                    "type": aspect_name,
                    "angle": f"{int(angle)}°",
                    "orb": round(orb, 2),
                }
    return best


def _days_to_next_solar_eclipse(now: datetime) -> int:
    """Days from `now` to the next global solar eclipse, computed via Swiss
    Ephemeris' sol_eclipse_when_glob. Returns 0 if the calculation fails."""
    if _swe is None:
        raise SwissEphemerisUnavailableError("swisseph not available")
    jd = _swe.julday(now.year, now.month, now.day,  # type: ignore[union-attr]
                     now.hour + now.minute / 60.0)
    try:
        retflag, tret = _swe.sol_eclipse_when_glob(jd, _swe.FLG_SWIEPH, 0)  # type: ignore[union-attr]
        eclipse_jd = float(tret[0])
        days = max(0, int(round(eclipse_jd - jd)))
        return days
    except Exception:  # pragma: no cover
        return 0


# Per-UTC-day cache. The substitutions response is identical for every
# requester on a given calendar day, so we compute once per day and serve
# the cached payload for the rest of the day. Drops cold-path latency from
# ~50 ms (Swiss-Ephemeris + eclipse search) to a dict lookup.
_TOPO_SUBSTITUTIONS_CACHE: dict[str, dict] = {}


@ephemeris_bp.route("/topo-substitutions", methods=["GET"])
def topo_substitutions():
    """Return real ephemeris-derived values for Today-screen template tokens.

    These were previously computed iOS-side as deterministic pseudo-random
    stubs (day-of-year modulo arithmetic). The iOS client now calls this once
    per UTC day and caches the response. See client/AstronovaApp/Features
    /Topo/Services/TopoEngine.swift `substitute(_:dashaLord:)` for the
    consumer.

    Response schema:
      void_end_time_iso   ISO 8601 UTC string for next Moon sign change.
      void_end_time       Pre-formatted 12h clock time ("7:27 PM") in UTC —
                          the iOS client SHOULD reformat in the user's locale
                          if it has the user's timezone, but this lets
                          web/embeds render the value directly.
      aspect_partner      Title-cased planet name, or empty if no aspect.
      aspect_type         "conjunction" | "sextile" | "square" | "trine"
                          | "opposition" | "" .
      aspect_angle        "0°" | "60°" | "90°" | "120°" | "180°" | "" .
      aspect_orb_degrees  Numeric orb (lower = tighter).
      eclipse_distance_days  Integer days to next solar eclipse.
      computed_at_iso     Server timestamp.
    """
    try:
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        day_key = now.strftime("%Y-%m-%d")

        # Serve the cached payload if today's slot is warm.
        if (cached := _TOPO_SUBSTITUTIONS_CACHE.get(day_key)) is not None:
            return jsonify(cached)

        # Moon void end time.
        void_end_dt = _moon_next_sign_change(now)
        void_end_iso = void_end_dt.replace(microsecond=0).isoformat() + "Z"
        h12 = void_end_dt.hour % 12 or 12
        ampm = "PM" if void_end_dt.hour >= 12 else "AM"
        void_end_clock = f"{h12}:{void_end_dt.minute:02d} {ampm}"

        # Dominant moon aspect (may be None if no major aspect within orb).
        aspect = _moon_dominant_aspect(now)
        if aspect is None:
            aspect_partner = ""
            aspect_type = ""
            aspect_angle = ""
            aspect_orb = 0.0
        else:
            aspect_partner = aspect["partner"]
            aspect_type = aspect["type"]
            aspect_angle = aspect["angle"]
            aspect_orb = aspect["orb"]

        eclipse_days = _days_to_next_solar_eclipse(now)

        payload = {
            "void_end_time_iso": void_end_iso,
            "void_end_time": void_end_clock,
            "aspect_partner": aspect_partner,
            "aspect_type": aspect_type,
            "aspect_angle": aspect_angle,
            "aspect_orb_degrees": aspect_orb,
            "eclipse_distance_days": eclipse_days,
            "computed_at_iso": now.replace(microsecond=0).isoformat() + "Z",
        }

        # Cache for the rest of the UTC day. Trim older entries so the dict
        # stays small (at most ~2 entries during a day rollover).
        _TOPO_SUBSTITUTIONS_CACHE[day_key] = payload
        for stale in [k for k in _TOPO_SUBSTITUTIONS_CACHE if k != day_key]:
            _TOPO_SUBSTITUTIONS_CACHE.pop(stale, None)

        return jsonify(payload)

    except SwissEphemerisUnavailableError as exc:
        return jsonify({"error": str(exc), "code": "EPHEMERIS_UNAVAILABLE"}), 503
    except Exception as exc:
        return jsonify({"error": f"Failed to compute topo substitutions: {exc}"}), 500


def get_planet_symbol(planet_name: str) -> str:
    """Get the symbol for a planet"""
    symbols = {
        "sun": "☉",
        "moon": "☽",
        "mercury": "☿",
        "venus": "♀",
        "mars": "♂",
        "jupiter": "♃",
        "saturn": "♄",
        "uranus": "♅",
        "neptune": "♆",
        "pluto": "♇",
        "ascendant": "⟰",
        "rahu": "☊",
        "ketu": "☋",
    }
    return symbols.get(planet_name.lower(), "⭐")


def get_planet_significance(planet_name: str) -> str:
    """Get the significance description for a planet"""
    significance = {
        "sun": "Core identity and vitality",
        "moon": "Emotions and intuition",
        "mercury": "Communication and thinking",
        "venus": "Love and values",
        "mars": "Energy and action",
        "jupiter": "Growth and wisdom",
        "saturn": "Structure and discipline",
        "uranus": "Innovation and change",
        "neptune": "Dreams and spirituality",
        "pluto": "Transformation and power",
        "ascendant": "Rising sign and outer personality",
        "rahu": "Ambition, desire, and worldly expansion",
        "ketu": "Detachment, insight, and spiritual release",
    }
    return significance.get(planet_name.lower(), "Cosmic influence")
