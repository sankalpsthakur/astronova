from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request
from flask_babel import gettext as _

from db import get_user_birth_data
from services.ephemeris_service import EphemerisService

horoscope_bp = Blueprint("horoscope", __name__)
_ephem = EphemerisService()

VALID_SIGNS = [
    "aries",
    "taurus",
    "gemini",
    "cancer",
    "leo",
    "virgo",
    "libra",
    "scorpio",
    "sagittarius",
    "capricorn",
    "aquarius",
    "pisces",
]

# Sign characteristics for personalized horoscopes
SIGN_TRAITS = {
    "aries": {
        "element": "fire",
        "ruler": "Mars",
        "quality": "cardinal",
        "keywords": ["initiative", "courage", "leadership", "action"],
        "colors": ["Red", "Scarlet", "Crimson"],
        "lucky_numbers": [1, 9, 19],
        "lucky_days": ["Tuesday", "Saturday"],
    },
    "taurus": {
        "element": "earth",
        "ruler": "Venus",
        "quality": "fixed",
        "keywords": ["stability", "patience", "sensuality", "beauty"],
        "colors": ["Green", "Pink", "Emerald"],
        "lucky_numbers": [2, 6, 24],
        "lucky_days": ["Friday", "Monday"],
    },
    "gemini": {
        "element": "air",
        "ruler": "Mercury",
        "quality": "mutable",
        "keywords": ["communication", "versatility", "curiosity", "intellect"],
        "colors": ["Yellow", "Light Blue", "Silver"],
        "lucky_numbers": [3, 5, 14],
        "lucky_days": ["Wednesday", "Sunday"],
    },
    "cancer": {
        "element": "water",
        "ruler": "Moon",
        "quality": "cardinal",
        "keywords": ["emotion", "nurturing", "intuition", "home"],
        "colors": ["White", "Silver", "Pearl"],
        "lucky_numbers": [2, 7, 11],
        "lucky_days": ["Monday", "Thursday"],
    },
    "leo": {
        "element": "fire",
        "ruler": "Sun",
        "quality": "fixed",
        "keywords": ["confidence", "creativity", "generosity", "pride"],
        "colors": ["Gold", "Orange", "Yellow"],
        "lucky_numbers": [1, 4, 10],
        "lucky_days": ["Sunday", "Tuesday"],
    },
    "virgo": {
        "element": "earth",
        "ruler": "Mercury",
        "quality": "mutable",
        "keywords": ["analysis", "precision", "service", "health"],
        "colors": ["Navy Blue", "Grey", "Beige"],
        "lucky_numbers": [5, 14, 23],
        "lucky_days": ["Wednesday", "Friday"],
    },
    "libra": {
        "element": "air",
        "ruler": "Venus",
        "quality": "cardinal",
        "keywords": ["balance", "harmony", "relationships", "justice"],
        "colors": ["Pink", "Light Blue", "Lavender"],
        "lucky_numbers": [6, 15, 24],
        "lucky_days": ["Friday", "Saturday"],
    },
    "scorpio": {
        "element": "water",
        "ruler": "Mars",
        "quality": "fixed",
        "keywords": ["intensity", "transformation", "passion", "mystery"],
        "colors": ["Maroon", "Black", "Deep Red"],
        "lucky_numbers": [8, 11, 18],
        "lucky_days": ["Tuesday", "Thursday"],
    },
    "sagittarius": {
        "element": "fire",
        "ruler": "Jupiter",
        "quality": "mutable",
        "keywords": ["adventure", "wisdom", "optimism", "freedom"],
        "colors": ["Purple", "Blue", "Turquoise"],
        "lucky_numbers": [3, 9, 12],
        "lucky_days": ["Thursday", "Sunday"],
    },
    "capricorn": {
        "element": "earth",
        "ruler": "Saturn",
        "quality": "cardinal",
        "keywords": ["ambition", "discipline", "responsibility", "achievement"],
        "colors": ["Brown", "Black", "Dark Green"],
        "lucky_numbers": [8, 10, 26],
        "lucky_days": ["Saturday", "Tuesday"],
    },
    "aquarius": {
        "element": "air",
        "ruler": "Saturn",
        "quality": "fixed",
        "keywords": ["innovation", "independence", "humanity", "originality"],
        "colors": ["Electric Blue", "Silver", "Turquoise"],
        "lucky_numbers": [4, 8, 13],
        "lucky_days": ["Saturday", "Sunday"],
    },
    "pisces": {
        "element": "water",
        "ruler": "Jupiter",
        "quality": "mutable",
        "keywords": ["compassion", "intuition", "creativity", "spirituality"],
        "colors": ["Sea Green", "Lavender", "Aqua"],
        "lucky_numbers": [3, 7, 12],
        "lucky_days": ["Thursday", "Monday"],
    },
}


