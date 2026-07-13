"""
Astrocartography / Relocation Astrology Service.

Computes how a natal chart shifts when a person relocates to different cities.
Uses APPROXIMATE math — no Swiss Ephemeris dependency. The key insight is:

    ΔASC ≈ Δlongitude  (1 deg longitude ≈ 4 min RA ≈ 1 deg ascendant shift)

All outputs are grounded, actionable recommendations for operational decision-making:
where to base visibility, where to build backend, where to stage.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# City database — major global operational nodes with astrocartographic profiles
# ---------------------------------------------------------------------------

CITIES: List[Dict[str, Any]] = [
    {
        "name": "Dubai",
        "lat": 25.20,
        "lon": 55.27,
        "country": "UAE",
        "description": "Sovereign-Creator amplified. Career visibility peaks.",
        "best_for": ["founder_visibility", "tax_optimization", "independent_operation"],
    },
    {
        "name": "Singapore",
        "lat": 1.35,
        "lon": 103.82,
        "country": "Singapore",
        "description": "Capital structure stabilizes. Backend/IP architecture node.",
        "best_for": ["asset_protection", "backend_infrastructure", "cross_border"],
    },
    {
        "name": "Bengaluru",
        "lat": 12.97,
        "lon": 77.59,
        "country": "India",
        "description": "Native baseline. Staging/build environment.",
        "best_for": ["build_staging", "talent_access", "cost_efficiency"],
    },
    {
        "name": "London",
        "lat": 51.51,
        "lon": -0.13,
        "country": "UK",
        "description": "Network/political node. Public visibility with ego cost.",
        "best_for": ["enterprise_sales", "network_access", "premium_branding"],
    },
    {
        "name": "New York",
        "lat": 40.71,
        "lon": -74.01,
        "country": "USA",
        "description": "Media/finance hub. High burn rate, high signal.",
        "best_for": ["capital_raising", "media_visibility", "enterprise_clients"],
    },
    {
        "name": "San Francisco",
        "lat": 37.77,
        "lon": -122.42,
        "country": "USA",
        "description": "Innovation spike but overhead leak. Good for short launches.",
        "best_for": ["product_launches", "fundraising", "tech_networks"],
    },
    {
        "name": "Tokyo",
        "lat": 35.68,
        "lon": 139.76,
        "country": "Japan",
        "description": "Deep work. Public risk. Inner discipline required.",
        "best_for": ["deep_research", "disciplined_execution", "asia_presence"],
    },
    {
        "name": "Delhi",
        "lat": 28.61,
        "lon": 77.23,
        "country": "India",
        "description": "Power/authority node. Bureaucratic friction, network depth.",
        "best_for": ["government_relations", "india_operations", "family_proximity"],
    },
    {
        "name": "Zurich",
        "lat": 47.38,
        "lon": 8.54,
        "country": "Switzerland",
        "description": "Precision/wealth preservation. Quiet but powerful.",
        "best_for": ["wealth_management", "precision_engineering", "data_privacy"],
    },
    {
        "name": "Mumbai",
        "lat": 19.08,
        "lon": 72.88,
        "country": "India",
        "description": "Commercial velocity. High operational churn.",
        "best_for": ["commerce", "media_entertainment", "india_headquarters"],
    },
]

# ---------------------------------------------------------------------------
# Sign registry (Western canonical names with Vedic aliases)
# ---------------------------------------------------------------------------

ZODIAC_SIGNS: List[str] = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

_SIGN_ALIASES: Dict[str, str] = {
    # Western (case-insensitive)
    "aries": "Aries", "taurus": "Taurus", "gemini": "Gemini",
    "cancer": "Cancer", "leo": "Leo", "virgo": "Virgo",
    "libra": "Libra", "scorpio": "Scorpio",
    "sagittarius": "Sagittarius", "capricorn": "Capricorn",
    "aquarius": "Aquarius", "pisces": "Pisces",
    # Vedic (Rashi)
    "mesha": "Aries", "vrishabha": "Taurus", "mithuna": "Gemini",
    "karka": "Cancer", "simha": "Leo", "kanya": "Virgo",
    "tula": "Libra", "vrischika": "Scorpio", "dhanu": "Sagittarius",
    "makara": "Capricorn", "kumbha": "Aquarius", "meena": "Pisces",
}

_SIGN_RULER: Dict[str, str] = {
    "Aries": "Mars", "Taurus": "Venus", "Gemini": "Mercury",
    "Cancer": "Moon", "Leo": "Sun", "Virgo": "Mercury",
    "Libra": "Venus", "Scorpio": "Mars", "Sagittarius": "Jupiter",
    "Capricorn": "Saturn", "Aquarius": "Saturn", "Pisces": "Jupiter",
}

# ---------------------------------------------------------------------------
# Dignity tables
# ---------------------------------------------------------------------------

_EXALTATION: Dict[str, str] = {
    "Sun": "Aries", "Moon": "Taurus", "Mars": "Capricorn",
    "Mercury": "Virgo", "Jupiter": "Cancer", "Venus": "Pisces",
    "Saturn": "Libra",
}

_DEBILITATION: Dict[str, str] = {
    "Sun": "Libra", "Moon": "Scorpio", "Mars": "Cancer",
    "Mercury": "Pisces", "Jupiter": "Capricorn", "Venus": "Virgo",
    "Saturn": "Aries",
}

_OWN_SIGNS: Dict[str, set] = {
    "Sun": {"Leo"},
    "Moon": {"Cancer"},
    "Mars": {"Aries", "Scorpio"},
    "Mercury": {"Gemini", "Virgo"},
    "Jupiter": {"Sagittarius", "Pisces"},
    "Venus": {"Taurus", "Libra"},
    "Saturn": {"Capricorn", "Aquarius"},
}

# Natural friendship (standard Parasari scheme)
_PLANETARY_FRIENDS: Dict[str, set] = {
    "Sun": {"Moon", "Mars", "Jupiter"},
    "Moon": {"Sun", "Mercury"},
    "Mars": {"Sun", "Moon", "Jupiter"},
    "Mercury": {"Sun", "Venus"},
    "Jupiter": {"Sun", "Moon", "Mars"},
    "Venus": {"Mercury", "Saturn"},
    "Saturn": {"Mercury", "Venus"},
}

_PLANETARY_ENEMIES: Dict[str, set] = {
    "Sun": {"Venus", "Saturn"},
    "Moon": set(),
    "Mars": {"Mercury"},
    "Mercury": {"Moon"},
    "Jupiter": {"Mercury", "Venus"},
    "Venus": {"Sun", "Moon"},
    "Saturn": {"Sun", "Moon", "Mars"},
}

# ---------------------------------------------------------------------------
# House classifications
# ---------------------------------------------------------------------------

_KENDRA_HOUSES: set = {1, 4, 7, 10}
_TRIKONA_HOUSES: set = {1, 5, 9}
_DUSTHANA_HOUSES: set = {6, 8, 12}

# ---------------------------------------------------------------------------
# Planetary line colors and interpretations
# ---------------------------------------------------------------------------

_LINE_PROFILES: Dict[str, Dict[str, str]] = {
    "Jupiter_MC": {
        "planet": "Jupiter",
        "line_type": "MC",
        "color_hex": "#FFD700",
        "interpretation": "Public success, wisdom, expansion through career. "
        "Best for visibility, teaching, and enterprise sales.",
    },
    "Venus_AS": {
        "planet": "Venus",
        "line_type": "AS",
        "color_hex": "#FF69B4",
        "interpretation": "Personal magnetism, relationship harmony, creative expression. "
        "Best for branding, design, and partnership-based work.",
    },
    "Saturn_IC": {
        "planet": "Saturn",
        "line_type": "IC",
        "color_hex": "#708090",
        "interpretation": "Deep structural foundation, discipline at home base. "
        "Best for long-term builds, backend infrastructure, asset anchoring.",
    },
    "Mars_AS": {
        "planet": "Mars",
        "line_type": "AS",
        "color_hex": "#FF4500",
        "interpretation": "Initiative, drive, competitive edge on the ground. "
        "Best for launches, fundraising sprints, and high-agency execution.",
    },
}

_BENEFICS: set = {"Jupiter", "Venus", "Mercury", "Moon"}
_MALEFICS: set = {"Sun", "Mars", "Saturn", "Rahu", "Ketu"}


# ===========================================================================
# Helpers
# ===========================================================================


def _normalize_sign(name: str) -> str:
    """Normalize a sign name to canonical Western form, case-insensitive, Vedic-aware."""
    value = (name or "").strip()
    if not value:
        return "Aries"
    return _SIGN_ALIASES.get(value.lower(), value[:1].upper() + value[1:].lower())


def _sign_to_index(name: str) -> int:
    """Convert sign name to 0-based zodiac index."""
    canon = _normalize_sign(name)
    try:
        return ZODIAC_SIGNS.index(canon)
    except ValueError:
        return 0


def _index_to_sign(idx: int) -> str:
    """Convert 0-based zodiac index back to sign name."""
    return ZODIAC_SIGNS[idx % 12]


def _degree_to_sign_deg(absolute_deg: float) -> Tuple[str, float]:
    """Convert absolute zodiac degree (0-360) to (sign_name, degree_within_sign)."""
    d = absolute_deg % 360
    idx = int(d // 30)
    return _index_to_sign(idx), d % 30


def _extract_natal_axes(birth_data: Dict[str, Any]) -> Tuple[float, float]:
    """Extract natal ascendant and MC absolute degrees from birth_data.

    Supports multiple formats:
      - Top-level: birth_data["ascendant_degree"], birth_data["mc_degree"]
      - Nested: birth_data["ascendant"]["degree"], birth_data["mc"]["degree"]
      - Sign + degree: extracts absolute from sign name + within-sign degree
    """
    asc_deg: Optional[float] = None
    mc_deg: Optional[float] = None

    # Direct absolute degree
    if "ascendant_degree" in birth_data:
        asc_deg = float(birth_data["ascendant_degree"])
    if "mc_degree" in birth_data:
        mc_deg = float(birth_data["mc_degree"])

    # Nested dict format: {"ascendant": {"sign": "...", "degree": ...}}
    if asc_deg is None:
        asc = birth_data.get("ascendant")
        if isinstance(asc, dict):
            sign = _normalize_sign(str(asc.get("sign", "Aries")))
            deg = float(asc.get("degree", 0))
            asc_deg = _sign_to_index(sign) * 30.0 + deg
        elif isinstance(asc, str):
            asc_deg = _sign_to_index(asc) * 30.0 + 15.0  # mid-sign approximation

    if mc_deg is None:
        mc = birth_data.get("mc")
        if isinstance(mc, dict):
            sign = _normalize_sign(str(mc.get("sign", "Aries")))
            deg = float(mc.get("degree", 0))
            mc_deg = _sign_to_index(sign) * 30.0 + deg

    # Fallback: estimate ascendant from birth time (very rough, midnight = Aries 0)
    if asc_deg is None:
        time_str = str(birth_data.get("time", "06:00"))
        try:
            parts = time_str.replace(":", " ").split()
            hours = float(parts[0])
            minutes = float(parts[1]) if len(parts) > 1 else 0
            # Rough estimate: 24h = 360deg, so each hour ≈ 15deg, offset by ~6h
            asc_deg = ((hours + minutes / 60.0) - 6.0) * 15.0
            if asc_deg < 0:
                asc_deg += 360.0
        except (ValueError, IndexError):
            asc_deg = 0.0  # default Aries 0

    # Fallback MC: ascendant + 90 (approximate; varies by latitude)
    if mc_deg is None:
        mc_deg = (asc_deg + 90.0) % 360.0

    return asc_deg, mc_deg


def _extract_planet_positions(birth_data: Dict[str, Any]) -> Dict[str, float]:
    """Extract approximate planet absolute longitudes from birth_data.

    Returns {planet_name: absolute_degree}. Falls back to approximate
    positions derived from ascendant if no planet data is available.
    """
    planets = birth_data.get("planets")
    positions: Dict[str, float] = {}

    if isinstance(planets, dict):
        for pname, pdata in planets.items():
            planet = pname[:1].upper() + pname[1:].lower()
            if isinstance(pdata, dict):
                sign = _normalize_sign(str(pdata.get("sign", "")))
                deg = float(pdata.get("degree", 0))
                if "longitude" in pdata:
                    positions[planet] = float(pdata["longitude"]) % 360
                else:
                    positions[planet] = (_sign_to_index(sign) * 30.0 + deg) % 360
            elif isinstance(pdata, (int, float)):
                positions[planet] = float(pdata) % 360

    return positions


def _asc_lord_dignity_score(lord: str, new_sign: str) -> float:
    """Score ascendant lord's dignity in the relocated sign. Returns 0-40."""
    if lord not in _EXALTATION:
        return 15.0  # neutral default for Rahu/Ketu

    if new_sign == _EXALTATION[lord]:
        return 40.0
    if new_sign in _OWN_SIGNS.get(lord, set()):
        return 35.0
    if new_sign == _DEBILITATION[lord]:
        return 0.0
    # Check friendships
    ruler_of_new = _SIGN_RULER.get(new_sign, "")
    if ruler_of_new in _PLANETARY_FRIENDS.get(lord, set()):
        return 25.0
    if ruler_of_new in _PLANETARY_ENEMIES.get(lord, set()):
        return 8.0
    return 15.0  # neutral


