from __future__ import annotations

import uuid
from datetime import datetime

from flask import Blueprint, jsonify, request

from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService
from utils.birth_data import parse_birth_data, BirthDataError

chart_bp = Blueprint("chart", __name__)
_ephem = EphemerisService()
_dasha = DashaService()

# OpenAPI parity: service-info endpoint.
@chart_bp.route("", methods=["GET"])
def chart_info():
    return jsonify(
        {
            "service": "chart",
            "status": "available",
            "endpoints": {
                "POST /generate": "Generate natal chart (western/vedic/chinese)",
                "POST /aspects": "Compute aspects from chart longitudes",
                "GET /aspects?date=YYYY-MM-DD": "Compute aspects for a date (UTC)",
            },
        }
    )

# Minimal house meaning payloads used by both Western and Vedic charts.
HOUSE_MEANINGS = {
    1: "Self, body, vitality, identity, beginnings (Lagna).",
    2: "Wealth, speech, family, values, sustenance.",
    3: "Courage, effort, communication, siblings, skills.",
    4: "Home, mother, foundations, comfort, inner peace.",
    5: "Creativity, education, children, intelligence, romance.",
    6: "Health, service, debts, obstacles, daily routines.",
    7: "Partnership, marriage, contracts, public interactions.",
    8: "Transformation, longevity, secrets, shared resources.",
    9: "Dharma, luck, higher learning, mentors, long journeys.",
    10: "Career, status, actions, responsibility, reputation.",
    11: "Gains, networks, aspirations, friends, fulfillment.",
    12: "Release, spirituality, loss, foreign lands, rest.",
}

WESTERN_SIGN_RULERS = {
    "Aries": "Mars",
    "Taurus": "Venus",
    "Gemini": "Mercury",
    "Cancer": "Moon",
    "Leo": "Sun",
    "Virgo": "Mercury",
    "Libra": "Venus",
    "Scorpio": "Mars",
    "Sagittarius": "Jupiter",
    "Capricorn": "Saturn",
    "Aquarius": "Saturn",
    "Pisces": "Jupiter",
}

VEDIC_SIGN_RULERS = {
    "Mesha": "Mars",
    "Vrishabha": "Venus",
    "Mithuna": "Mercury",
    "Karka": "Moon",
    "Simha": "Sun",
    "Kanya": "Mercury",
    "Tula": "Venus",
    "Vrischika": "Mars",
    "Dhanu": "Jupiter",
    "Makara": "Saturn",
    "Kumbha": "Saturn",
    "Meena": "Jupiter",
}


def _parse_birth_payload(data: dict) -> tuple[datetime, float, float, str]:
    """Parse birth payload using shared utility."""
    try:
        return parse_birth_data(data, key="birthData", require_coords=True, include_timezone=True)
    except BirthDataError as e:
        raise ValueError(str(e))


def _normalize_system_name(value: str) -> str | None:
    normalized = (value or "").strip().lower()
    if normalized in ("western", "tropical"):
        return "western"
    if normalized in ("vedic", "sidereal", "kundali"):
        return "vedic"
    if normalized == "chinese":
        return "chinese"
    return None


def _normalize_systems(raw_systems: object) -> list[str]:
    if raw_systems is None:
        return ["western"]
    if isinstance(raw_systems, str):
        raw_systems = [raw_systems]
    if not isinstance(raw_systems, list):
        return ["western"]

    systems: list[str] = []
    for entry in raw_systems:
        if not isinstance(entry, str):
            continue
        system = _normalize_system_name(entry)
        if system and system not in systems:
            systems.append(system)
    return systems or ["western"]


def _positions_to_chart_system(positions: dict) -> dict:
    # positions: { 'planets': { name: { sign, degree, ... } } }
    result: dict[str, dict] = {}
    for name, info in positions.get("planets", {}).items():
        key = str(name).lower()
        result[key] = {"degree": float(info.get("degree", 0.0)), "sign": str(info.get("sign", "Unknown"))}
    return result


def _safe_sign_index(sign: str, sign_names: list[str]) -> int | None:
    try:
        return sign_names.index(sign)
    except ValueError:
        return None


