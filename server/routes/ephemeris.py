from datetime import datetime
from typing import Optional
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request

from errors import SwissEphemerisUnavailableError
from services.ephemeris_service import EphemerisService

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