# ===========================================================================
# GeographicService
# ===========================================================================


class GeographicService:
    """Service for astrocartographic relocation analysis.

    Computes relocated ascendant/MC, scores city suitability, ranks cities,
    and generates planetary line data — all with approximate math.
    No ephemeris dependency.
    """

    def __init__(self) -> None:
        pass

    # -----------------------------------------------------------------------
    # Method 1: Compute relocated Ascendant / MC
    # -----------------------------------------------------------------------

    def compute_relocated_ascendant(
        self, birth_data: Dict[str, Any], target_city: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Compute approximate relocated Ascendant and MC for a target city.

        Formula:  ΔASC ≈ Δlongitude
        (1 deg longitude ≈ 4 minutes of right ascension ≈ 1 deg ascendant shift)

        Args:
            birth_data: {date, time, timezone, latitude, longitude} plus
                        optional ascendant_degree, mc_degree (absolute 0-360).
            target_city: One of the CITIES dicts with "lat", "lon".

        Returns:
            {ascendant_sign, ascendant_degree, mc_sign, mc_degree,
             ascendant_lord, delta_asc, delta_mc}
        """
        natal_asc, natal_mc = _extract_natal_axes(birth_data)
        birth_lon = float(birth_data.get("longitude", 0))
        target_lon = float(target_city.get("lon", 0))

        # Longitude delta — positive = eastward shift
        lon_delta = target_lon - birth_lon

        # Relocated axes
        new_asc_deg = (natal_asc + lon_delta) % 360.0
        new_mc_deg = (natal_mc + lon_delta) % 360.0

        asc_sign, asc_deg_in_sign = _degree_to_sign_deg(new_asc_deg)
        mc_sign, mc_deg_in_sign = _degree_to_sign_deg(new_mc_deg)
        lord = _SIGN_RULER.get(asc_sign, "Unknown")

        # Delta in degrees (signed, for interpretation)
        delta_asc = ((new_asc_deg - natal_asc + 540.0) % 360.0) - 180.0
        delta_mc = ((new_mc_deg - natal_mc + 540.0) % 360.0) - 180.0

        return {
            "ascendant_sign": asc_sign,
            "ascendant_degree": round(asc_deg_in_sign, 2),
            "ascendant_absolute": round(new_asc_deg, 2),
            "mc_sign": mc_sign,
            "mc_degree": round(mc_deg_in_sign, 2),
            "mc_absolute": round(new_mc_deg, 2),
            "ascendant_lord": lord,
            "delta_asc": round(delta_asc, 2),
            "delta_mc": round(delta_mc, 2),
            "longitude_shift": round(lon_delta, 2),
        }

    # -----------------------------------------------------------------------
    # Method 2: Evaluate a single city
    # -----------------------------------------------------------------------

    def evaluate_city(
        self,
        birth_data: Dict[str, Any],
        target_city: Dict[str, Any],
        user_priors: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Score a city's astrocartographic suitability.

        Scoring (100-point scale, normalized to 0-1.0):
          * Ascendant lord dignity in relocated chart  ........ 0-40 pts
          * MC / 10th-house career axis activation  .......... 0-30 pts
          * User prior alignment  ............................ 0-20 pts
          * Blemish penalty (malefic house activation) ....... 0 to -10 pts

        Args:
            birth_data: Natal chart data.
            target_city: City dict with lat, lon, name, country.
            user_priors: Optional user context dict for weighting.

        Returns:
            {city_name, score, ascendant, mc, strengths, weaknesses,
             recommendation_rank, description}
        """
        rel = self.compute_relocated_ascendant(birth_data, target_city)
        priors = user_priors or {}

        asc_sign = rel["ascendant_sign"]
        mc_sign = rel["mc_sign"]
        lord = rel["ascendant_lord"]
        score = 0.0
        strengths: List[str] = []
        weaknesses: List[str] = []

        # --- 1. Ascendant lord dignity (0-40) ---
        dignity = _asc_lord_dignity_score(lord, asc_sign)
        score += dignity
        if dignity >= 35:
            strengths.append(f"{lord} in {asc_sign}: strong dignity — identity amplifies naturally")
        elif dignity >= 25:
            strengths.append(f"{lord} in {asc_sign}: friendly placement — ease of adaptation")
        elif dignity <= 8:
            weaknesses.append(f"{lord} in {asc_sign}: challenged dignity — identity friction at this location")
            if dignity == 0:
                weaknesses.append(f"{lord} debilitated in {asc_sign}: consider this city for short stays only")

        # --- 2. MC / career axis activation (0-30) ---
        mc_lord = _SIGN_RULER.get(mc_sign, "")
        mc_dignity = _asc_lord_dignity_score(mc_lord, mc_sign) if mc_lord else 15.0
        # Normalize MC dignity to 0-30 scale
        mc_score = (mc_dignity / 40.0) * 30.0
        score += mc_score

        # Bonus: if ascendant lord = MC lord (career-identity alignment)
        if lord == mc_lord:
            mc_score += 10.0
            strengths.append(f"{lord} rules both Ascendant and MC: unified career-identity axis")

        if mc_score >= 25:
            strengths.append(f"MC in {mc_sign}: career axis strongly activated")
        elif mc_score <= 8:
            weaknesses.append(f"MC in {mc_sign}: career activation muted at this location")

        # --- 3. User prior alignment (0-20) ---
        prior_score = 0.0
        if priors:
            # Relocation intent
            relocation_keys = {"relocation", "move", "relocate", "base", "hub", "headquarters"}
            if any(k in str(priors).lower() for k in relocation_keys):
                prior_score += 12.0
                strengths.append("Relocation intent detected — geographic priorities weighted")

            # Career/wealth focus
            career_keys = {"career", "business", "founder", "revenue", "growth", "launch"}
            if any(k in str(priors).lower() for k in career_keys):
                prior_score += 8.0
                strengths.append("Career/business focus detected — MC-axis cities favoured")

            # Explicit target mentions
            target_name = target_city.get("name", "").lower()
            if target_name in str(priors).lower():
                prior_score += 5.0
                strengths.append(f"{target_city.get('name')} explicitly mentioned in priors — weighting up")

        score += min(prior_score, 20.0)

        # --- 4. Blemish penalty (0 to -10) ---
        penalty = 0.0
        # Count dusthana (6/8/12) activations for ascendant lord
        natal_asc, _ = _extract_natal_axes(birth_data)
        # House of ascendant lord relative to new ascendant: (lord_sign_idx - asc_sign_idx)
        asc_idx = _sign_to_index(asc_sign)
        lord_idx = _sign_to_index(asc_sign)  # ascendant lord is the ruler OF the ascendant...
        # Actually, the ascendant lord is IN the ascendant sign in relocated chart? No.
        # Lord dignities are checked in the relocated ascendant sign. For blemish,
        # check if dusthana rulers are prominent, or if relocated asc lord is in dusthana.
        # Simplified: if new ascendant is a dusthana from natal ascendant
        natal_asc_idx = _sign_to_index(_degree_to_sign_deg(natal_asc)[0])
        house_from_natal = ((asc_idx - natal_asc_idx) % 12) + 1
        if house_from_natal in _DUSTHANA_HOUSES:
            penalty += 5.0
            weaknesses.append(
                f"Relocated Ascendant falls in {house_from_natal}H from natal Ascendant: "
                "structural friction at this location"
            )

        # If new MC ruler is in dusthana from new MC
        mc_idx = _sign_to_index(mc_sign)
        mc_lord_idx = _sign_to_index(mc_sign)  # approx
        mc_house = ((mc_lord_idx - mc_idx) % 12) + 1
        if mc_house in _DUSTHANA_HOUSES:
            penalty += 3.0
            weaknesses.append("MC ruler in dusthana: career axis under shadow at this location")

        # If relocated ascendant lord is a natural malefic
        if lord in _MALEFICS:
            penalty += 2.0
            weaknesses.append(f"Malefic ascendant lord ({lord}): intensity/cost tradeoff at this location")

        penalty = min(penalty, 10.0)
        score -= penalty

        # Clamp and normalize
        raw_score = max(0.0, min(score, 100.0))
        normalized = raw_score / 100.0

        # Recommendation tier
        if normalized >= 0.75:
            tier = "strongly recommended"
        elif normalized >= 0.55:
            tier = "recommended"
        elif normalized >= 0.35:
            tier = "viable"
        else:
            tier = "not recommended"

        return {
            "city_name": target_city.get("name", "Unknown"),
            "country": target_city.get("country", ""),
            "score": round(normalized, 3),
            "raw_score": round(raw_score, 1),
            "recommendation_tier": tier,
            "ascendant": {
                "sign": asc_sign,
                "degree": rel["ascendant_degree"],
                "lord": lord,
            },
            "mc": {
                "sign": mc_sign,
                "degree": rel["mc_degree"],
                "lord": _SIGN_RULER.get(mc_sign, "Unknown"),
            },
            "delta_asc": rel["delta_asc"],
            "delta_mc": rel["delta_mc"],
            "strengths": strengths,
            "weaknesses": weaknesses,
            "description": target_city.get("description", ""),
            "best_for": target_city.get("best_for", []),
        }

    # -----------------------------------------------------------------------
    # Method 3: Rank all cities (or filtered subset)
    # -----------------------------------------------------------------------

    def rank_cities(
        self,
        birth_data: Dict[str, Any],
        user_priors: Optional[Dict[str, Any]] = None,
        filter_countries: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """Evaluate all cities and return ranked list by score (descending).

        Top 3 receive "recommended" flag. Each entry includes rank, score,
        ascendant sign, best_for tags, and a generated suitability note.

        Args:
            birth_data: Natal chart data.
            user_priors: Optional user context for weighting.
            filter_countries: Optional list of country codes to restrict to.

        Returns:
            Ranked list of city evaluation dicts.
        """
        candidates = CITIES
        if filter_countries:
            allowed = {c.lower() for c in filter_countries}
            candidates = [c for c in CITIES if c.get("country", "").lower() in allowed]

        results: List[Dict[str, Any]] = []
        for city in candidates:
            eval_ = self.evaluate_city(birth_data, city, user_priors)
            results.append(eval_)

        # Sort by score descending
        results.sort(key=lambda r: r["score"], reverse=True)

        # Assign ranks and suitability notes
        for i, entry in enumerate(results):
            entry["rank"] = i + 1
            entry["recommended"] = i < 3

            score = entry["score"]
            asc_sign = entry["ascendant"]["sign"]
            best_for = entry.get("best_for", [])

            if score >= 0.75:
                note = (
                    f"{asc_sign} ascendant at this location amplifies natural strength. "
                    f"Best for: {', '.join(best_for[:2]) if best_for else 'general operations'}."
                )
            elif score >= 0.55:
                note = (
                    f"{asc_sign} ascendant supports most operations with moderate adjustment. "
                    f"Suitable for: {', '.join(best_for[:2]) if best_for else 'secondary base'}."
                )
            elif score >= 0.35:
                note = (
                    f"{asc_sign} ascendant here requires adaptation. "
                    f"Consider for: short stays, specific projects."
                )
            else:
                note = (
                    f"{asc_sign} ascendant at this location creates structural friction. "
                    f"Not recommended as a primary base."
                )

            entry["suitability_note"] = note

        return results

    # -----------------------------------------------------------------------
    # Method 4: Planetary lines for map visualization
    # -----------------------------------------------------------------------

    def get_planetary_lines(self, birth_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Return approximate planetary line positions for map visualization.

        Computes Jupiter MC, Venus AS, Saturn IC, and Mars AS lines based on
        natal planetary positions and ascendant/MC. If precise planet data is
        unavailable, falls back to approximate positions derived from the
        ascendant.

        Each line: {planet, line_type, approximate_longitude_range, color_hex, interpretation}

        Args:
            birth_data: Natal chart data, optionally with planet positions.

        Returns:
            List of planetary line dicts for map overlay.
        """
        natal_asc, natal_mc = _extract_natal_axes(birth_data)
        birth_lon = float(birth_data.get("longitude", 0))
        positions = _extract_planet_positions(birth_data)

        # If no planet data, derive approximate positions from ascendant
        if not positions:
            # Rough placement: each planet 1 sign apart from ascendant
            # (standard approximate distribution)
            planet_order = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]
            for i, planet in enumerate(planet_order):
                positions[planet] = (natal_asc + i * 30.0 + 5.0) % 360.0

        lines: List[Dict[str, Any]] = []

        line_specs = [
            ("Jupiter", "MC", "Jupiter_MC"),
            ("Venus", "AS", "Venus_AS"),
            ("Saturn", "IC", "Saturn_IC"),
            ("Mars", "AS", "Mars_AS"),
        ]

        for planet, line_type, profile_key in line_specs:
            planet_lon = positions.get(planet)
            if planet_lon is None:
                continue

            profile = _LINE_PROFILES[profile_key]

            # Approximate line longitude:
            #   ASC line: planet_lon + (line_lon - birth_lon) ≈ natal_asc at line_lon
            #   => line_lon = birth_lon + (natal_asc - planet_lon)
            #   MC line:  line_lon = birth_lon + (natal_mc - planet_lon)
            #   IC line:  line_lon = birth_lon + ((natal_mc + 180) - planet_lon)
            #   DS line:  line_lon = birth_lon + ((natal_asc + 180) - planet_lon)

            if line_type == "AS":
                offset = natal_asc - planet_lon
            elif line_type == "MC":
                offset = natal_mc - planet_lon
            elif line_type == "IC":
                offset = (natal_mc + 180.0) % 360.0 - planet_lon
            elif line_type == "DS":
                offset = (natal_asc + 180.0) % 360.0 - planet_lon
            else:
                offset = 0.0

            line_lon = (birth_lon + offset) % 360.0
            # Normalize to [-180, 180] range for standard map display
            display_lon = line_lon if line_lon <= 180 else line_lon - 360

            # Orb of influence: ~1 degree longitude ≈ 70 miles / 112 km
            lon_range = [round(display_lon - 1.0, 2), round(display_lon + 1.0, 2)]

            lines.append({
                "planet": planet,
                "line_type": line_type,
                "profile_key": profile_key,
                "approximate_longitude": round(display_lon, 2),
                "approximate_longitude_range": lon_range,
                "color_hex": profile["color_hex"],
                "interpretation": profile["interpretation"],
            })

        return lines

    # -----------------------------------------------------------------------
    # Method 5: Full geographic report
    # -----------------------------------------------------------------------

    def full_geographic_report(
        self,
        birth_data: Dict[str, Any],
        user_priors: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Generate a complete astrocartographic report.

        Combines ranked cities, planetary lines, top recommendation, and a
        summary narrative paragraph.

        Args:
            birth_data: Natal chart data.
            user_priors: Optional user context for weighting.

        Returns:
            Full report dict with ranked_cities, planetary_lines, top_pick,
            and summary.
        """
        ranked = self.rank_cities(birth_data, user_priors)
        lines = self.get_planetary_lines(birth_data)

        top_pick = ranked[0] if ranked else None
        runner_up = ranked[1] if len(ranked) > 1 else None

        # Build summary narrative
        if top_pick and runner_up:
            ta = top_pick
            ra = runner_up
            summary = (
                f"{ta['city_name']} preserves your "
                f"{ta['ascendant']['sign']} identity while activating "
                f"{ta['ascendant']['lord']}/{ta['mc']['sign']} career axis. "
                f"{ra['city_name']} shifts you to {ra['ascendant']['sign']} — "
                f"better for {', '.join(ra.get('best_for', ['secondary ops'])[:2])} "
                f"but heavier personally. "
                f"Recommended: distributed model with {ta['city_name']} as "
                f"visibility base, {ra['city_name']} as capital/IP node."
            )
        elif top_pick:
            ta = top_pick
            summary = (
                f"{ta['city_name']} is the strongest relocation candidate: "
                f"{ta['ascendant']['sign']} ascendant with "
                f"{ta['ascendant']['lord']} lord — {ta['description']}"
            )
        else:
            summary = "Insufficient city data for geographic analysis."

        # Count per tier
        tier_counts: Dict[str, int] = {}
        for entry in ranked:
            tier = entry.get("recommendation_tier", "unknown")
            tier_counts[tier] = tier_counts.get(tier, 0) + 1

        return {
            "ranked_cities": ranked,
            "planetary_lines": lines,
            "top_pick": top_pick,
            "runner_up": runner_up,
            "recommendation_counts": tier_counts,
            "summary": summary,
            "method_note": (
                "All computations use approximate ΔASC ≈ Δlongitude math. "
                "Degrees are for directional guidance, not exact cuspal precision. "
                "Cross-validate with precise ephemeris for critical timing decisions."
            ),
        }