def _build_whole_sign_houses(
    lagna_sign: str,
    sign_names: list[str],
    include_meanings: bool = True,
    *,
    sign_rulers: dict[str, str] | None = None,
    house_planets: dict[int, list[str]] | None = None,
) -> dict[str, dict]:
    lagna_index = _safe_sign_index(lagna_sign, sign_names)
    if lagna_index is None:
        lagna_index = 0

    houses: dict[str, dict] = {}
    for offset in range(12):
        house_num = offset + 1
        sign = sign_names[(lagna_index + offset) % 12]
        house_payload: dict[str, object] = {"sign": sign, "degree": 0.0}
        if include_meanings:
            house_payload["meaning"] = HOUSE_MEANINGS.get(house_num, "")
        if sign_rulers:
            house_payload["lord"] = sign_rulers.get(sign)
        if house_planets is not None:
            planets = house_planets.get(house_num, [])
            house_payload["planets"] = planets
            if planets:
                house_payload["influence"] = f"Planets placed here: {', '.join(p.title() for p in planets)}."
            else:
                house_payload["influence"] = "No major planets placed here (whole sign)."
        houses[str(house_num)] = house_payload
    return houses


def _compute_aspects(lon_map: dict[str, float], orb: float = 6.0) -> list[dict]:
    aspects = {
        "conjunction": 0,
        "sextile": 60,
        "square": 90,
        "trine": 120,
        "opposition": 180,
    }
    planets = list(lon_map.keys())
    results: list[dict] = []
    for i in range(len(planets)):
        for j in range(i + 1, len(planets)):
            p1, p2 = planets[i], planets[j]
            lon1, lon2 = lon_map[p1], lon_map[p2]
            diff = abs((lon1 - lon2 + 180) % 360 - 180)
            for name, angle in aspects.items():
                delta = abs(diff - angle)
                if delta <= orb:
                    results.append(
                        {"planet1": p1, "planet2": p2, "type": name, "aspect": name, "orb": round(delta, 2)}
                    )
    return results


