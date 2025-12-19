from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Optional

from flask import Blueprint, g, jsonify, request

import db
from middleware import require_auth
from services.ephemeris_service import EphemerisService
from services.transit_service import TransitService
from utils.birth_data import parse_birth_data, BirthDataError

compat_bp = Blueprint("compatibility", __name__)
logger = logging.getLogger(__name__)

_ephem = EphemerisService()
_transit = TransitService(_ephem)


def _get_user_id() -> Optional[str]:
    """Get user_id from request headers or body."""
    data = request.get_json(silent=True) or {}
    return data.get("userId") or request.headers.get("X-User-Id")

# Sign compatibility matrix (0-100)
SIGN_COMPATIBILITY = {
    "Aries": {
        "Aries": 70,
        "Taurus": 50,
        "Gemini": 85,
        "Cancer": 45,
        "Leo": 95,
        "Virgo": 40,
        "Libra": 70,
        "Scorpio": 60,
        "Sagittarius": 95,
        "Capricorn": 45,
        "Aquarius": 85,
        "Pisces": 60,
    },
    "Taurus": {
        "Aries": 50,
        "Taurus": 80,
        "Gemini": 55,
        "Cancer": 95,
        "Leo": 60,
        "Virgo": 95,
        "Libra": 65,
        "Scorpio": 90,
        "Sagittarius": 50,
        "Capricorn": 95,
        "Aquarius": 50,
        "Pisces": 85,
    },
    "Gemini": {
        "Aries": 85,
        "Taurus": 55,
        "Gemini": 75,
        "Cancer": 60,
        "Leo": 90,
        "Virgo": 65,
        "Libra": 95,
        "Scorpio": 55,
        "Sagittarius": 90,
        "Capricorn": 50,
        "Aquarius": 95,
        "Pisces": 60,
    },
    "Cancer": {
        "Aries": 45,
        "Taurus": 95,
        "Gemini": 60,
        "Cancer": 80,
        "Leo": 65,
        "Virgo": 90,
        "Libra": 60,
        "Scorpio": 95,
        "Sagittarius": 55,
        "Capricorn": 85,
        "Aquarius": 50,
        "Pisces": 95,
    },
    "Leo": {
        "Aries": 95,
        "Taurus": 60,
        "Gemini": 90,
        "Cancer": 65,
        "Leo": 75,
        "Virgo": 60,
        "Libra": 90,
        "Scorpio": 65,
        "Sagittarius": 95,
        "Capricorn": 50,
        "Aquarius": 85,
        "Pisces": 70,
    },
    "Virgo": {
        "Aries": 40,
        "Taurus": 95,
        "Gemini": 65,
        "Cancer": 90,
        "Leo": 60,
        "Virgo": 80,
        "Libra": 70,
        "Scorpio": 90,
        "Sagittarius": 60,
        "Capricorn": 95,
        "Aquarius": 60,
        "Pisces": 85,
    },
    "Libra": {
        "Aries": 70,
        "Taurus": 65,
        "Gemini": 95,
        "Cancer": 60,
        "Leo": 90,
        "Virgo": 70,
        "Libra": 80,
        "Scorpio": 65,
        "Sagittarius": 85,
        "Capricorn": 60,
        "Aquarius": 95,
        "Pisces": 70,
    },
    "Scorpio": {
        "Aries": 60,
        "Taurus": 90,
        "Gemini": 55,
        "Cancer": 95,
        "Leo": 65,
        "Virgo": 90,
        "Libra": 65,
        "Scorpio": 85,
        "Sagittarius": 70,
        "Capricorn": 90,
        "Aquarius": 60,
        "Pisces": 95,
    },
    "Sagittarius": {
        "Aries": 95,
        "Taurus": 50,
        "Gemini": 90,
        "Cancer": 55,
        "Leo": 95,
        "Virgo": 60,
        "Libra": 85,
        "Scorpio": 70,
        "Sagittarius": 80,
        "Capricorn": 60,
        "Aquarius": 90,
        "Pisces": 65,
    },
    "Capricorn": {
        "Aries": 45,
        "Taurus": 95,
        "Gemini": 50,
        "Cancer": 85,
        "Leo": 50,
        "Virgo": 95,
        "Libra": 60,
        "Scorpio": 90,
        "Sagittarius": 60,
        "Capricorn": 80,
        "Aquarius": 65,
        "Pisces": 85,
    },
    "Aquarius": {
        "Aries": 85,
        "Taurus": 50,
        "Gemini": 95,
        "Cancer": 50,
        "Leo": 85,
        "Virgo": 60,
        "Libra": 95,
        "Scorpio": 60,
        "Sagittarius": 90,
        "Capricorn": 65,
        "Aquarius": 75,
        "Pisces": 70,
    },
    "Pisces": {
        "Aries": 60,
        "Taurus": 85,
        "Gemini": 60,
        "Cancer": 95,
        "Leo": 70,
        "Virgo": 85,
        "Libra": 70,
        "Scorpio": 95,
        "Sagittarius": 65,
        "Capricorn": 85,
        "Aquarius": 70,
        "Pisces": 80,
    },
}

# Element compatibility
ELEMENT_SIGNS = {
    "Fire": ["Aries", "Leo", "Sagittarius"],
    "Earth": ["Taurus", "Virgo", "Capricorn"],
    "Air": ["Gemini", "Libra", "Aquarius"],
    "Water": ["Cancer", "Scorpio", "Pisces"],
}

# Reverse lookup for sign to element
SIGN_TO_ELEMENT = {}
for element, signs in ELEMENT_SIGNS.items():
    for sign in signs:
        SIGN_TO_ELEMENT[sign] = element


