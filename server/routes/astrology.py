from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request

from services.dasha_interpretation_service import DashaInterpretationService
from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService
from services.planetary_strength_service import PlanetaryStrengthService

try:
    # Access Swiss Ephemeris if available for sidereal Moon (nakshatra) calculations
    from services.ephemeris_service import SWE_AVAILABLE
    from services.ephemeris_service import swe as _swe
except Exception:  # pragma: no cover - defensive
    SWE_AVAILABLE = False
    _swe = None

astrology_bp = Blueprint("astrology", __name__)
_svc = EphemerisService()
_dasha_svc = DashaService()
_strength_svc = PlanetaryStrengthService()
_interp_svc = DashaInterpretationService()


@astrology_bp.route("/positions", methods=["GET"])
def positions():
    positions = _svc.get_positions_for_date(datetime.utcnow())
    result = {}
    for name, info in positions.get("planets", {}).items():
        key = name.title()
        result[key] = {"degree": float(info.get("degree", 0.0)), "sign": str(info.get("sign", "Unknown"))}
    return jsonify(result)


def _vimshottari_sequence():
    # Order and durations in years
    return [
        ("Ketu", 7),
        ("Venus", 20),
        ("Sun", 6),
        ("Moon", 10),
        ("Mars", 7),
        ("Rahu", 18),
        ("Jupiter", 16),
        ("Saturn", 19),
        ("Mercury", 17),
    ]


def _lord_annotation(lord: str) -> str:
    notes = {
        "Sun": "Identity, authority, vitality; focus on purpose and leadership.",
        "Moon": "Emotions, home, nurturing; focus on intuition and care.",
        "Mars": "Action, courage, drive; focus on initiative and willpower.",
        "Mercury": "Intellect, communication; focus on learning and expression.",
        "Jupiter": "Growth, wisdom, fortune; focus on expansion and teaching.",
        "Venus": "Love, beauty, values; focus on harmony and relationships.",
        "Saturn": "Discipline, structure, lessons; focus on responsibility.",
        "Rahu": "Ambition, innovation, desires; unconventional progress.",
        "Ketu": "Detachment, insight, spirituality; inner refinement.",
    }
    return notes.get(lord, "Period of karmic development and learning.")


@astrology_bp.route("/dashas", methods=["GET"])
def dashas():
    """
    Lightweight Vimshottari dasha endpoint - delegates to DashaService for consistency.
    Query:
      - birth_date: YYYY-MM-DD (required)
      - birth_time: HH:MM (optional, defaults to 12:00)
      - timezone: IANA tz (optional, defaults UTC)
      - lat, lon: coordinates (optional)
      - target_date: YYYY-MM-DD (required)
      - include_boundaries: include full antardasha list (optional)
      - debug: include calculation debug info (optional)
    """
    birth_date = request.args.get("birth_date")
    birth_time = request.args.get("birth_time", "12:00")
    timezone = request.args.get("timezone", "UTC")
    lat = request.args.get("lat", type=float)
    lon = request.args.get("lon", type=float)
    target_date_str = request.args.get("target_date")
    include_boundaries = request.args.get("include_boundaries") in ("1", "true", "yes")
    debug = request.args.get("debug") in ("1", "true", "yes")

    if not birth_date or not target_date_str:
        return jsonify({"error": "birth_date and target_date required"}), 400

    # Parse dates
    try:
        bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
        bd = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
        target_date = datetime.strptime(target_date_str, "%Y-%m-%d")
    except Exception as e:
        return jsonify({"error": f"Invalid date/time/timezone: {str(e)}"}), 400

    # Get sidereal Moon position for dasha calculation
    moon_longitude = 0.0
    if SWE_AVAILABLE and _swe is not None:
        try:
            _swe.set_sid_mode(_swe.SIDM_LAHIRI, 0, 0)
            jd = _swe.julday(bd.year, bd.month, bd.day, bd.hour + bd.minute / 60 + bd.second / 3600)
            xx, _ = _swe.calc_ut(jd, _swe.MOON, _swe.FLG_SIDEREAL)
            moon_longitude = float(xx[0])
        except Exception:
            positions = _svc.get_positions_for_date(bd, lat, lon, system="vedic")
            moon = positions.get("planets", {}).get("moon", {})
            moon_longitude = float(moon.get("longitude", 0.0))
    else:
        positions = _svc.get_positions_for_date(bd, lat, lon, system="vedic")
        moon = positions.get("planets", {}).get("moon", {})
        moon_longitude = float(moon.get("longitude", 0.0))

    # Use canonical DashaService for calculation
    dasha_info = _dasha_svc.calculate_complete_dasha(
        bd, moon_longitude, target_date, include_future=False, num_future_periods=0
    )

    if not dasha_info:
        return jsonify({"error": "Failed to calculate dasha"}), 500

    # Build lightweight response
    maha = dasha_info["mahadasha"]
    antar = dasha_info.get("antardasha", {})

    resp = {
        "mahadasha": {
            "lord": maha["lord"],
            "start": maha["start"],
            "end": maha["end"],
            "annotation": _lord_annotation(maha["lord"]),
        },
        "antardasha": {
            "lord": antar.get("lord", maha["lord"]),
            "start": antar.get("start", maha["start"]),
            "end": antar.get("end", maha["end"]),
            "annotation": _lord_annotation(antar.get("lord", maha["lord"])),
        },
    }

    # Optional: include full antardasha boundaries
    if include_boundaries and dasha_info.get("all_antardashas"):
        resp["boundaries"] = {
            "mahadasha": {"lord": maha["lord"], "start": maha["start"], "end": maha["end"]},
            "antardasha": [
                {"lord": a["lord"], "start": a["start"], "end": a["end"], "annotation": _lord_annotation(a["lord"])}
                for a in dasha_info["all_antardashas"]
            ],
            "breakpoints": [a["start"] for a in dasha_info["all_antardashas"]],
        }

    # Optional: debug info
    if debug:
        starting = dasha_info.get("starting_dasha", {})
        resp["debug"] = {
            "start_lord": starting.get("lord"),
            "start_balance_years": starting.get("balance_years"),
            "start_balance_years_int": int(starting.get("balance_years", 0)),
            "start_balance_months_approx": int(
                round((starting.get("balance_years", 0) - int(starting.get("balance_years", 0))) * 12)
            ),
            "mahadasha_order": [lord for lord, _ in _vimshottari_sequence()],
        }

    resp["disclaimer"] = "For entertainment purposes only. Not professional advice."
    return jsonify(resp)


