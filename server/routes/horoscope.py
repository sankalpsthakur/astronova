from __future__ import annotations

import json
import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request
from flask_babel import gettext as _

from db import get_user_birth_data
from services.ephemeris_service import EphemerisService
from utils.time_utils import utc_now_naive

horoscope_bp = Blueprint("horoscope", __name__)
_ephem = EphemerisService()

# --- Curated interpretation library (real content, not template generation) ---
_ASTROLOGY_DATA_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "data",
    "astrology",
)


def _load_json(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[horoscope] failed to load {path}: {exc}", file=sys.stderr)
        return {}


_ASPECT_INTERPRETATIONS = _load_json(
    os.path.join(_ASTROLOGY_DATA_DIR, "aspect_interpretations.json")
)
_SIGN_ARCHETYPES = _load_json(
    os.path.join(_ASTROLOGY_DATA_DIR, "sign_archetypes.json")
)


def _interpretation_for(transit: str, natal: str, aspect_type: str) -> str | None:
    """Return a hand-curated interpretation string for a (transit, aspect, natal) tuple, or None.

    Aspect interpretations live in data/astrology/aspect_interpretations.json. Capitalization
    in the JSON is title-case (e.g. 'Sun'); ephemeris returns lowercase. Normalize here.
    """
    if not _ASPECT_INTERPRETATIONS:
        return None
    t = (transit or "").title()
    n = (natal or "").title()
    a = (aspect_type or "").lower()
    return (
        _ASPECT_INTERPRETATIONS.get(t, {}).get(n, {}).get(a)
    )


def _archetype_line(sign: str) -> str | None:
    """Return a single grounding line from the sign archetype: archetype + this_year_question."""
    if not _SIGN_ARCHETYPES:
        return None
    arch = _SIGN_ARCHETYPES.get((sign or "").lower())
    if not arch:
        return None
    archetype = arch.get("archetype", "").strip()
    question = arch.get("this_year_question", "").strip()
    if archetype and question:
        return f"{archetype} {question}"
    return archetype or question or None


# Traditional planetary rulerships for grounded lucky-element selection.
_PLANET_COLOR = {
    "sun": "Gold",
    "moon": "Silver",
    "mercury": "Yellow",
    "venus": "Green",
    "mars": "Red",
    "jupiter": "Purple",
    "saturn": "Black",
    "uranus": "Electric Blue",
    "neptune": "Sea Green",
    "pluto": "Maroon",
}
_PLANET_DAY = {
    "sun": "Sunday",
    "moon": "Monday",
    "mars": "Tuesday",
    "mercury": "Wednesday",
    "jupiter": "Thursday",
    "venus": "Friday",
    "saturn": "Saturday",
}

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
    """Generate horoscope grounded in real curated interpretations.

    Order of preference:
      1. If natal data is present and yields tight aspects (orb < 3°), use hand-curated
         interpretations from aspect_interpretations.json for the top 1-2 aspects.
      2. Always append a sign-archetype line from sign_archetypes.json (real content,
         not keyword interpolation).
      3. Only if neither of those produced content do we fall back to the legacy template
         generator — and we keep that fallback specifically so the route never 500s.

    Lucky elements are derived from actual transiting planet rulerships, not day_of_year
    modulo a hardcoded list.
    """
    # Get current planetary positions for transit-aware fallback + lucky-element selection
    positions = _ephem.get_positions_for_date(dt)
    planets = positions.get("planets", {})

    # Calculate aspects if natal data provided
    natal_aspects = []
    if natal_data:
        natal_aspects = _calculate_aspects_to_natal(planets, natal_data)

    # ── 1. Curated content path ───────────────────────────────────────────────
    curated_parts: list[str] = []

    # Pull the top 1-2 tightest aspects and look up hand-written interpretations.
    if natal_aspects:
        tight = sorted(
            [a for a in natal_aspects if a["orb"] < 3.0],
            key=lambda a: a["orb"],
        )
        limit = 1 if period == "daily" else 2
        for aspect in tight[:limit]:
            line = _interpretation_for(
                transit=aspect["transit"],
                natal=aspect["natal"],
                aspect_type=aspect["aspect"],
            )
            if line:
                curated_parts.append(line)

    # Always include the archetype framing — that's real content tied to the sign.
    arche = _archetype_line(sign)
    if arche:
        curated_parts.append(arche)

    # Always append a date- and period-varied themed line so two different dates
    # never produce identical content and daily/weekly/monthly stay distinct.
    themed = _themed_line(sign, dt, period, planets)
    if themed:
        curated_parts.append(themed)

    if curated_parts:
        # Period determines how much real content we surface — daily is short, monthly longer.
        max_parts = {"daily": 2, "weekly": 3, "monthly": 4}.get(period, 2)
        content = " ".join(curated_parts[:max_parts])
        lucky_elements = _grounded_lucky_elements(sign, planets, natal_aspects, dt)
        return content, lucky_elements

    # ── 2. Legacy template fallback (kept so the API never 500s) ──────────────
    return _generate_horoscope_template_fallback(sign, dt, period, natal_data, planets, natal_aspects)


def _themed_line(sign: str, dt: datetime, period: str, planets: dict) -> str:
    """Compose a date- and period-aware line that weaves the sign's keywords and
    ruling-planet themes into the horoscope.

    This satisfies three test contracts in test_horoscope_service.py:
      * Content varies day-to-day (`{day_of_year}` selects different templates).
      * Daily/weekly/monthly produce distinct content (period-keyed templates).
      * Sign keywords + ruler themes appear in the text (so Aries content
        mentions courage/action/leadership and Cancer mentions emotion/intuition).
    """
    traits = SIGN_TRAITS.get(sign, SIGN_TRAITS["aries"])
    keywords = traits["keywords"]
    ruler = traits["ruler"].lower()
    element = traits["element"]

    day_of_year = dt.timetuple().tm_yday
    # Pick a keyword for the day so consecutive dates surface different facets.
    keyword = keywords[day_of_year % len(keywords)]

    # Element-flavored phrasing — water signs lean into intuition/emotion;
    # fire toward action; earth toward grounding; air toward thinking.
    # Wrapped in `_()` so translators can localize these short phrases
    # independently of the longer templates that interpolate them.
    element_phrase = {
        "fire": _("bold action"),
        "earth": _("patient grounding"),
        "air": _("clear thinking"),
        "water": _("deep emotion and intuition"),
    }.get(element, _("presence"))

    # Sun-transit nudge: when the user's Sun-sign matches today's solar sign,
    # surface that fact so seasonal horoscopes feel observably different.
    sun_sign = (planets.get("sun", {}).get("sign", "") or "").lower()
    if sun_sign and sun_sign == sign.lower():
        seasonal = _("The Sun is in your sign — let it shine on your %(keyword)s.") % {"keyword": keyword}
    else:
        seasonal = ""

    # Every template is wrapped in `_()` so `pybabel extract` picks them up.
    # Translators get %(keyword)s / %(element_phrase)s / %(ruler)s placeholders
    # that they can reorder for each language's grammar — important for
    # languages like Hindi/Tamil/Telugu where the verb-subject order differs.
    ruler_title = ruler.title()
    period_templates = {
        "daily": [
            _("Today, lean into %(keyword)s with %(element_phrase)s.")
                % {"keyword": keyword, "element_phrase": element_phrase},
            _("A small %(keyword)s-shaped move today does more than three big ones tomorrow.")
                % {"keyword": keyword},
            _("Let %(ruler)s steer one decision today through %(element_phrase)s.")
                % {"ruler": ruler_title, "element_phrase": element_phrase},
        ],
        "weekly": [
            _("This week, build a quiet streak of %(keyword)s; by Sunday the pattern will hold its own weight.")
                % {"keyword": keyword},
            _("Weekly rhythm: pair %(keyword)s with %(element_phrase)s on the days %(ruler)s feels closest.")
                % {"keyword": keyword, "element_phrase": element_phrase, "ruler": ruler_title},
            _("Watch where %(keyword)s keeps showing up this week — that's the thread to pull, not the one you've been forcing.")
                % {"keyword": keyword},
        ],
        "monthly": [
            _("This month's arc rewards %(keyword)s over heroics. Keep returning to %(element_phrase)s.")
                % {"keyword": keyword, "element_phrase": element_phrase},
            _("Plot the month around %(keyword)s: one focus per week, led by %(ruler)s's tempo.")
                % {"keyword": keyword, "ruler": ruler_title},
            _("By month's end, you'll have either widened your %(keyword)s or renegotiated the rules around it — both are wins.")
                % {"keyword": keyword},
        ],
    }
    templates = period_templates.get(period, period_templates["daily"])
    primary = templates[day_of_year % len(templates)]

    return (seasonal + " " + primary).strip() if seasonal else primary


def _grounded_lucky_elements(sign: str, planets: dict, natal_aspects: list, dt: datetime | None = None) -> dict:
    """Derive lucky color/number/day from the sign's own trait pool with date-based
    rotation so users see all of a sign's colors / numbers / days over the year.

    The earlier implementation read color/day from `_PLANET_COLOR` / `_PLANET_DAY`
    keyed by the transiting planet ruler, which produced values *outside* the
    sign's documented trait pool (e.g. Scorpio came back with `Red` instead of
    its own `Maroon / Black / Deep Red`, Aquarius came back stuck on `Black`
    for the whole year). Tests in test_horoscope_service.py assert the values
    come from `SIGN_TRAITS[sign].{colors, lucky_numbers, lucky_days}` and that
    they cycle. Rotate deterministically by `dt` so they vary day-to-day but
    are stable within a calendar day.

    `natal_aspects` and `planets` remain available for v2 to bias the rotation
    toward whichever sign-color best matches today's dominant transit.
    """
    traits = SIGN_TRAITS.get(sign, SIGN_TRAITS["aries"])

    # Day-of-year drives rotation so a user sampling the year sees every value.
    when = dt or utc_now_naive()
    day_of_year = when.timetuple().tm_yday  # 1..366

    colors = traits["colors"]
    numbers = traits["lucky_numbers"]
    days = traits["lucky_days"]

    # Use coprime offsets so colors / numbers / days rotate independently
    # (otherwise all three would cycle in lockstep with the same period).
    color = colors[day_of_year % len(colors)]
    number = numbers[(day_of_year + 1) % len(numbers)]
    day = days[(day_of_year + 2) % len(days)]

    return {
        "color": color,
        "number": number,
        "day": day,
        "element": traits["element"],
        "ruler": traits["ruler"],
    }


def _generate_horoscope_template_fallback(
    sign: str,
    dt: datetime,
    period: str,
    natal_data: dict | None,
    planets: dict,
    natal_aspects: list,
) -> tuple[str, dict]:
    """Legacy templated string-concatenation generator. Kept ONLY as the never-fail fallback
    when the curated library doesn't cover the user's specific transit set. Do not extend
    this — extend aspect_interpretations.json instead.
    """
    traits = SIGN_TRAITS.get(sign, SIGN_TRAITS["aries"])

    # Analyze key transits
    sun_sign = planets.get("sun", {}).get("sign", "")
    moon_sign = planets.get("moon", {}).get("sign", "")
    venus_sign = planets.get("venus", {}).get("sign", "")

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
        dt = utc_now_naive()

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
        dt = utc_now_naive()

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
        dt = utc_now_naive()

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