def _calculate_aspects_to_natal(transit_planets: dict, natal_planets: dict, orb: float = 8.0) -> list[dict]:
    """Calculate aspects between transiting planets and natal planets."""
    aspects = {
        "conjunction": 0,
        "sextile": 60,
        "square": 90,
        "trine": 120,
        "opposition": 180,
    }

    results = []
    for t_name, t_info in transit_planets.items():
        t_lon = t_info.get("longitude", 0.0)
        for n_name, n_info in natal_planets.items():
            n_lon = n_info.get("longitude", 0.0)
            diff = abs((t_lon - n_lon + 180) % 360 - 180)

            for aspect_name, angle in aspects.items():
                delta = abs(diff - angle)
                if delta <= orb:
                    results.append({"transit": t_name, "natal": n_name, "aspect": aspect_name, "orb": round(delta, 2)})
    return results


def _generate_horoscope(sign: str, dt: datetime, period: str, natal_data: dict = None) -> tuple[str, dict]:
    """Generate personalized horoscope based on current planetary transits and optional natal chart."""
    traits = SIGN_TRAITS.get(sign, SIGN_TRAITS["aries"])

    # Get current planetary positions
    positions = _ephem.get_positions_for_date(dt)
    planets = positions.get("planets", {})

    # Analyze key transits (simplified - real version would check aspects)
    sun_sign = planets.get("sun", {}).get("sign", "")
    moon_sign = planets.get("moon", {}).get("sign", "")
    venus_sign = planets.get("venus", {}).get("sign", "")

    # Calculate aspects if natal data provided
    natal_aspects = []
    if natal_data:
        natal_aspects = _calculate_aspects_to_natal(planets, natal_data)

    # Generate context-aware guidance based on transits
    guidance_parts = []

    # Add natal aspect-based personalization if available
    if natal_aspects:
        # Prioritize major transits to natal chart
        major_aspects = [a for a in natal_aspects if a["orb"] < 3.0]
        if major_aspects:
            # Focus on most significant aspect
            aspect = major_aspects[0]
            transit_planet = aspect["transit"]
            natal_planet = aspect["natal"]
            aspect_type = aspect["aspect"]

            # Create personalized message based on the aspect
            if aspect_type == "conjunction":
                guidance_parts.append(
                    f"Transiting {transit_planet.title()} aligns powerfully with your natal {natal_planet.title()}, amplifying its energy in your life. This is a significant time for {traits['keywords'][0]} and personal growth."
                )
            elif aspect_type == "trine":
                guidance_parts.append(
                    f"Transiting {transit_planet.title()} forms a harmonious trine with your natal {natal_planet.title()}, bringing ease and flow. Opportunities for {traits['keywords'][1]} naturally arise."
                )
            elif aspect_type == "square":
                guidance_parts.append(
                    f"Transiting {transit_planet.title()} challenges your natal {natal_planet.title()} through a square aspect. Channel this tension into productive {traits['keywords'][2]} and breakthrough."
                )
            elif aspect_type == "opposition":
                guidance_parts.append(
                    f"Transiting {transit_planet.title()} opposes your natal {natal_planet.title()}, highlighting the need for balance. Integrate {traits['keywords'][0]} with awareness and maturity."
                )
            elif aspect_type == "sextile":
                guidance_parts.append(
                    f"Transiting {transit_planet.title()} supports your natal {natal_planet.title()} through a sextile, creating opportunities. Take initiative in areas of {traits['keywords'][1]}."
                )

    # Sun transit influence
    if sun_sign.lower() == sign:
        guidance_parts.append(
            f"With the Sun illuminating your sign, this is your time to shine. Focus on {traits['keywords'][0]} and {traits['keywords'][1]}."
        )
    else:
        # Vary guidance based on which keyword to emphasize
        keyword_idx = (dt.timetuple().tm_yday // 30) % len(traits["keywords"])
        guidance_parts.append(f"Channel your natural {traits['keywords'][keyword_idx]} into meaningful projects.")

    # Moon transit (emotions)
    if moon_sign.lower() in ["cancer", "pisces", "scorpio"]:  # Water signs
        guidance_parts.append(f"Emotional currents run deep. Your {traits['keywords'][2]} will guide you through.")
    elif moon_sign.lower() == sign:
        # Moon in own sign
        guidance_parts.append(f"The Moon energizes your emotions and intuition. Trust your {traits['keywords'][1]} today.")
    else:
        keyword_idx = (dt.timetuple().tm_yday // 15) % len(traits["keywords"])
        guidance_parts.append(f"Stay grounded in your {traits['keywords'][keyword_idx]} to navigate the day ahead.")

    # Mercury transit (communication) - varies by period
    if "communication" in traits["keywords"] or "intellect" in traits["keywords"]:
        if period == "daily":
            guidance_parts.append("Your mental clarity is heightened - perfect for important conversations.")
        elif period == "weekly":
            guidance_parts.append("This week brings opportunities for meaningful dialogue and intellectual growth.")
        else:
            guidance_parts.append("The month ahead favors learning, teaching, and sharing your knowledge.")

    # Venus transit (relationships) - varies by period
    if period == "weekly" or period == "monthly":
        if "relationships" in traits["keywords"] or "harmony" in traits["keywords"]:
            if period == "weekly":
                guidance_parts.append("Relationships take center stage this week. Foster connection and balance.")
            else:
                guidance_parts.append("This month emphasizes harmony in partnerships and creative pursuits.")
    else:
        # Daily: add Venus influence based on Venus sign
        if venus_sign.lower() == sign:
            guidance_parts.append("Venus graces your sign, enhancing charm and attracting positive connections.")

    # Mars transit (action) - add date-based variation
    if traits["element"] == "fire":
        action_word = traits["keywords"][(dt.timetuple().tm_yday // 7) % len(traits["keywords"])]
        if period == "daily":
            guidance_parts.append(
                f"Mars energy aligns with your fiery nature. Take bold {action_word} when opportunities arise."
            )
        else:
            guidance_parts.append(f"Harness your natural {action_word} throughout this {period} with confidence.")

    # Combine into cohesive message (take first 2-3 parts based on period)
    num_parts = 2 if period == "daily" else 3
    content = " ".join(guidance_parts[:num_parts])

    # Generate lucky elements based on date and sign
    day_offset = dt.timetuple().tm_yday
    color_idx = day_offset % len(traits["colors"])
    number_idx = day_offset % len(traits["lucky_numbers"])
    day_idx = day_offset % len(traits["lucky_days"])

    lucky_elements = {
        "color": traits["colors"][color_idx],
        "number": traits["lucky_numbers"][number_idx],
        "day": traits["lucky_days"][day_idx],
        "element": traits["element"],
        "ruler": traits["ruler"],
    }

    return content, lucky_elements


@horoscope_bp.route("", methods=["GET"])
def horoscope():
    sign = request.args.get("sign", "aries").lower()
    if sign not in VALID_SIGNS:
        return jsonify({"error": _("Invalid zodiac sign")}), 400

    date_str = request.args.get("date")
    period = request.args.get("type", "daily").lower()
    user_id = request.args.get("user_id")  # Optional user ID for personalization

    if date_str:
        try:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": _("Invalid date format, use YYYY-MM-DD")}), 400
    else:
        dt = datetime.utcnow()

    # Get natal chart data if user_id provided
    natal_planets = None
    if user_id:
        birth_data = get_user_birth_data(user_id)
        if birth_data:
            # Calculate natal chart positions
            try:
                birth_date = birth_data["birth_date"]
                birth_time = birth_data.get("birth_time", "12:00")
                timezone = birth_data.get("timezone", "UTC")
                lat = birth_data.get("latitude")
                lon = birth_data.get("longitude")

                bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
                bd_utc = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

                natal_positions = _ephem.get_positions_for_date(bd_utc, lat, lon)
                natal_planets = natal_positions.get("planets", {})
            except Exception:
                # If natal chart calculation fails, continue with generic horoscope
                pass

    content, lucky_elements = _generate_horoscope(sign, dt, period, natal_planets)

    return jsonify(
        {
            "id": f'{sign}-{dt.strftime("%Y%m%d")}-{period}',
            "sign": sign,
            "date": dt.isoformat(),
            "type": period,
            "content": content,
            "luckyElements": lucky_elements,
            "personalized": natal_planets is not None,  # Indicate if this is personalized
            "disclaimer": "For entertainment purposes only. Not professional advice.",
            "legacy": {"sign": sign, "date": dt.strftime("%Y-%m-%d"), "type": period, "horoscope": content},
        }
    )


@horoscope_bp.route("/personalized", methods=["POST"])
def personalized_horoscope():
    """
    Generate a personalized horoscope based on user's natal chart.
    POST body:
    {
        "sign": "leo",  // optional, will be derived from birth data
        "date": "2025-01-15",  // optional, defaults to today
        "type": "daily",  // optional: daily, weekly, monthly
        "birthData": {
            "date": "1990-08-15",
            "time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060
        }
    }
    """
    payload = request.get_json(silent=True)
    if not payload:
        return jsonify({"error": _("Request body must be valid JSON")}), 400

    # Parse target date
    date_str = payload.get("date")
    if date_str:
        try:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": _("Invalid date format, use YYYY-MM-DD")}), 400
    else:
        dt = datetime.utcnow()

    period = payload.get("type", "daily").lower()

    # Parse birth data
    birth_data = payload.get("birthData")
    if not birth_data:
        return jsonify({"error": _("birthData is required for personalized horoscope")}), 400

    try:
        birth_date = birth_data["date"]
        birth_time = birth_data.get("time", "12:00")
        timezone = birth_data.get("timezone", "UTC")
        lat = birth_data.get("latitude")
        lon = birth_data.get("longitude")

        if lat is None or lon is None:
            return jsonify({"error": _("latitude and longitude required in birthData")}), 400

        # Calculate natal chart
        bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
        bd_utc = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

        natal_positions = _ephem.get_positions_for_date(bd_utc, lat, lon)
        natal_planets = natal_positions.get("planets", {})

        # Determine sun sign from natal chart if not provided
        sign = payload.get("sign")
        if not sign:
            natal_sun = natal_planets.get("sun", {})
            sign = natal_sun.get("sign", "aries").lower()
        else:
            sign = sign.lower()

        if sign not in VALID_SIGNS:
            return jsonify({"error": _("Invalid zodiac sign")}), 400

    except KeyError as e:
        return jsonify({"error": _("Missing required field in birthData: %(field)s") % {"field": e}}), 400
    except ValueError as e:
        return jsonify({"error": _("Invalid birth data format: %(error)s") % {"error": e}}), 400

    # Generate personalized horoscope
    content, lucky_elements = _generate_horoscope(sign, dt, period, natal_planets)

    return jsonify(
        {
            "id": f'{sign}-{dt.strftime("%Y%m%d")}-{period}-personalized',
            "sign": sign,
            "date": dt.isoformat(),
            "type": period,
            "content": content,
            "luckyElements": lucky_elements,
            "personalized": True,
            "disclaimer": "For entertainment purposes only. Not professional advice.",
            "legacy": {"sign": sign, "date": dt.strftime("%Y-%m-%d"), "type": period, "horoscope": content},
        }
    )


@horoscope_bp.route("/daily", methods=["GET"])
def daily_horoscope():
    # Convenience endpoint that forces daily type
    sign = request.args.get("sign", "aries").lower()
    if sign not in VALID_SIGNS:
        return jsonify({"error": _("Invalid zodiac sign")}), 400

    date_str = request.args.get("date")
    user_id = request.args.get("user_id")  # Optional user ID for personalization

    if date_str:
        try:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": _("Invalid date format, use YYYY-MM-DD")}), 400
    else:
        dt = datetime.utcnow()

    # Get natal chart data if user_id provided
    natal_planets = None
    if user_id:
        birth_data = get_user_birth_data(user_id)
        if birth_data:
            # Calculate natal chart positions
            try:
                birth_date = birth_data["birth_date"]
                birth_time = birth_data.get("birth_time", "12:00")
                timezone = birth_data.get("timezone", "UTC")
                lat = birth_data.get("latitude")
                lon = birth_data.get("longitude")

                bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
                bd_utc = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

                natal_positions = _ephem.get_positions_for_date(bd_utc, lat, lon)
                natal_planets = natal_positions.get("planets", {})
            except Exception:
                # If natal chart calculation fails, continue with generic horoscope
                pass

    content, lucky_elements = _generate_horoscope(sign, dt, "daily", natal_planets)

    return jsonify(
        {
            "id": f'{sign}-{dt.strftime("%Y%m%d")}-daily',
            "sign": sign,
            "date": dt.isoformat(),
            "type": "daily",
            "content": content,
            "luckyElements": lucky_elements,
            "personalized": natal_planets is not None,  # Indicate if this is personalized
            "disclaimer": "For entertainment purposes only. Not professional advice.",
            "legacy": {"sign": sign, "date": dt.strftime("%Y-%m-%d"), "type": "daily", "horoscope": content},
        }
    )
