"""Discover endpoint - unified snapshot for daily check-in."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional
from zoneinfo import ZoneInfo

from flask import Blueprint, jsonify, request

from db import get_user_birth_data
from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService

discover_bp = Blueprint("discover", __name__)
_ephem = EphemerisService()
_dasha = DashaService()

# Domain mapping for insights - expanded to 7 life domains
DOMAINS = {
    "self": {"keywords": ["identity", "vitality", "confidence", "personal growth"], "planets": ["sun", "mars"]},
    "love": {"keywords": ["relationships", "harmony", "attraction", "connection"], "planets": ["venus", "moon"]},
    "work": {"keywords": ["career", "ambition", "achievement", "discipline"], "planets": ["saturn", "jupiter"]},
    "mind": {"keywords": ["communication", "intellect", "learning", "ideas"], "planets": ["mercury", "uranus"]},
}

# Extended 7 life domains for domain insights feature
LIFE_DOMAINS = {
    "personal": {
        "displayName": "Personal",
        "keywords": ["identity", "vitality", "self", "growth", "confidence", "purpose"],
        "planets": ["sun"],
        "houses": [1],
        "reportType": "birth_chart",
    },
    "love": {
        "displayName": "Love",
        "keywords": ["relationships", "romance", "attraction", "partnership", "harmony"],
        "planets": ["venus", "moon"],
        "houses": [5, 7],
        "reportType": "love_forecast",
    },
    "career": {
        "displayName": "Career",
        "keywords": ["career", "work", "ambition", "achievement", "profession", "success"],
        "planets": ["saturn", "mars"],
        "houses": [10, 6],
        "reportType": "career_forecast",
    },
    "wealth": {
        "displayName": "Wealth",
        "keywords": ["money", "finances", "abundance", "prosperity", "investments"],
        "planets": ["jupiter", "venus"],
        "houses": [2, 8, 11],
        "reportType": "wealth_forecast",
    },
    "health": {
        "displayName": "Health",
        "keywords": ["health", "vitality", "energy", "wellness", "body", "fitness"],
        "planets": ["mars", "sun"],
        "houses": [6, 1],
        "reportType": "health_forecast",
    },
    "family": {
        "displayName": "Family",
        "keywords": ["family", "home", "roots", "nurturing", "domestic", "parents"],
        "planets": ["moon"],
        "houses": [4],
        "reportType": "family_forecast",
    },
    "spiritual": {
        "displayName": "Spiritual",
        "keywords": ["spiritual", "intuition", "meditation", "transcendence", "dreams"],
        "planets": ["neptune", "jupiter"],
        "houses": [12, 9],
        "reportType": "spiritual_forecast",
    },
}

# Planet interpretations for domain insights
PLANET_MEANINGS = {
    "sun": {
        "strong": "Your core vitality is boosted, bringing confidence and clarity.",
        "neutral": "Steady solar energy supports consistent progress.",
        "weak": "Take time to recharge your inner light today.",
    },
    "moon": {
        "strong": "Emotional sensitivity heightened. Trust your intuition.",
        "neutral": "Emotional currents flow gently today.",
        "weak": "Inner reflection may feel more challenging.",
    },
    "mercury": {
        "strong": "Mental clarity and communication skills are amplified.",
        "neutral": "Thoughts flow at a comfortable pace.",
        "weak": "Double-check important communications today.",
    },
    "venus": {
        "strong": "Harmonious energy for relationships and creativity.",
        "neutral": "Pleasant social interactions likely.",
        "weak": "Give extra care to relationships today.",
    },
    "mars": {
        "strong": "Physical energy and motivation are at a high point.",
        "neutral": "Steady drive available for your goals.",
        "weak": "Pace yourself and avoid confrontations.",
    },
    "jupiter": {
        "strong": "Opportunities for expansion and growth are present.",
        "neutral": "Moderate optimism supports your endeavors.",
        "weak": "Be realistic about expectations today.",
    },
    "saturn": {
        "strong": "Discipline and structure serve you well today.",
        "neutral": "Steady progress through patient effort.",
        "weak": "Responsibilities may feel heavier than usual.",
    },
    "neptune": {
        "strong": "Spiritual sensitivity and intuition are heightened.",
        "neutral": "Creative and spiritual channels are open.",
        "weak": "Stay grounded; avoid escapism.",
    },
    "uranus": {
        "strong": "Breakthrough insights and innovations possible.",
        "neutral": "Openness to change serves you.",
        "weak": "Expect the unexpected; stay flexible.",
    },
    "pluto": {
        "strong": "Deep transformation and regeneration energy available.",
        "neutral": "Subtle but powerful changes brewing.",
        "weak": "Release what no longer serves you.",
    },
}

# Aspect interpretations
ASPECT_MEANINGS = {
    "conjunction": {"label": "conjunct", "strength": 1.0, "nature": "intensifying"},
    "trine": {"label": "trine", "strength": 0.8, "nature": "harmonious"},
    "sextile": {"label": "sextile", "strength": 0.6, "nature": "supportive"},
    "square": {"label": "square", "strength": 0.7, "nature": "challenging"},
    "opposition": {"label": "opposite", "strength": 0.8, "nature": "polarizing"},
}

# Domain-specific insight templates
DOMAIN_INSIGHTS = {
    "personal": {
        "high": [
            "Strong focus day awaits",
            "Your authentic self shines today",
            "Personal power is amplified",
        ],
        "medium": [
            "Steady progress on self-development",
            "Inner clarity available today",
            "Good day for self-reflection",
        ],
        "low": [
            "Take time for self-care",
            "Gentle approach to personal goals",
            "Rest and recharge your spirit",
        ],
    },
    "love": {
        "high": [
            "Gentle day for bonding",
            "Romance energy is heightened",
            "Hearts connect easily today",
        ],
        "medium": [
            "Warm connections possible",
            "Love flows at comfortable pace",
            "Good for relationship conversations",
        ],
        "low": [
            "Give relationships extra patience",
            "Focus on self-love today",
            "Quiet companionship preferred",
        ],
    },
    "career": {
        "high": [
            "Take bold initiatives",
            "Career momentum building",
            "Professional recognition likely",
        ],
        "medium": [
            "Steady work progress",
            "Good for planning ahead",
            "Collaboration opportunities arise",
        ],
        "low": [
            "Avoid major decisions",
            "Review before committing",
            "Behind-the-scenes work favored",
        ],
    },
    "wealth": {
        "high": [
            "Financial opportunities present",
            "Abundance energy flowing",
            "Good for investments",
        ],
        "medium": [
            "Steady financial currents",
            "Moderate spending advised",
            "Plan for long-term growth",
        ],
        "low": [
            "Avoid major decisions",
            "Review finances carefully",
            "Postpone big purchases",
        ],
    },
    "health": {
        "high": [
            "High energy for exercise",
            "Physical vitality peaks",
            "Active pursuits rewarding",
        ],
        "medium": [
            "Moderate energy available",
            "Balance activity with rest",
            "Good for routine maintenance",
        ],
        "low": [
            "Rest and recovery day",
            "Gentle movement preferred",
            "Listen to your body",
        ],
    },
    "family": {
        "high": [
            "Harmony at home today",
            "Family bonds strengthen",
            "Nurturing energy flows",
        ],
        "medium": [
            "Comfortable domestic energy",
            "Good for family conversations",
            "Home improvements favored",
        ],
        "low": [
            "Give family members space",
            "Quiet home time preferred",
            "Address tensions gently",
        ],
    },
    "spiritual": {
        "high": [
            "Deep meditation rewarding",
            "Spiritual insights available",
            "Intuition heightened",
        ],
        "medium": [
            "Gentle spiritual practice",
            "Dreams may be meaningful",
            "Trust quiet guidance",
        ],
        "low": [
            "Stay grounded today",
            "Practical spirituality favored",
            "Journal your thoughts",
        ],
    },
}

# Energy state mapping based on planetary aspects
ENERGY_STATES = {
    "flowing": {"description": "High-frequency vibrations, natural ease", "icon": "wind"},
    "intense": {"description": "Amplified energy frequency, powerful focus", "icon": "flame.fill"},
    "quiet": {"description": "Low-frequency attunement, inward resonance", "icon": "moon.stars"},
    "volatile": {"description": "Shifting frequencies, stay attuned", "icon": "bolt.fill"},
}


def _calculate_energy_state(planets: Dict[str, Any], moon_phase: float) -> str:
    """Determine energy state based on planetary positions and moon phase."""
    mars_speed = planets.get("mars", {}).get("speed", 0)
    saturn_speed = planets.get("saturn", {}).get("speed", 0)

    # Retrograde indicators
    retrogrades = sum(1 for p in planets.values() if isinstance(p, dict) and p.get("speed", 1) < 0)

    # Moon phase affects energy (0-1 scale, 0.5 = full moon)
    is_full_moon = 0.45 <= moon_phase <= 0.55
    is_new_moon = moon_phase < 0.1 or moon_phase > 0.9

    if retrogrades >= 3:
        return "volatile"
    elif is_full_moon or (mars_speed and mars_speed > 0.7):
        return "intense"
    elif is_new_moon or (saturn_speed and saturn_speed < 0):
        return "quiet"
    else:
        return "flowing"


def _calculate_domain_weights(planets: Dict[str, Any], sign: str) -> Dict[str, float]:
    """Calculate relative weights for each domain based on planetary activity."""
    weights = {"self": 0.25, "love": 0.25, "work": 0.25, "mind": 0.25}

    for domain, config in DOMAINS.items():
        domain_planets = config["planets"]
        activity = 0.0
        for planet_name in domain_planets:
            planet = planets.get(planet_name, {})
            # Boost if planet is in a compatible sign or has high speed
            speed = abs(planet.get("speed", 0.5))
            activity += min(speed, 1.0)

        weights[domain] = 0.15 + (activity * 0.2)  # Base + activity bonus

    # Normalize to sum to 1.0
    total = sum(weights.values())
    return {k: round(v / total, 2) for k, v in weights.items()}


def _generate_narrative_tiles(
    content: str, planets: Dict[str, Any], domain_weights: Dict[str, float]
) -> List[Dict[str, Any]]:
    """Generate tappable narrative tiles anchored to drivers."""
    tiles = []

    # Split content into sentences
    sentences = [s.strip() for s in content.replace(". ", ".|").split("|") if s.strip()]

    # Map sentences to domains based on keywords
    for i, sentence in enumerate(sentences[:5]):
        # Determine primary domain for this sentence
        best_domain = "self"
        best_score = 0
        for domain, config in DOMAINS.items():
            score = sum(1 for kw in config["keywords"] if kw.lower() in sentence.lower())
            if score > best_score:
                best_score = score
                best_domain = domain

        # Find relevant planetary driver
        driver_planet = DOMAINS[best_domain]["planets"][0]
        driver_info = planets.get(driver_planet, {})

        tiles.append(
            {
                "id": f"tile_{i}",
                "text": sentence,
                "domain": best_domain,
                "weight": domain_weights.get(best_domain, 0.25),
                "driver": {
                    "type": "transit",
                    "planet": driver_planet,
                    "sign": driver_info.get("sign", ""),
                    "longitude": driver_info.get("longitude", 0),
                },
            }
        )

    return tiles


def _generate_actions(energy_state: str, domain_weights: Dict[str, float]) -> List[Dict[str, str]]:
    """Generate recommended actions based on energy state and dominant domains."""
    actions = []

    # Primary action based on energy state
    if energy_state == "flowing":
        actions.append({"id": "act_1", "text": "Start a new project", "type": "do"})
    elif energy_state == "intense":
        actions.append({"id": "act_1", "text": "Focus on one priority", "type": "do"})
    elif energy_state == "quiet":
        actions.append({"id": "act_1", "text": "Reflect and journal", "type": "do"})
    else:  # volatile
        actions.append({"id": "act_1", "text": "Stay flexible with plans", "type": "do"})

    # Domain-specific action
    top_domain = max(domain_weights, key=domain_weights.get)
    domain_actions = {
        "self": {"do": "Invest in personal growth", "avoid": "Overcommitting to others"},
        "love": {"do": "Reach out to someone you care about", "avoid": "Forcing difficult conversations"},
        "work": {"do": "Tackle your most important task", "avoid": "Procrastinating on deadlines"},
        "mind": {"do": "Learn something new", "avoid": "Information overload"},
    }
    if top_domain in domain_actions:
        actions.append({"id": "act_2", "text": domain_actions[top_domain]["do"], "type": "do"})
        actions.append({"id": "act_3", "text": domain_actions[top_domain]["avoid"], "type": "avoid"})

    return actions


def _get_next_shift(birth_date: datetime, moon_longitude: float, target_date: datetime) -> Optional[Dict[str, Any]]:
    """Get the next significant dasha transition."""
    try:
        transition = _dasha.get_dasha_transition_info(birth_date, moon_longitude, target_date)
        if transition and transition.get("next_transition"):
            next_t = transition["next_transition"]
            next_date = next_t.get("date")
            if next_date:
                if isinstance(next_date, str):
                    next_dt = datetime.fromisoformat(next_date.replace("Z", "+00:00"))
                else:
                    next_dt = next_date
                days_until = (next_dt.replace(tzinfo=None) - target_date).days
                return {
                    "date": next_dt.isoformat() if hasattr(next_dt, "isoformat") else str(next_dt),
                    "daysUntil": max(0, days_until),
                    "level": next_t.get("level", "mahadasha"),
                    "from": next_t.get("from_lord", ""),
                    "to": next_t.get("to_lord", ""),
                    "summary": f"{next_t.get('to_lord', 'New')} period begins",
                }
    except Exception:
        pass
    return None


def _get_upcoming_markers(target_date: datetime, days: int = 14) -> List[Dict[str, Any]]:
    """Generate upcoming intensity markers for the next N days."""
    markers = []
    for i in range(days):
        date = target_date + timedelta(days=i)
        # Simple intensity calculation based on day of week and lunar cycle approximation
        day_factor = 0.3 if date.weekday() in [5, 6] else 0.5  # Weekends lower intensity
        lunar_factor = 0.5 + 0.3 * abs((date.timetuple().tm_yday % 29) / 29 - 0.5)
        intensity = round(day_factor + lunar_factor, 2)

        markers.append(
            {
                "date": date.strftime("%Y-%m-%d"),
                "dayOfWeek": date.strftime("%a"),
                "intensity": min(1.0, intensity),
                "label": "ease" if intensity < 0.5 else ("effort" if intensity < 0.75 else "intensity"),
            }
        )
    return markers


def _calculate_planet_strength(planet_data: Dict[str, Any], moon_phase: float = 0.5) -> str:
    """Calculate if planet is in strong, neutral, or weak position."""
    if not planet_data:
        return "neutral"

    speed = planet_data.get("speed", 0.5)
    retrograde = planet_data.get("retrograde", False)

    # Retrograde generally weakens
    if retrograde:
        return "weak"

    # High speed = strong influence
    if abs(speed) > 0.7:
        return "strong"
    elif abs(speed) < 0.3:
        return "weak"

    return "neutral"


def _detect_aspects(planets: Dict[str, Any], target_planet: str) -> List[Dict[str, Any]]:
    """Detect major aspects to a target planet."""
    aspects = []
    if target_planet not in planets:
        return aspects

    target_lon = planets[target_planet].get("longitude", 0)

    aspect_orbs = {
        "conjunction": (0, 8),
        "sextile": (60, 6),
        "square": (90, 7),
        "trine": (120, 8),
        "opposition": (180, 8),
    }

    for other_planet, data in planets.items():
        if other_planet == target_planet or not isinstance(data, dict):
            continue

        other_lon = data.get("longitude", 0)
        diff = abs(target_lon - other_lon)
        if diff > 180:
            diff = 360 - diff

        for aspect_name, (angle, orb) in aspect_orbs.items():
            if abs(diff - angle) <= orb:
                aspects.append(
                    {
                        "planet": other_planet.capitalize(),
                        "aspect": ASPECT_MEANINGS[aspect_name]["label"],
                        "nature": ASPECT_MEANINGS[aspect_name]["nature"],
                    }
                )
                break

    return aspects


def _generate_domain_insights(planets: Dict[str, Any], moon_phase: float = 0.5) -> List[Dict[str, Any]]:
    """Generate insights for all 7 life domains based on planetary positions."""
    import random
    import uuid

    insights = []

    for domain_key, domain_config in LIFE_DOMAINS.items():
        # Calculate domain intensity based on ruling planets
        ruling_planets = domain_config["planets"]
        total_strength = 0.0
        drivers = []

        for planet_name in ruling_planets:
            planet_data = planets.get(planet_name, {})
            if not isinstance(planet_data, dict):
                continue

            strength = _calculate_planet_strength(planet_data, moon_phase)
            strength_value = {"strong": 0.9, "neutral": 0.5, "weak": 0.3}.get(strength, 0.5)
            total_strength += strength_value

            # Get planet meaning
            planet_meanings = PLANET_MEANINGS.get(planet_name, {})
            explanation = planet_meanings.get(strength, planet_meanings.get("neutral", ""))

            # Check for aspects
            aspects = _detect_aspects(planets, planet_name)
            aspect_str = None
            if aspects:
                primary_aspect = aspects[0]
                aspect_str = f"{primary_aspect['aspect']} {primary_aspect['planet']}"
                # Modify explanation based on aspect
                if primary_aspect["nature"] == "harmonious":
                    explanation += " Supportive planetary alignment enhances this energy."
                elif primary_aspect["nature"] == "challenging":
                    explanation += " Work through any resistance for growth."

            drivers.append(
                {
                    "id": str(uuid.uuid4()),
                    "planet": planet_name.capitalize(),
                    "aspect": aspect_str,
                    "sign": planet_data.get("sign"),
                    "explanation": explanation,
                }
            )

        # Calculate intensity (0.0 to 1.0)
        intensity = min(1.0, total_strength / max(len(ruling_planets), 1))

        # Select appropriate insight based on intensity
        if intensity >= 0.7:
            level = "high"
        elif intensity >= 0.4:
            level = "medium"
        else:
            level = "low"

        domain_texts = DOMAIN_INSIGHTS.get(domain_key, DOMAIN_INSIGHTS["personal"])
        short_insight = random.choice(domain_texts.get(level, domain_texts["medium"]))

        # Generate full insight
        full_insight = _generate_full_insight(domain_key, drivers, intensity)

        insights.append(
            {
                "id": str(uuid.uuid4()),
                "domain": domain_key,
                "shortInsight": short_insight,
                "fullInsight": full_insight,
                "drivers": drivers,
                "intensity": round(intensity, 2),
            }
        )

    return insights


def _generate_full_insight(domain: str, drivers: List[Dict[str, Any]], intensity: float) -> str:
    """Generate a detailed paragraph insight for a domain."""
    domain_config = LIFE_DOMAINS.get(domain, {})
    display_name = domain_config.get("displayName", domain.capitalize())

    # Build insight based on drivers
    if intensity >= 0.7:
        opener = f"Today's planetary alignments strongly support your {display_name.lower()} life."
        tone = "excellent"
    elif intensity >= 0.4:
        opener = f"Moderate cosmic energy flows through your {display_name.lower()} sector today."
        tone = "good"
    else:
        opener = f"A gentler day for {display_name.lower()} matters calls for patience and reflection."
        tone = "gentle"

    # Add driver-specific content
    driver_sentences = []
    for driver in drivers[:2]:  # Use top 2 drivers
        planet = driver["planet"]
        sign = driver.get("sign", "")
        aspect = driver.get("aspect")

        if aspect:
            driver_sentences.append(f"{planet} {aspect} brings {'supportive' if 'trine' in (aspect or '').lower() or 'sextile' in (aspect or '').lower() else 'dynamic'} energy.")
        elif sign:
            driver_sentences.append(f"{planet} in {sign} influences how you approach this area.")

    middle = " ".join(driver_sentences) if driver_sentences else ""

    # Closing advice
    if tone == "excellent":
        closer = "Take action on important matters in this area."
    elif tone == "good":
        closer = "Steady progress is available through mindful attention."
    else:
        closer = "Focus on maintenance rather than major initiatives."

    return f"{opener} {middle} {closer}".strip()


def _get_cosmic_weather(planets: Dict[str, Any], moon_phase: float, target_date: datetime) -> Dict[str, Any]:
    """Generate cosmic weather summary for the day."""
    # Determine dominant planet
    max_speed = 0
    dominant = "Sun"
    for name, data in planets.items():
        if isinstance(data, dict):
            speed = abs(data.get("speed", 0))
            if speed > max_speed and name not in ["rahu", "ketu"]:
                max_speed = speed
                dominant = name.capitalize()

    # Determine mood
    retrograde_count = sum(1 for p in planets.values() if isinstance(p, dict) and p.get("retrograde", False))
    if retrograde_count >= 3:
        mood = "reflective"
        summary = "Multiple retrograde planets encourage introspection and revisiting past matters. Take time to review before moving forward."
    elif moon_phase > 0.45 and moon_phase < 0.55:
        mood = "illuminating"
        summary = "The Full Moon illuminates your path with clarity. Emotions run high but insights flow freely. Culminations and completions are favored."
    elif moon_phase < 0.1 or moon_phase > 0.9:
        mood = "initiating"
        summary = "The New Moon phase supports fresh starts and new intentions. Plant seeds for what you wish to grow."
    else:
        mood = "harmonious"
        summary = "A balanced day of cosmic harmony awaits. The planets support steady progress across all areas of life."

    # Moon phase name
    if moon_phase < 0.03:
        phase_name = "New Moon"
    elif moon_phase < 0.25:
        phase_name = "Waxing Crescent"
    elif moon_phase < 0.28:
        phase_name = "First Quarter"
    elif moon_phase < 0.47:
        phase_name = "Waxing Gibbous"
    elif moon_phase < 0.53:
        phase_name = "Full Moon"
    elif moon_phase < 0.75:
        phase_name = "Waning Gibbous"
    elif moon_phase < 0.78:
        phase_name = "Last Quarter"
    else:
        phase_name = "Waning Crescent"

    return {
        "date": target_date.strftime("%Y-%m-%d"),
        "summary": summary,
        "mood": mood,
        "dominantPlanet": dominant,
        "moonPhase": phase_name,
    }


@discover_bp.route("/domains", methods=["GET", "POST"])
def discover_domains():
    """
    Get life domain insights with planetary drivers.

    Returns insights for all 7 life domains (personal, love, career,
    wealth, health, family, spiritual) based on current planetary positions.
    """
    payload = request.get_json(silent=True) or {}

    # Parse target date
    date_str = payload.get("targetDate") or request.args.get("date")
    if date_str:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400
    else:
        target_date = datetime.utcnow()

    # Get current planetary positions
    positions = _ephem.get_positions_for_date(target_date)
    planets = positions.get("planets", {})
    moon_phase = positions.get("moon_phase", 0.5)

    # Generate domain insights
    domain_insights = _generate_domain_insights(planets, moon_phase)

    # Generate cosmic weather
    cosmic_weather = _get_cosmic_weather(planets, moon_phase, target_date)

    # Get daily horoscope (optional, for the weather header)
    sun_sign = planets.get("sun", {}).get("sign", "aries").lower() if isinstance(planets.get("sun"), dict) else "aries"
    from routes.horoscope import _generate_horoscope

    horoscope_content, _ = _generate_horoscope(sun_sign, target_date, "daily", None)

    return jsonify(
        {
            "date": target_date.strftime("%Y-%m-%d"),
            "domains": domain_insights,
            "cosmicWeather": cosmic_weather,
            "dailyHoroscope": horoscope_content,
            "disclaimer": "For entertainment purposes only. Not professional advice.",
        }
    )


@discover_bp.route("/snapshot", methods=["POST"])
def discover_snapshot():
    """
    Get unified Discover snapshot for daily check-in.

    POST body:
    {
        "userId": "optional-user-id",
        "birthData": {
            "date": "1990-08-15",
            "time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060
        },
        "targetDate": "2025-01-15"  // optional, defaults to today
    }
    """
    payload = request.get_json(silent=True) or {}

    # Parse target date
    date_str = payload.get("targetDate")
    if date_str:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400
    else:
        target_date = datetime.utcnow()

    # Get birth data from payload or user_id
    birth_data = payload.get("birthData")
    user_id = payload.get("userId")

    if not birth_data and user_id:
        birth_data = get_user_birth_data(user_id)
        if birth_data:
            birth_data = {
                "date": birth_data.get("birth_date"),
                "time": birth_data.get("birth_time", "12:00"),
                "timezone": birth_data.get("timezone", "UTC"),
                "latitude": birth_data.get("latitude"),
                "longitude": birth_data.get("longitude"),
            }

    # Get current planetary positions
    positions = _ephem.get_positions_for_date(target_date)
    planets = positions.get("planets", {})
    moon_phase = positions.get("moon_phase", 0.5)

    # Determine sun sign (for horoscope)
    sun_sign = planets.get("sun", {}).get("sign", "aries").lower()

    # Calculate core metrics
    energy_state = _calculate_energy_state(planets, moon_phase)
    domain_weights = _calculate_domain_weights(planets, sun_sign)

    # Import horoscope generation
    from routes.horoscope import SIGN_TRAITS, _generate_horoscope

    traits = SIGN_TRAITS.get(sun_sign, SIGN_TRAITS["aries"])

    # Generate horoscope content
    natal_planets = None
    if birth_data:
        try:
            bd = birth_data["date"]
            bt = birth_data.get("time", "12:00")
            tz = birth_data.get("timezone", "UTC")
            lat = birth_data.get("latitude")
            lon = birth_data.get("longitude")

            bd_local = datetime.strptime(f"{bd}T{bt}", "%Y-%m-%dT%H:%M")
            bd_utc = bd_local.replace(tzinfo=ZoneInfo(tz)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
            natal_positions = _ephem.get_positions_for_date(bd_utc, lat, lon)
            natal_planets = natal_positions.get("planets", {})
        except Exception:
            pass

    horoscope_content, lucky_elements = _generate_horoscope(sun_sign, target_date, "daily", natal_planets)

    # Generate narrative tiles
    narrative_tiles = _generate_narrative_tiles(horoscope_content, planets, domain_weights)

    # Generate actions
    actions = _generate_actions(energy_state, domain_weights)

    # Get next dasha shift if birth data available
    next_shift = None
    if birth_data and natal_planets:
        try:
            moon_lon = natal_planets.get("moon", {}).get("longitude", 0)
            bd = birth_data["date"]
            bt = birth_data.get("time", "12:00")
            bd_dt = datetime.strptime(f"{bd}T{bt}", "%Y-%m-%dT%H:%M")
            next_shift = _get_next_shift(bd_dt, moon_lon, target_date)
        except Exception:
            pass

    # Build response
    response = {
        "date": target_date.strftime("%Y-%m-%d"),
        "sign": sun_sign,
        "personalized": natal_planets is not None,
        # Now layer
        "now": {
            "theme": horoscope_content.split(".")[0] + "." if "." in horoscope_content else horoscope_content,
            "narrativeTiles": narrative_tiles,
            "actions": actions,
        },
        # Cosmic Lens data
        "lens": {
            "energyState": {
                "id": energy_state,
                "label": energy_state.capitalize(),
                "description": ENERGY_STATES[energy_state]["description"],
                "icon": ENERGY_STATES[energy_state]["icon"],
            },
            "domainWeights": domain_weights,
            "activations": [
                {
                    "type": "transit",
                    "planet": name,
                    "sign": data.get("sign", ""),
                    "speed": data.get("speed", 0),
                }
                for name, data in planets.items()
                if isinstance(data, dict) and name in ["sun", "moon", "mercury", "venus", "mars"]
            ],
        },
        # Next layer
        "next": {
            "shift": next_shift,
            "markers": _get_upcoming_markers(target_date, 14),
        },
        # Lucky elements
        "lucky": lucky_elements,
        # Keywords for display
        "keywords": traits.get("keywords", []),
        # Cache hints
        "cacheHints": {
            "ttlSeconds": 3600,  # 1 hour
            "nextRefresh": (target_date + timedelta(hours=1)).isoformat(),
        },
    }

    return jsonify(response)


@discover_bp.route("/snapshot", methods=["GET"])
def discover_snapshot_get():
    """GET version for simple queries without birth data."""
    sign = request.args.get("sign", "aries").lower()
    date_str = request.args.get("date")

    if date_str:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400
    else:
        target_date = datetime.utcnow()

    # Get current planetary positions
    positions = _ephem.get_positions_for_date(target_date)
    planets = positions.get("planets", {})
    moon_phase = positions.get("moon_phase", 0.5)

    # Calculate metrics
    energy_state = _calculate_energy_state(planets, moon_phase)
    domain_weights = _calculate_domain_weights(planets, sign)

    # Import horoscope generation
    from routes.horoscope import SIGN_TRAITS, _generate_horoscope

    traits = SIGN_TRAITS.get(sign, SIGN_TRAITS["aries"])
    horoscope_content, lucky_elements = _generate_horoscope(sign, target_date, "daily", None)

    # Generate tiles and actions
    narrative_tiles = _generate_narrative_tiles(horoscope_content, planets, domain_weights)
    actions = _generate_actions(energy_state, domain_weights)

    response = {
        "date": target_date.strftime("%Y-%m-%d"),
        "sign": sign,
        "personalized": False,
        "now": {
            "theme": horoscope_content.split(".")[0] + "." if "." in horoscope_content else horoscope_content,
            "narrativeTiles": narrative_tiles,
            "actions": actions,
        },
        "lens": {
            "energyState": {
                "id": energy_state,
                "label": energy_state.capitalize(),
                "description": ENERGY_STATES[energy_state]["description"],
                "icon": ENERGY_STATES[energy_state]["icon"],
            },
            "domainWeights": domain_weights,
            "activations": [
                {
                    "type": "transit",
                    "planet": name,
                    "sign": data.get("sign", ""),
                    "speed": data.get("speed", 0),
                }
                for name, data in planets.items()
                if isinstance(data, dict) and name in ["sun", "moon", "mercury", "venus", "mars"]
            ],
        },
        "next": {
            "shift": None,
            "markers": _get_upcoming_markers(target_date, 14),
        },
        "lucky": lucky_elements,
        "keywords": traits.get("keywords", []),
        "cacheHints": {
            "ttlSeconds": 3600,
            "nextRefresh": (target_date + timedelta(hours=1)).isoformat(),
        },
    }

    return jsonify(response)