@chart_bp.route("/generate", methods=["POST"])
def generate_chart():
    payload = request.get_json(silent=True)
    if not payload:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    try:
        dt, lat, lon, tz = _parse_birth_payload(payload)
    except ValueError as e:
        return jsonify({"error": str(e), "code": "VALIDATION_ERROR"}), 400
    except Exception as e:
        import logging

        logging.error(f"Unexpected error in chart generation: {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "code": "INTERNAL_ERROR"}), 500

    systems = _normalize_systems(payload.get("systems"))
    chart_type = payload.get("chartType", "natal")

    charts: dict[str, dict] = {}
    western_chart_payload: dict | None = None
    vedic_chart_payload: dict | None = None

    if "western" in systems:
        western = _ephem.get_positions_for_date(dt, lat, lon, system="western")
        western_positions = _positions_to_chart_system(western)

        asc_sign = str(western.get("planets", {}).get("ascendant", {}).get("sign", "Aries"))
        sign_names = list(EphemerisService.ZODIAC_SIGNS)
        houses = _build_whole_sign_houses(
            asc_sign,
            sign_names,
            include_meanings=False,
            sign_rulers=WESTERN_SIGN_RULERS,
        )

        asc_index = _safe_sign_index(asc_sign, sign_names)
        if asc_index is None:
            asc_index = 0

        def house_for_sign(sign: str) -> int:
            idx = _safe_sign_index(sign, sign_names)
            if idx is None:
                return 0
            return ((idx - asc_index) % 12) + 1

        positions_full: dict[str, dict] = {}
        for planet, info in western.get("planets", {}).items():
            sign = str(info.get("sign", "Unknown"))
            positions_full[str(planet).lower()] = {
                "sign": sign,
                "degree": float(info.get("degree", 0.0)),
                "house": 1 if str(planet).lower() == "ascendant" else house_for_sign(sign),
            }

        lon_map = {
            str(name).lower(): float(info.get("longitude"))
            for name, info in western.get("planets", {}).items()
            if name != "ascendant" and "longitude" in info
        }
        aspects = _compute_aspects(lon_map)

        charts["western"] = {"positions": western_positions, "svg": ""}
        western_chart_payload = {"positions": positions_full, "houses": houses, "aspects": aspects}

    if "vedic" in systems:
        vedic = _ephem.get_positions_for_date(dt, lat, lon, system="vedic")
        vedic_positions = _positions_to_chart_system(vedic)

        lagna_sign = str(vedic.get("planets", {}).get("ascendant", {}).get("sign", EphemerisService.VEDIC_SIGNS[0]))
        sign_names = list(EphemerisService.VEDIC_SIGNS)

        lagna_index = _safe_sign_index(lagna_sign, sign_names)
        if lagna_index is None:
            lagna_index = 0

        def house_for_sign(sign: str) -> int:
            idx = _safe_sign_index(sign, sign_names)
            if idx is None:
                return 0
            return ((idx - lagna_index) % 12) + 1

        positions_full: dict[str, dict] = {}
        for planet, info in vedic.get("planets", {}).items():
            sign = str(info.get("sign", "Unknown"))
            positions_full[str(planet).lower()] = {
                "sign": sign,
                "degree": float(info.get("degree", 0.0)),
                "house": 1 if str(planet).lower() == "ascendant" else house_for_sign(sign),
            }

        house_planets: dict[int, list[str]] = {i: [] for i in range(1, 13)}
        for planet_name, pos in positions_full.items():
            if planet_name == "ascendant":
                continue
            house = int(pos.get("house") or 0)
            if 1 <= house <= 12:
                house_planets[house].append(planet_name)

        houses = _build_whole_sign_houses(
            lagna_sign,
            sign_names,
            include_meanings=True,
            sign_rulers=VEDIC_SIGN_RULERS,
            house_planets=house_planets,
        )

        dashas: list[dict] = []
        try:
            moon_longitude = float(vedic.get("planets", {}).get("moon", {}).get("longitude", 0.0))
            dasha_info = _dasha.calculate_complete_dasha(
                birth_date=dt,
                moon_longitude=moon_longitude,
                target_date=datetime.utcnow(),
                include_future=True,
                num_future_periods=5,
            )
            if dasha_info and dasha_info.get("mahadasha"):
                current = dasha_info["mahadasha"]
                dashas.append({"planet": current.get("lord"), "startDate": current.get("start"), "endDate": current.get("end")})
                for upcoming in dasha_info.get("upcoming_mahadashas", []) or []:
                    dashas.append(
                        {"planet": upcoming.get("lord"), "startDate": upcoming.get("start"), "endDate": upcoming.get("end")}
                    )
        except Exception:
            dashas = []

        charts["vedic"] = {"positions": vedic_positions, "svg": ""}
        lagna = vedic.get("planets", {}).get("ascendant")
        if isinstance(lagna, dict) and "sign" in lagna:
            lagna = dict(lagna)
            lagna["lord"] = VEDIC_SIGN_RULERS.get(str(lagna.get("sign")))
            lagna["meaning"] = HOUSE_MEANINGS.get(1, "")
        vedic_chart_payload = {
            "lagna": lagna,
            "positions": positions_full,
            "houses": houses,
            "dashas": dashas,
        }

    resp = {
        "chartId": str(uuid.uuid4()),
        "charts": charts or {"western": {"positions": {}, "svg": ""}},
        "type": chart_type,
        "westernChart": western_chart_payload,
        "vedicChart": vedic_chart_payload,
        "chineseChart": None,
        "disclaimer": "For entertainment purposes only. Not professional advice.",
    }
    return jsonify(resp)


@chart_bp.route("/aspects", methods=["POST"])
def chart_aspects():
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    # Prefer birthData if present, otherwise use current time
    try:
        if payload and ("birthData" in payload or "date" in payload):
            dt, lat, lon, tz = _parse_birth_payload(payload)
        else:
            # Use current time if no birth data provided (empty {} or no keys)
            dt, lat, lon, _tz = datetime.utcnow(), None, None, "UTC"  # type: ignore[assignment]
    except ValueError as e:
        return jsonify({"error": str(e), "code": "VALIDATION_ERROR"}), 400
    except Exception as e:
        import logging

        logging.error(f"Unexpected error in aspects calculation: {e}", exc_info=True)
        return jsonify({"error": "Internal server error", "code": "INTERNAL_ERROR"}), 500

    positions = _ephem.get_positions_for_date(dt, lat, lon)
    lon_map = {}
    for name, info in positions.get("planets", {}).items():
        if "longitude" in info:
            lon_map[name] = float(info["longitude"])
    aspects = _compute_aspects(lon_map)
    return jsonify(aspects)


@chart_bp.route("/aspects", methods=["GET"])
def chart_aspects_by_date():
    from datetime import datetime as _dt

    date_str = request.args.get("date")
    if not date_str:
        return jsonify({"error": "date parameter required (YYYY-MM-DD)"}), 400
    try:
        dt = _dt.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400
    positions = _ephem.get_positions_for_date(dt)
    lon_map = {name: float(info.get("longitude", 0.0)) for name, info in positions.get("planets", {}).items()}
    aspects = _compute_aspects(lon_map)
    return jsonify(aspects)