def _parse_birth_data(data: dict, key: str = "birthData") -> tuple[datetime, float, float]:
    """Parse birth data from nested structure using shared utility."""
    try:
        return parse_birth_data(data, key=key, require_coords=True, include_timezone=False)
    except BirthDataError as e:
        raise ValueError(str(e))


def _positions_to_chart(positions: dict) -> dict:
    """Convert ephemeris positions to chart format."""
    result = {}
    for name, info in positions.get("planets", {}).items():
        key = name.title()
        result[key] = {
            "degree": float(info.get("degree", 0.0)),
            "sign": str(info.get("sign", "Unknown")),
            "longitude": float(info.get("longitude", 0.0)),
        }
    return result


def _calculate_sun_sign_compatibility(user_sun_sign: str, partner_sun_sign: str) -> float:
    """Calculate sun sign compatibility score (0-100)."""
    if user_sun_sign in SIGN_COMPATIBILITY and partner_sun_sign in SIGN_COMPATIBILITY[user_sun_sign]:
        return float(SIGN_COMPATIBILITY[user_sun_sign][partner_sun_sign])
    return 50.0  # Default neutral score


def _calculate_moon_compatibility(user_moon_sign: str, partner_moon_sign: str) -> float:
    """Calculate moon sign compatibility score (0-100)."""
    # Moon compatibility is crucial for emotional connection
    base_score = _calculate_sun_sign_compatibility(user_moon_sign, partner_moon_sign)

    # Bonus for same element
    user_element = SIGN_TO_ELEMENT.get(user_moon_sign)
    partner_element = SIGN_TO_ELEMENT.get(partner_moon_sign)

    if user_element == partner_element:
        base_score = min(100, base_score + 10)
    elif (user_element in ["Fire", "Air"] and partner_element in ["Fire", "Air"]) or (
        user_element in ["Earth", "Water"] and partner_element in ["Earth", "Water"]
    ):
        base_score = min(100, base_score + 5)

    return base_score


def _calculate_venus_mars_compatibility(user_chart: dict, partner_chart: dict) -> float:
    """Calculate Venus/Mars compatibility for romantic attraction."""
    score = 0.0
    count = 0

    # Check user's Venus with partner's Mars (attraction)
    if "Venus" in user_chart and "Mars" in partner_chart:
        venus_sign = user_chart["Venus"]["sign"]
        mars_sign = partner_chart["Mars"]["sign"]
        score += _calculate_sun_sign_compatibility(venus_sign, mars_sign)
        count += 1

    # Check partner's Venus with user's Mars (attraction)
    if "Venus" in partner_chart and "Mars" in user_chart:
        venus_sign = partner_chart["Venus"]["sign"]
        mars_sign = user_chart["Mars"]["sign"]
        score += _calculate_sun_sign_compatibility(venus_sign, mars_sign)
        count += 1

    # Check Venus-Venus compatibility (shared values)
    if "Venus" in user_chart and "Venus" in partner_chart:
        user_venus = user_chart["Venus"]["sign"]
        partner_venus = partner_chart["Venus"]["sign"]
        score += _calculate_sun_sign_compatibility(user_venus, partner_venus)
        count += 1

    return score / count if count > 0 else 50.0


def _calculate_ascendant_compatibility(user_chart: dict, partner_chart: dict) -> float:
    """Calculate ascendant compatibility for overall harmony."""
    if "Ascendant" not in user_chart or "Ascendant" not in partner_chart:
        return 60.0  # Default if no ascendant data

    user_asc = user_chart["Ascendant"]["sign"]
    partner_asc = partner_chart["Ascendant"]["sign"]

    return _calculate_sun_sign_compatibility(user_asc, partner_asc)


def _calculate_synastry_aspects(user_chart: dict, partner_chart: dict) -> list[dict]:
    """Calculate synastry aspects between two charts."""
    aspects = []

    # Define aspect angles and their compatibility impact
    aspect_types = {
        "conjunction": (0, 8, 1.0),  # 0° ± 8°, strong influence
        "sextile": (60, 6, 0.8),  # 60° ± 6°, harmonious
        "square": (90, 7, -0.6),  # 90° ± 7°, challenging
        "trine": (120, 8, 1.0),  # 120° ± 8°, very harmonious
        "opposition": (180, 8, -0.4),  # 180° ± 8°, tension
    }

    # Important planetary pairings for synastry
    important_planets = ["Sun", "Moon", "Venus", "Mars", "Mercury", "Jupiter"]

    for user_planet in important_planets:
        if user_planet not in user_chart:
            continue

        user_lon = user_chart[user_planet].get("longitude", 0)

        for partner_planet in important_planets:
            if partner_planet not in partner_chart:
                continue

            partner_lon = partner_chart[partner_planet].get("longitude", 0)

            # Calculate angular difference
            diff = abs((user_lon - partner_lon + 180) % 360 - 180)

            # Check for aspects
            for aspect_name, (angle, orb, compatibility) in aspect_types.items():
                delta = abs(diff - angle)

                if delta <= orb:
                    aspects.append(
                        {
                            "planet1": user_planet,
                            "planet2": partner_planet,
                            "aspect": aspect_name,
                            "orb": round(delta, 2),
                            "compatibility": compatibility,
                            "description": f"{user_planet} {aspect_name} {partner_planet}",
                        }
                    )

    return aspects


def _calculate_overall_score(
    sun_score: float, moon_score: float, venus_mars_score: float, asc_score: float, aspects: list[dict]
) -> float:
    """Calculate weighted overall compatibility score."""
    # Base scores with weights
    weighted_score = (
        sun_score * 0.25  # 25% Sun sign
        + moon_score * 0.30  # 30% Moon sign (emotions)
        + venus_mars_score * 0.25  # 25% Venus/Mars (attraction)
        + asc_score * 0.20  # 20% Ascendant (overall harmony)
    )

    # Adjust based on synastry aspects
    if aspects:
        aspect_bonus = sum(a.get("compatibility", 0) for a in aspects) / len(aspects) * 5
        weighted_score = max(0, min(100, weighted_score + aspect_bonus))

    return round(weighted_score, 1)