@astrology_bp.route("/dashas/complete", methods=["POST"])
def dashas_complete():
    """
    Comprehensive dasha endpoint with all features:
    - Mahadasha, Antardasha, Pratyantardasha calculations
    - Planetary strength analysis
    - Impact scoring (career, relationships, health, spiritual)
    - Qualitative interpretations and narratives
    - Transition information
    - Educational content

    POST body:
    {
        "birthData": {
            "date": "YYYY-MM-DD",
            "time": "HH:MM",
            "timezone": "IANA timezone",
            "latitude": float,
            "longitude": float
        },
        "targetDate": "YYYY-MM-DD",  // optional, defaults to today
        "includeTransitions": true,  // optional
        "includeEducation": true     // optional
    }
    """
    payload = request.get_json(silent=True) or {}

    # Parse birth data
    birth_data = payload.get("birthData", {})
    birth_date = birth_data.get("date")
    birth_time = birth_data.get("time", "12:00")
    timezone = birth_data.get("timezone", "UTC")
    lat = birth_data.get("latitude")
    lon = birth_data.get("longitude")

    if not birth_date or lat is None or lon is None:
        return jsonify({"error": "birthData with date, latitude, and longitude required"}), 400

    # Parse target date (defaults to today)
    target_date_str = payload.get("targetDate")
    if target_date_str:
        try:
            target_date = datetime.strptime(target_date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid targetDate format, use YYYY-MM-DD"}), 400
    else:
        target_date = datetime.now()

    # Parse birth datetime
    try:
        bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
        bd = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
    except Exception as e:
        return jsonify({"error": f"Invalid date/time/timezone: {str(e)}"}), 400

    # Validate target_date is not before birth_date
    if target_date < bd:
        return jsonify({
            "error": "target_date cannot be before birth_date",
            "detail": f"Birth date is {bd.date().isoformat()}, but target date is {target_date.date().isoformat()}. Dasha periods start from birth."
        }), 400

    # Get sidereal Moon position for dasha calculation
    moon_longitude = 0.0
    if SWE_AVAILABLE and _swe is not None:
        try:
            _swe.set_sid_mode(_swe.SIDM_LAHIRI, 0, 0)
            jd = _swe.julday(bd.year, bd.month, bd.day, bd.hour + bd.minute / 60 + bd.second / 3600)
            xx, _ = _swe.calc_ut(jd, _swe.MOON, _swe.FLG_SIDEREAL)
            moon_longitude = float(xx[0])
        except Exception:
            positions = _svc.get_positions_for_date(bd, lat, lon, system="vedic")
            moon = positions.get("planets", {}).get("moon", {})
            moon_longitude = float(moon.get("longitude", 0.0))
    else:
        positions = _svc.get_positions_for_date(bd, lat, lon, system="vedic")
        moon = positions.get("planets", {}).get("moon", {})
        moon_longitude = float(moon.get("longitude", 0.0))

    # Calculate complete dasha information
    dasha_info = _dasha_svc.calculate_complete_dasha(
        bd, moon_longitude, target_date, include_future=True, num_future_periods=3
    )

    if not dasha_info or dasha_info.get("error"):
        error_msg = dasha_info.get("message", "Failed to calculate dasha") if dasha_info else "Failed to calculate dasha"
        return jsonify({"error": error_msg}), 400

    # Get planet positions for strength analysis (default to sidereal/Vedic for Time Travel consistency)
    zodiac_system = (payload.get("system") or payload.get("zodiacSystem") or "vedic")
    zodiac_system = str(zodiac_system).lower()
    if zodiac_system in ("tropical", "western"):
        zodiac_system = "western"
    elif zodiac_system in ("sidereal", "kundali", "vedic"):
        zodiac_system = "vedic"
    else:
        zodiac_system = "vedic"

    current_positions = _svc.get_positions_for_date(target_date, lat, lon, system=zodiac_system)
    planet_data = {}
    sign_names = (
        list(EphemerisService.VEDIC_SIGNS) if zodiac_system == "vedic" else list(EphemerisService.ZODIAC_SIGNS)
    )
    asc_sign = str(current_positions.get("planets", {}).get("ascendant", {}).get("sign", sign_names[0]))
    try:
        asc_index = sign_names.index(asc_sign)
    except ValueError:
        asc_index = 0

    def house_for_sign(sign: str) -> int | None:
        try:
            idx = sign_names.index(sign)
        except ValueError:
            return None
        return ((idx - asc_index) % 12) + 1

    for name, info in current_positions.get("planets", {}).items():
        sign = info.get("sign")
        house = 1 if name == "ascendant" else house_for_sign(str(sign))  # type: ignore[arg-type]
        planet_data[name.title()] = {
            "sign": sign,
            "degree": info.get("degree"),
            "house": house,
            "retrograde": info.get("retrograde", False),
        }

    # Calculate impact for current periods
    maha_lord = dasha_info["mahadasha"]["lord"]
    antar_lord = dasha_info["antardasha"]["lord"] if dasha_info.get("antardasha") else maha_lord
    pratyantar_lord = dasha_info["pratyantardasha"]["lord"] if dasha_info.get("pratyantardasha") else None

    # Impact analysis
    maha_impact = _strength_svc.calculate_dasha_impact(maha_lord, planet_data)
    antar_impact = _strength_svc.calculate_dasha_impact(antar_lord, planet_data)

    # Combined impact (weighted: Mahadasha 60%, Antardasha 40%)
    combined_impact = {
        "career": round(maha_impact["impact_scores"]["career"] * 0.6 + antar_impact["impact_scores"]["career"] * 0.4, 1),
        "relationships": round(
            maha_impact["impact_scores"]["relationships"] * 0.6 + antar_impact["impact_scores"]["relationships"] * 0.4, 1
        ),
        "health": round(maha_impact["impact_scores"]["health"] * 0.6 + antar_impact["impact_scores"]["health"] * 0.4, 1),
        "spiritual": round(
            maha_impact["impact_scores"]["spiritual"] * 0.6 + antar_impact["impact_scores"]["spiritual"] * 0.4, 1
        ),
    }

    # Generate narrative
    narrative = _interp_svc.generate_period_narrative(
        maha_lord, antar_lord, pratyantar_lord, maha_impact.get("strength"), combined_impact
    )

    # Build response
    response = {
        "dasha": dasha_info,
        "current_period": {
            "mahadasha": dasha_info["mahadasha"],
            "antardasha": dasha_info["antardasha"],
            "pratyantardasha": dasha_info["pratyantardasha"],
            "narrative": narrative,
        },
        "impact_analysis": {
            "mahadasha_impact": {
                "lord": maha_lord,
                "scores": maha_impact["impact_scores"],
                "tone": maha_impact["tone"],
                "tone_description": maha_impact["tone_description"],
                "strength": maha_impact["strength"],
            },
            "antardasha_impact": {
                "lord": antar_lord,
                "scores": antar_impact["impact_scores"],
                "tone": antar_impact["tone"],
                "tone_description": antar_impact["tone_description"],
                "strength": antar_impact["strength"],
            },
            "combined_scores": combined_impact,
        },
        "planetary_keywords": {
            "mahadasha": maha_impact.get("keywords", []),
            "antardasha": antar_impact.get("keywords", []),
        },
    }

    # Add transition information if requested
    if payload.get("includeTransitions", False):
        transition_info = _dasha_svc.get_dasha_transition_info(bd, moon_longitude, target_date)

        # Get next Mahadasha for comparison
        if transition_info.get("mahadasha") and dasha_info.get("upcoming_mahadashas"):
            next_maha_lord = dasha_info["upcoming_mahadashas"][0]["lord"]
            comparison = _strength_svc.compare_dasha_impacts(maha_lord, next_maha_lord, planet_data)

            transition_insights = _interp_svc.get_transition_insights(
                maha_lord, next_maha_lord, transition_info["mahadasha"]["days_remaining"], comparison
            )

            response["transitions"] = {
                "timing": transition_info,
                "insights": transition_insights,
                "impact_comparison": comparison,
            }

    # Add educational content if requested
    if payload.get("includeEducation", False):
        starting_lord = dasha_info["starting_dasha"]["lord"]
        balance_years = dasha_info["starting_dasha"]["balance_years"]

        response["education"] = {
            "calculation_explanation": _interp_svc.explain_dasha_calculation(moon_longitude, starting_lord, balance_years),
            "mahadasha_guide": _interp_svc.get_dasha_explanation(maha_lord, "mahadasha"),
            "antardasha_guide": _interp_svc.get_dasha_explanation(antar_lord, "antardasha"),
        }

    response["disclaimer"] = "For entertainment purposes only. Not professional advice."
    return jsonify(response)