def _calculate_vedic_score(user_chart: dict, partner_chart: dict) -> float:
    """Calculate Vedic astrology compatibility score (simplified Kuta system)."""
    # Simplified Vedic compatibility based on Moon signs and nakshatra principles
    if "Moon" not in user_chart or "Moon" not in partner_chart:
        return 50.0

    user_moon_sign = user_chart["Moon"]["sign"]
    partner_moon_sign = partner_chart["Moon"]["sign"]

    # Base score on moon sign compatibility
    base_score = _calculate_moon_compatibility(user_moon_sign, partner_moon_sign)

    # Adjust for element harmony (simplified Gana Kuta)
    user_element = SIGN_TO_ELEMENT.get(user_moon_sign)
    partner_element = SIGN_TO_ELEMENT.get(partner_moon_sign)

    if user_element == partner_element:
        base_score = min(100, base_score + 10)

    # Scale to typical Vedic range (often out of 36)
    vedic_score = (base_score / 100) * 36

    return round(vedic_score, 1)


def _calculate_chinese_score(user_dt: datetime, partner_dt: datetime) -> float:
    """Calculate Chinese zodiac compatibility score."""
    # Chinese zodiac animals

    # Calculate Chinese zodiac year
    user_animal_idx = (user_dt.year - 4) % 12
    partner_animal_idx = (partner_dt.year - 4) % 12

    # Compatibility matrix (simplified)
    # Most compatible: 4 years apart (trine), Least compatible: 6 years apart (opposite)
    year_diff = abs(user_animal_idx - partner_animal_idx)

    if year_diff == 0:
        score = 75  # Same sign - understanding but may clash
    elif year_diff in [4, 8]:
        score = 95  # Trine - very compatible
    elif year_diff == 6:
        score = 50  # Opposite - challenging
    elif year_diff in [1, 5, 7, 11]:
        score = 70  # Neutral to good
    else:
        score = 80  # Generally compatible

    return float(score)


def _chart_to_client_format(chart: dict) -> dict:
    """Convert chart to client expected format: {planet: {attribute: value}}."""
    result = {}
    for planet, info in chart.items():
        result[planet] = {"degree": info.get("degree", 0.0), "longitude": info.get("longitude", 0.0)}
    return result


@compat_bp.route("", methods=["POST"])
def compatibility():
    """Calculate comprehensive compatibility between two birth charts."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    try:
        # Support both 'person1/person2' (client format) and 'userBirthData/partnerBirthData'
        if "person1" in data and "person2" in data:
            # Client sends flat structure with person1/person2
            user_data = {"birthData": data["person1"]}
            partner_data = {"birthData": data["person2"]}
        elif "user" in data and "partner" in data:
            # OpenAPI format: user/partner objects contain birth fields (and optional name)
            user_data = {"birthData": data["user"]}
            partner_data = {"birthData": data["partner"]}
        elif "userBirthData" in data and "partnerBirthData" in data:
            user_data = data
            partner_data = data
            user_data = {"birthData": data["userBirthData"]}
            partner_data = {"birthData": data["partnerBirthData"]}
        else:
            raise ValueError("Request must contain either (person1, person2) or (userBirthData, partnerBirthData)")

        # Parse both birth data sets
        user_dt, user_lat, user_lon = _parse_birth_data(user_data, "birthData")
        partner_dt, partner_lat, partner_lon = _parse_birth_data(partner_data, "birthData")

    except ValueError as e:
        return jsonify({"error": str(e), "code": "VALIDATION_ERROR"}), 400
    except Exception as e:
        logger.error(f"Error parsing birth data: {e}", exc_info=True)
        return jsonify({"error": "Invalid request format", "code": "INVALID_REQUEST"}), 400

    try:
        # Get planetary positions for both charts
        user_positions = _ephem.get_positions_for_date(user_dt, user_lat, user_lon)
        partner_positions = _ephem.get_positions_for_date(partner_dt, partner_lat, partner_lon)

        user_chart = _positions_to_chart(user_positions)
        partner_chart = _positions_to_chart(partner_positions)

        # Calculate individual compatibility scores
        sun_score = _calculate_sun_sign_compatibility(
            user_chart.get("Sun", {}).get("sign", "Aries"), partner_chart.get("Sun", {}).get("sign", "Aries")
        )

        moon_score = _calculate_moon_compatibility(
            user_chart.get("Moon", {}).get("sign", "Aries"), partner_chart.get("Moon", {}).get("sign", "Aries")
        )

        venus_mars_score = _calculate_venus_mars_compatibility(user_chart, partner_chart)
        asc_score = _calculate_ascendant_compatibility(user_chart, partner_chart)

        # Calculate synastry aspects
        synastry_aspects = _calculate_synastry_aspects(user_chart, partner_chart)

        # Calculate overall score
        overall_score = _calculate_overall_score(sun_score, moon_score, venus_mars_score, asc_score, synastry_aspects)

        # Calculate Vedic and Chinese scores
        vedic_score = _calculate_vedic_score(user_chart, partner_chart)
        chinese_score = _calculate_chinese_score(user_dt, partner_dt)

        # Format synastry aspects as strings for client (expects array of strings)
        aspect_strings = [a["description"] for a in synastry_aspects]

        # Convert charts to client expected format
        user_chart_formatted = _chart_to_client_format(user_chart)
        partner_chart_formatted = _chart_to_client_format(partner_chart)

        return jsonify(
            {
                "overallIntensity": _score_to_intensity(int(round(overall_score))),
                "vedicIntensity": _score_to_intensity(int(round(vedic_score))),
                "chineseIntensity": _score_to_intensity(int(round(chinese_score))),
                "synastryAspects": aspect_strings,
                "userChart": user_chart_formatted,
                "partnerChart": partner_chart_formatted,
                "disclaimer": "For entertainment purposes only. Not professional advice.",
            }
        )

    except Exception as e:
        logger.error(f"Error calculating compatibility: {e}", exc_info=True)
        return jsonify({"error": "Failed to calculate compatibility", "code": "CALCULATION_ERROR"}), 500


# =============================================================================
# Relationship CRUD Endpoints
# =============================================================================


@compat_bp.route("/relationships", methods=["GET"])
@require_auth
def list_relationships():
    """List all relationships for the current user."""
    user_id = g.user_id

    relationships = db.get_user_relationships(user_id)

    # Transform to client format with sun/moon signs computed
    result = []
    for rel in relationships:
        # Calculate sun sign from birth date for display
        sun_sign = "Unknown"
        moon_sign = "Unknown"
        try:
            birth_dt = datetime.fromisoformat(rel["partnerBirthDate"].replace("Z", "+00:00"))
            lat = rel.get("partnerLatitude") or 0.0
            lon = rel.get("partnerLongitude") or 0.0
            positions = _ephem.get_positions_for_date(birth_dt, lat, lon)
            chart = _positions_to_chart(positions)
            sun_sign = chart.get("Sun", {}).get("sign", "Unknown")
            moon_sign = chart.get("Moon", {}).get("sign", "Unknown")
        except Exception as e:
            logger.warning(f"Could not compute signs for relationship {rel['id']}: {e}")

        result.append(
            {
                "id": rel["id"],
                "name": rel["partnerName"],
                "avatarUrl": rel.get("partnerAvatarUrl"),
                "sunSign": sun_sign,
                "moonSign": moon_sign,
                "risingSign": None,  # Would need birth time + location
                "birthDate": rel["partnerBirthDate"],
                "sharedSignature": None,  # Computed on demand
                "lastPulse": None,  # Computed on demand
                "lastViewed": rel.get("lastViewedAt"),
                "isFavorite": rel.get("isFavorite", False),
            }
        )

    return jsonify({"relationships": result})


@compat_bp.route("/relationships", methods=["POST"])
@require_auth
def create_relationship():
    """Create a new relationship."""
    user_id = g.user_id

    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Request body required", "code": "INVALID_JSON"}), 400

    partner_name = data.get("partnerName") or data.get("name")
    partner_birth_date = data.get("partnerBirthDate") or data.get("birthDate")

    if not partner_name or not partner_birth_date:
        return jsonify({"error": "partnerName and partnerBirthDate are required", "code": "VALIDATION_ERROR"}), 400

    try:
        relationship = db.create_relationship(
            user_id=user_id,
            partner_name=partner_name,
            partner_birth_date=partner_birth_date,
            partner_birth_time=data.get("partnerBirthTime") or data.get("birthTime"),
            partner_timezone=data.get("partnerTimezone") or data.get("timezone"),
            partner_latitude=data.get("partnerLatitude") or data.get("latitude"),
            partner_longitude=data.get("partnerLongitude") or data.get("longitude"),
            partner_location_name=data.get("partnerLocationName") or data.get("locationName"),
            partner_avatar_url=data.get("partnerAvatarUrl") or data.get("avatarUrl"),
        )

        # Calculate sun/moon signs for response
        sun_sign = "Unknown"
        moon_sign = "Unknown"
        try:
            birth_dt = datetime.fromisoformat(partner_birth_date.replace("Z", "+00:00"))
            lat = relationship.get("partnerLatitude") or 0.0
            lon = relationship.get("partnerLongitude") or 0.0
            positions = _ephem.get_positions_for_date(birth_dt, lat, lon)
            chart = _positions_to_chart(positions)
            sun_sign = chart.get("Sun", {}).get("sign", "Unknown")
            moon_sign = chart.get("Moon", {}).get("sign", "Unknown")
        except Exception as e:
            logger.warning(f"Could not compute signs: {e}")

        return (
            jsonify(
                {
                    "id": relationship["id"],
                    "name": relationship["partnerName"],
                    "avatarUrl": relationship.get("partnerAvatarUrl"),
                    "sunSign": sun_sign,
                    "moonSign": moon_sign,
                    "risingSign": None,
                    "birthDate": relationship["partnerBirthDate"],
                    "sharedSignature": None,
                    "lastPulse": None,
                    "lastViewed": None,
                    "isFavorite": False,
                }
            ),
            201,
        )
    except Exception as e:
        logger.error(f"Error creating relationship: {e}", exc_info=True)
        return jsonify({"error": "Failed to create relationship", "code": "CREATE_ERROR"}), 500


@compat_bp.route("/relationships/<relationship_id>", methods=["GET"])
@require_auth
def get_relationship(relationship_id: str):
    """Get a single relationship."""
    user_id = g.user_id

    relationship = db.get_relationship(relationship_id)
    if not relationship:
        return jsonify({"error": "Relationship not found", "code": "NOT_FOUND"}), 404

    if relationship["userId"] != user_id:
        return jsonify({"error": "Access denied", "code": "FORBIDDEN"}), 403

    return jsonify(relationship)


@compat_bp.route("/relationships/<relationship_id>", methods=["DELETE"])
@require_auth
def delete_relationship(relationship_id: str):
    """Delete a relationship."""
    user_id = g.user_id

    deleted = db.delete_relationship(relationship_id, user_id)
    if not deleted:
        return jsonify({"error": "Relationship not found or access denied", "code": "NOT_FOUND"}), 404

    return jsonify({"success": True}), 200


@compat_bp.route("/relationships/<relationship_id>/snapshot", methods=["GET"])
@require_auth
def get_compatibility_snapshot(relationship_id: str):
    """Get full compatibility snapshot for a relationship."""
    user_id = g.user_id

    # Get relationship
    relationship = db.get_relationship(relationship_id)
    if not relationship:
        return jsonify({"error": "Relationship not found", "code": "NOT_FOUND"}), 404

    if relationship["userId"] != user_id:
        return jsonify({"error": "Access denied", "code": "FORBIDDEN"}), 403

    # Get user's birth data
    user_birth = db.get_user_birth_data(user_id)
    if not user_birth:
        return jsonify({"error": "User birth data not found", "code": "NO_BIRTH_DATA"}), 400

    # Update last viewed
    db.update_relationship_last_viewed(relationship_id)

    # Optional date parameter for journey
    date_str = request.args.get("date")
    target_date = datetime.utcnow()
    if date_str:
        try:
            target_date = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        except ValueError:
            pass

    try:
        # Parse user birth data
        user_dt = datetime.fromisoformat(user_birth["birth_date"].replace("Z", "+00:00"))
        user_lat = user_birth.get("latitude") or 0.0
        user_lon = user_birth.get("longitude") or 0.0

        # Parse partner birth data
        partner_dt = datetime.fromisoformat(relationship["partnerBirthDate"].replace("Z", "+00:00"))
        partner_lat = relationship.get("partnerLatitude") or 0.0
        partner_lon = relationship.get("partnerLongitude") or 0.0

        # Get natal charts
        user_positions = _ephem.get_positions_for_date(user_dt, user_lat, user_lon)
        partner_positions = _ephem.get_positions_for_date(partner_dt, partner_lat, partner_lon)

        user_chart = _positions_to_chart(user_positions)
        partner_chart = _positions_to_chart(partner_positions)

        # Calculate synastry aspects
        synastry_aspects = _calculate_synastry_aspects(user_chart, partner_chart)

        # Calculate scores
        sun_score = _calculate_sun_sign_compatibility(
            user_chart.get("Sun", {}).get("sign", "Aries"), partner_chart.get("Sun", {}).get("sign", "Aries")
        )
        moon_score = _calculate_moon_compatibility(
            user_chart.get("Moon", {}).get("sign", "Aries"), partner_chart.get("Moon", {}).get("sign", "Aries")
        )
        venus_mars_score = _calculate_venus_mars_compatibility(user_chart, partner_chart)
        asc_score = _calculate_ascendant_compatibility(user_chart, partner_chart)
        overall_score = _calculate_overall_score(sun_score, moon_score, venus_mars_score, asc_score, synastry_aspects)

        # Build domain breakdown
        domain_breakdown = _build_domain_breakdown(user_chart, partner_chart, synastry_aspects)

        # Build synastry aspect objects for client (with transit activation check)
        synastry_data = _build_synastry_data(
            synastry_aspects, overall_score, domain_breakdown,
            target_date=target_date, natal_a=user_positions, natal_b=partner_positions
        )

        # Build natal placements for both (display format)
        natal_a = _build_natal_placements(user_chart)
        natal_b = _build_natal_placements(partner_chart)

        # Build composite chart (midpoints)
        composite = _build_composite_chart(user_chart, partner_chart)

        # Build relationship pulse (based on current transits)
        pulse = _calculate_relationship_pulse(
            synastry_aspects, target_date, natal_a=user_positions, natal_b=partner_positions
        )

        # Build shared insight
        shared_insight = _select_shared_insight(synastry_aspects, pulse)

        # Build next shift (based on real transit predictions)
        next_shift = _calculate_next_shift(
            synastry_aspects, target_date, natal_a=user_positions, natal_b=partner_positions
        )

        # Build journey forecast (based on real transit calculations)
        journey = _build_journey_forecast(
            synastry_aspects, target_date, natal_a=user_positions, natal_b=partner_positions
        )

        # Build share model
        share_model = _build_share_model(shared_insight, relationship)

        # Get user name from DB
        user_name = "You"

        snapshot = {
            "pair": {
                "idA": user_id,
                "idB": relationship_id,
                "nameA": user_name,
                "nameB": relationship["partnerName"],
                "avatarUrlA": None,
                "avatarUrlB": relationship.get("partnerAvatarUrl"),
                "sharedSignature": _generate_shared_signature(user_chart, partner_chart, synastry_aspects),
            },
            "natalA": natal_a,
            "natalB": natal_b,
            "synastry": synastry_data,
            "composite": composite,
            "now": {
                "pulse": pulse,
                "sharedInsight": shared_insight,
            },
            "next": next_shift,
            "journey": journey,
            "share": share_model,
            "disclaimer": "For entertainment purposes only. Not professional advice.",
        }

        return jsonify(snapshot)

    except Exception as e:
        logger.error(f"Error computing compatibility snapshot: {e}", exc_info=True)
        return jsonify({"error": "Failed to compute compatibility", "code": "CALCULATION_ERROR"}), 500


# =============================================================================
# Helper functions for snapshot building
# =============================================================================


def _build_natal_placements(chart: dict) -> dict:
    """Build natal placements in client format."""

    def _placement(planet_name: str) -> dict:
        info = chart.get(planet_name, {})
        return {
            "sign": info.get("sign", "Unknown"),
            "degree": info.get("degree", 0.0),
            "longitude": info.get("longitude", 0.0),
            "house": None,  # Would need house calculation
        }

    return {
        "sun": _placement("Sun"),
        "moon": _placement("Moon"),
        "mercury": _placement("Mercury"),
        "venus": _placement("Venus"),
        "mars": _placement("Mars"),
        "jupiter": _placement("Jupiter"),
        "saturn": _placement("Saturn"),
        "ascendant": _placement("Ascendant") if "Ascendant" in chart else None,
    }


def _build_composite_chart(user_chart: dict, partner_chart: dict) -> dict:
    """Build composite chart using midpoints."""

    def _midpoint(planet: str) -> dict:
        user_lon = user_chart.get(planet, {}).get("longitude", 0)
        partner_lon = partner_chart.get(planet, {}).get("longitude", 0)

        # Calculate midpoint (handling 360° wraparound)
        diff = abs(user_lon - partner_lon)
        if diff > 180:
            mid_lon = ((user_lon + partner_lon) / 2 + 180) % 360
        else:
            mid_lon = (user_lon + partner_lon) / 2

        # Determine sign
        sign_idx = int(mid_lon / 30)
        signs = [
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
        sign = signs[sign_idx % 12]
        degree = mid_lon % 30

        return {"sign": sign, "degree": round(degree, 2), "longitude": round(mid_lon, 2), "house": None}

    return {
        "sun": _midpoint("Sun"),
        "moon": _midpoint("Moon"),
        "venus": _midpoint("Venus"),
        "mars": _midpoint("Mars"),
        "ascendant": None,  # Composite ascendant requires time of meeting
    }


def _build_domain_breakdown(user_chart: dict, partner_chart: dict, aspects: list) -> list:
    """Build domain breakdown with intensity levels."""
    # Map planets to domains
    domain_planets = {
        "Identity": "Sun",
        "Emotion": "Moon",
        "Communication": "Mercury",
        "Love": "Venus",
        "Desire": "Mars",
        "Growth": "Jupiter",
        "Commitment": "Saturn",
    }

    result = []
    for domain, planet in domain_planets.items():
        user_sign = user_chart.get(planet, {}).get("sign", "Unknown")
        partner_sign = partner_chart.get(planet, {}).get("sign", "Unknown")

        # Find aspects involving this planet
        domain_aspects = [a for a in aspects if a["planet1"] == planet or a["planet2"] == planet]
        aspect_ids = [a["description"] for a in domain_aspects]

        # Calculate domain intensity from aspect quality
        harmonious_count = sum(1 for a in domain_aspects if a["compatibility"] > 0)
        challenging_count = sum(1 for a in domain_aspects if a["compatibility"] < 0)
        base_compat = _calculate_sun_sign_compatibility(user_sign, partner_sign)

        # Determine intensity based on aspect balance and sign compatibility
        if harmonious_count >= 2 and base_compat >= 70:
            intensity = "peak"
        elif harmonious_count > challenging_count and base_compat >= 50:
            intensity = "intense" if harmonious_count >= 2 else "strong"
        elif challenging_count > harmonious_count:
            intensity = "moderate" if base_compat >= 50 else "gentle"
        elif base_compat >= 70:
            intensity = "strong"
        elif base_compat >= 50:
            intensity = "moderate"
        else:
            intensity = "gentle"

        result.append(
            {"domain": domain, "intensity": intensity, "signA": user_sign, "signB": partner_sign, "aspectsInDomain": aspect_ids}
        )

    return result


def _build_synastry_data(
    aspects: list,
    overall_score: int,
    domain_breakdown: list,
    target_date: datetime = None,
    natal_a: dict = None,
    natal_b: dict = None,
) -> dict:
    """Build synastry data in client format.

    If natal positions and target_date are provided, computes real transit activations.
    """
    # Determine if aspects are harmonious
    aspect_harmonies = {"conjunction": True, "sextile": True, "trine": True, "square": False, "opposition": False}

    top_aspects = []
    for a in sorted(aspects, key=lambda x: abs(x["compatibility"]), reverse=True)[:10]:
        is_harmonious = aspect_harmonies.get(a["aspect"], True)

        # Compute isActivatedNow from transits if natal data available
        is_activated_now = False
        if target_date and natal_a and natal_b:
            is_activated, _strength = _transit.is_aspect_activated_now(a, target_date, natal_a, natal_b)
            is_activated_now = is_activated

        top_aspects.append(
            {
                "planetA": a["planet1"],
                "planetB": a["planet2"],
                "aspectType": a["aspect"],
                "orb": a["orb"],
                "strength": min(1.0, (8 - a["orb"]) / 8),  # Tighter orb = stronger
                "isHarmonious": is_harmonious,
                "isActivatedNow": is_activated_now,
                "interpretation": {
                    "title": f"{a['planet1']}-{a['planet2']} {a['aspect'].title()}",
                    "oneLiner": _get_aspect_interpretation(a["planet1"], a["planet2"], a["aspect"]),
                    "deepDive": "",
                    "suggestedAction": _get_aspect_action(a["aspect"], True),
                    "avoidAction": _get_aspect_action(a["aspect"], False),
                },
            }
        )

    # Convert overall score to intensity
    overall_intensity = _score_to_intensity(overall_score)

    return {"topAspects": top_aspects, "domainBreakdown": domain_breakdown, "overallIntensity": overall_intensity}


def _get_aspect_interpretation(planet1: str, planet2: str, aspect: str) -> str:
    """Generate a one-liner interpretation for an aspect."""
    harmonious = aspect in ["conjunction", "sextile", "trine"]

    interpretations = {
        ("Sun", "Moon"): ("Deep understanding flows naturally" if harmonious else "Core needs may conflict"),
        ("Venus", "Mars"): ("Strong romantic chemistry" if harmonious else "Passion meets friction"),
        ("Moon", "Moon"): ("Emotional wavelengths align" if harmonious else "Emotional styles differ"),
        ("Mercury", "Mercury"): ("Communication clicks" if harmonious else "Misunderstandings likely"),
        ("Sun", "Venus"): ("Mutual admiration" if harmonious else "Values may clash"),
        ("Venus", "Venus"): ("Shared aesthetic and values" if harmonious else "Different love languages"),
    }

    key = (planet1, planet2)
    reverse_key = (planet2, planet1)

    if key in interpretations:
        return interpretations[key]
    elif reverse_key in interpretations:
        return interpretations[reverse_key]
    else:
        return f"{planet1} and {planet2} {'harmonize' if harmonious else 'create tension'}"


def _get_aspect_action(aspect: str, is_do: bool) -> str:
    """Get do/avoid action for aspect type."""
    if is_do:
        actions = {
            "conjunction": "Lean into your shared energy",
            "sextile": "Take opportunities to connect",
            "trine": "Let things flow naturally",
            "square": "Address tension directly",
            "opposition": "Find the balance point",
        }
    else:
        actions = {
            "conjunction": "Don't lose your individuality",
            "sextile": "Don't take harmony for granted",
            "trine": "Don't become complacent",
            "square": "Don't escalate conflicts",
            "opposition": "Don't see it as you vs them",
        }
    return actions.get(aspect, "Be mindful" if is_do else "Avoid assumptions")


def _score_to_intensity(score: int) -> str:
    """Convert a 0-100 score to a qualitative intensity level.

    Returns one of: gentle, moderate, strong, intense, peak
    These map to gradient fill levels in the UI (0.2, 0.4, 0.6, 0.8, 1.0)
    """
    if score >= 85:
        return "peak"
    elif score >= 70:
        return "intense"
    elif score >= 55:
        return "strong"
    elif score >= 40:
        return "moderate"
    else:
        return "gentle"


def _calculate_relationship_pulse(
    aspects: list, target_date: datetime, natal_a: dict = None, natal_b: dict = None
) -> dict:
    """Calculate relationship pulse based on current transit activations.

    If natal positions are provided, uses real transit calculations.
    Otherwise falls back to static aspect-based calculation.
    """
    # Use transit-based calculation if natal positions available
    if natal_a and natal_b:
        result = _transit.calculate_pulse_from_transits(aspects, target_date, natal_a, natal_b)
        # Convert score to intensity
        result["intensity"] = _score_to_intensity(result.get("score", 50))
        del result["score"]  # Remove numeric score
        return result

    # Fallback: Static calculation based on natal aspects only
    # Use more varied intensity levels based on actual aspect counts
    harmonious = sum(1 for a in aspects if a["compatibility"] > 0)
    challenging = sum(1 for a in aspects if a["compatibility"] < 0)

    total = harmonious + challenging
    if total == 0:
        state = "grounded"
        intensity = "moderate"
    elif harmonious > challenging * 1.5:
        state = "flowing"
        # Vary intensity based on count: 1-2=strong, 3-4=intense, 5+=peak
        if harmonious >= 5:
            intensity = "peak"
        elif harmonious >= 3:
            intensity = "intense"
        else:
            intensity = "strong"
    elif challenging > harmonious:
        state = "friction"
        # Lower intensity for friction
        intensity = "gentle" if challenging >= 3 else "moderate"
    elif harmonious > challenging:
        state = "electric"
        intensity = "strong" if harmonious >= 2 else "moderate"
    else:
        state = "magnetic"
        intensity = "moderate"

    top_activations = []
    for a in sorted(aspects, key=lambda x: abs(x["compatibility"]), reverse=True)[:2]:
        top_activations.append(f"{a['planet1']} {a['aspect']} {a['planet2']}")

    return {"state": state, "intensity": intensity, "label": state.title(), "topActivations": top_activations}


def _select_shared_insight(aspects: list, pulse: dict) -> dict:
    """Select the most relevant shared insight."""
    # Pick strongest aspect for insight
    if not aspects:
        return {
            "title": "Building connection",
            "sentence": "Every relationship has its unique rhythm. Take time to discover yours.",
            "suggestedAction": "Have an open conversation",
            "avoidAction": "Don't rush to conclusions",
            "whyExpanded": "Compatibility is a journey, not a destination.",
            "linkedAspectIds": [],
        }

    top_aspect = max(aspects, key=lambda x: abs(x["compatibility"]))
    is_positive = top_aspect["compatibility"] > 0

    return {
        "title": f"{top_aspect['planet1']}-{top_aspect['planet2']} Connection",
        "sentence": _get_aspect_interpretation(top_aspect["planet1"], top_aspect["planet2"], top_aspect["aspect"]),
        "suggestedAction": _get_aspect_action(top_aspect["aspect"], True),
        "avoidAction": _get_aspect_action(top_aspect["aspect"], False),
        "whyExpanded": f"This {top_aspect['aspect']} aspect between your {top_aspect['planet1']} and their {top_aspect['planet2']} is {'supporting' if is_positive else 'challenging'} your connection right now.",
        "linkedAspectIds": [f"{top_aspect['planet1']}-{top_aspect['aspect']}-{top_aspect['planet2']}"],
    }


def _calculate_next_shift(
    aspects: list, target_date: datetime, natal_a: dict = None, natal_b: dict = None
) -> dict:
    """Calculate the next significant shift in relationship energy.

    If natal positions are provided, uses real transit predictions.
    Otherwise falls back to a gentle estimate.
    """
    if natal_a and natal_b:
        result = _transit.find_next_significant_transit(
            aspects, target_date, natal_a, natal_b
        )
        return {
            "date": result["date"],
            "daysUntil": result["days_away"],
            "whatChanges": result["description"],
            "newState": result["predicted_state"],
            "planForIt": result["suggestion"],
        }

    # Fallback: estimate based on aspect balance (no natal data available)
    harmonious = sum(1 for a in aspects if a.get("compatibility", 0) > 0)
    challenging = sum(1 for a in aspects if a.get("compatibility", 0) < 0)
    total = harmonious + challenging

    # Vary days and state based on actual aspect balance
    if total == 0:
        days_until = 14
        new_state = "grounded"
        what_changes = "Subtle shifts in connection energy"
        plan = "Stay present and attentive to each other"
    elif harmonious > challenging:
        days_until = 5 + (harmonious % 4)  # 5-8 days
        new_state = "flowing" if harmonious > challenging * 1.5 else "magnetic"
        what_changes = f"Harmonious aspects ({harmonious}) continue to support your connection"
        plan = "Build on the positive momentum together"
    elif challenging > harmonious:
        days_until = 3 + (challenging % 3)  # 3-5 days
        new_state = "grounded"  # Recovery state, not artificially positive
        what_changes = f"Tension from {challenging} challenging aspects begins to ease"
        plan = "Focus on patience and understanding"
    else:
        days_until = 7
        new_state = "magnetic"
        what_changes = "Balance shifts as aspects evolve"
        plan = "Stay adaptable to changing dynamics"

    next_date = target_date + timedelta(days=days_until)
    return {
        "date": next_date.isoformat(),
        "daysUntil": days_until,
        "whatChanges": what_changes,
        "newState": new_state,
        "planForIt": plan,
    }


def _build_journey_forecast(
    aspects: list, target_date: datetime, natal_a: dict = None, natal_b: dict = None
) -> dict:
    """Build 30-day journey forecast based on real transit calculations.

    If natal positions are provided, uses real transit-based calculations.
    Otherwise falls back to a simplified pattern.
    """
    if natal_a and natal_b:
        return _transit.build_journey_forecast(aspects, target_date, natal_a, natal_b)

    # Fallback: Calculate based on actual synastry aspects (no natal transit data)
    daily_markers = []
    peak_windows = []

    # Analyze actual aspect distribution
    harmonious = sum(1 for a in aspects if a.get("compatibility", 0) > 0)
    challenging = sum(1 for a in aspects if a.get("compatibility", 0) < 0)
    neutral = len(aspects) - harmonious - challenging
    total = len(aspects)

    # Calculate baseline intensity from aspects
    if total == 0:
        base_intensity = "neutral"
    elif harmonious > challenging * 1.5:
        base_intensity = "elevated"
    elif challenging > harmonious:
        base_intensity = "challenging"
    else:
        base_intensity = "neutral"

    # Build daily markers - vary based on aspect strength, not fake patterns
    for i in range(30):
        day = target_date + timedelta(days=i)

        # Subtle natural variation based on aspect count and day position
        # This creates variety without fake modulo patterns
        aspect_factor = (harmonious - challenging) / max(total, 1)

        if aspect_factor > 0.3:
            intensity = "elevated"
            reason = f"{harmonious} harmonious aspects support connection"
        elif aspect_factor < -0.3:
            intensity = "challenging"
            reason = f"{challenging} aspects require patience"
        elif aspect_factor > 0:
            intensity = "neutral"
            reason = "Balanced energy with slight positive tilt"
        else:
            intensity = "quiet"
            reason = "Reflective period for your connection"

        daily_markers.append({"date": day.isoformat(), "intensity": intensity, "reason": reason})

    # Only mark peak windows if there's genuinely strong harmony
    if harmonious >= 4 and harmonious > challenging * 1.5:
        peak_windows = [
            {
                "startDate": target_date.isoformat(),
                "endDate": (target_date + timedelta(days=7)).isoformat(),
                "label": "Strong synastry alignment",
                "suggestion": f"Your {harmonious} harmonious aspects create supportive energy",
            }
        ]
    elif challenging >= 3 and challenging > harmonious:
        # Be honest about challenging periods too
        peak_windows = [
            {
                "startDate": target_date.isoformat(),
                "endDate": (target_date + timedelta(days=7)).isoformat(),
                "label": "Growth opportunity",
                "suggestion": f"{challenging} challenging aspects invite deeper understanding",
            }
        ]
    # No peak windows if no strong pattern - be honest rather than fabricate

    return {"dailyMarkers": daily_markers, "peakWindows": peak_windows}


def _build_share_model(insight: dict, relationship: dict) -> dict:
    """Build share model for the insight."""
    return {
        "cardTitle": insight["title"],
        "cardSentence": insight["sentence"],
        "cardAction": insight["suggestedAction"],
        "cardAvoid": insight["avoidAction"],
        "highlightedAspectId": insight["linkedAspectIds"][0] if insight["linkedAspectIds"] else None,
        "deepLinkToken": f"share-{relationship['id'][:8]}",
    }


def _generate_shared_signature(user_chart: dict, partner_chart: dict, aspects: list) -> str:
    """Generate a shared signature like 'Warmth + honesty, watch power dynamics'."""
    positives = []
    challenges = []

    # Check key aspects
    for a in aspects:
        if a["compatibility"] > 0:
            if a["planet1"] == "Sun" or a["planet2"] == "Sun":
                positives.append("warmth")
            if a["planet1"] == "Mercury" or a["planet2"] == "Mercury":
                positives.append("communication")
            if a["planet1"] == "Venus" or a["planet2"] == "Venus":
                positives.append("affection")
            if a["planet1"] == "Moon" or a["planet2"] == "Moon":
                positives.append("emotional depth")
        else:
            if a["planet1"] == "Mars" or a["planet2"] == "Mars":
                challenges.append("power dynamics")
            if a["planet1"] == "Saturn" or a["planet2"] == "Saturn":
                challenges.append("boundaries")
            if a["aspect"] == "square":
                challenges.append("tension points")

    # Deduplicate and limit
    positives = list(dict.fromkeys(positives))[:2]
    challenges = list(dict.fromkeys(challenges))[:1]

    if positives and challenges:
        return f"{' + '.join(pos.title() for pos in positives)}, watch {challenges[0]}"
    elif positives:
        return " + ".join(pos.title() for pos in positives)
    elif challenges:
        return f"Navigate {challenges[0]} together"
    else:
        return "Discovering your connection"
