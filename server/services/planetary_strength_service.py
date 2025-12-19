"""
Planetary Strength (Shadbala) and Impact Scoring Service.
Calculates planetary strength and scores impact on different life areas.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

# House significations for impact scoring
HOUSE_SIGNIFICATIONS = {
    1: ["identity", "health", "vitality", "personality"],
    2: ["wealth", "family", "speech", "values"],
    3: ["courage", "communication", "siblings", "skills"],
    4: ["home", "mother", "emotions", "property"],
    5: ["creativity", "children", "intelligence", "romance"],
    6: ["health", "service", "obstacles", "enemies"],
    7: ["relationships", "partnerships", "marriage", "business"],
    8: ["transformation", "occult", "longevity", "inheritance"],
    9: ["wisdom", "spirituality", "fortune", "higher_learning"],
    10: ["career", "status", "authority", "public_life"],
    11: ["gains", "friendships", "aspirations", "income"],
    12: ["spiritual", "loss", "foreign_lands", "liberation"],
}

# Planetary natural significations
PLANET_SIGNIFICATIONS = {
    "Sun": {
        "career": 0.9,
        "relationships": 0.4,
        "health": 0.8,
        "spiritual": 0.6,
        "keywords": ["authority", "vitality", "ego", "father"],
    },
    "Moon": {
        "career": 0.3,
        "relationships": 0.8,
        "health": 0.7,
        "spiritual": 0.7,
        "keywords": ["emotions", "mother", "mind", "nurturing"],
    },
    "Mars": {
        "career": 0.7,
        "relationships": 0.5,
        "health": 0.9,
        "spiritual": 0.4,
        "keywords": ["energy", "courage", "action", "conflict"],
    },
    "Mercury": {
        "career": 0.8,
        "relationships": 0.7,
        "health": 0.5,
        "spiritual": 0.5,
        "keywords": ["intellect", "communication", "learning", "commerce"],
    },
    "Jupiter": {
        "career": 0.7,
        "relationships": 0.7,
        "health": 0.6,
        "spiritual": 0.9,
        "keywords": ["wisdom", "expansion", "fortune", "teaching"],
    },
    "Venus": {
        "career": 0.6,
        "relationships": 0.9,
        "health": 0.6,
        "spiritual": 0.5,
        "keywords": ["love", "beauty", "harmony", "luxury"],
    },
    "Saturn": {
        "career": 0.8,
        "relationships": 0.4,
        "health": 0.5,
        "spiritual": 0.7,
        "keywords": ["discipline", "responsibility", "restriction", "karma"],
    },
    "Rahu": {
        "career": 0.8,
        "relationships": 0.6,
        "health": 0.3,
        "spiritual": 0.6,
        "keywords": ["ambition", "illusion", "obsession", "foreign"],
    },
    "Ketu": {
        "career": 0.3,
        "relationships": 0.3,
        "health": 0.4,
        "spiritual": 0.9,
        "keywords": ["detachment", "spirituality", "liberation", "moksha"],
    },
}

# Planetary friendships (for dignity calculation)
PLANETARY_RELATIONSHIPS = {
    "Sun": {"friends": ["Moon", "Mars", "Jupiter"], "enemies": ["Venus", "Saturn"], "neutral": ["Mercury"]},
    "Moon": {"friends": ["Sun", "Mercury"], "enemies": [], "neutral": ["Mars", "Jupiter", "Venus", "Saturn"]},
    "Mars": {"friends": ["Sun", "Moon", "Jupiter"], "enemies": ["Mercury"], "neutral": ["Venus", "Saturn"]},
    "Mercury": {"friends": ["Sun", "Venus"], "enemies": ["Moon"], "neutral": ["Mars", "Jupiter", "Saturn"]},
    "Jupiter": {"friends": ["Sun", "Moon", "Mars"], "enemies": ["Mercury", "Venus"], "neutral": ["Saturn"]},
    "Venus": {"friends": ["Mercury", "Saturn"], "enemies": ["Sun", "Moon"], "neutral": ["Mars", "Jupiter"]},
    "Saturn": {"friends": ["Mercury", "Venus"], "enemies": ["Sun", "Moon", "Mars"], "neutral": ["Jupiter"]},
    "Rahu": {"friends": ["Mercury", "Venus", "Saturn"], "enemies": ["Sun", "Moon", "Mars"], "neutral": ["Jupiter"]},
    "Ketu": {"friends": ["Mars", "Jupiter"], "enemies": ["Sun", "Moon"], "neutral": ["Mercury", "Venus", "Saturn"]},
}

# Exaltation and debilitation points (degrees)
EXALTATION_POINTS = {
    "Sun": ("Aries", 10),
    "Moon": ("Taurus", 3),
    "Mars": ("Capricorn", 28),
    "Mercury": ("Virgo", 15),
    "Jupiter": ("Cancer", 5),
    "Venus": ("Pisces", 27),
    "Saturn": ("Libra", 20),
}

DEBILITATION_POINTS = {
    "Sun": ("Libra", 10),
    "Moon": ("Scorpio", 3),
    "Mars": ("Cancer", 28),
    "Mercury": ("Pisces", 15),
    "Jupiter": ("Capricorn", 5),
    "Venus": ("Virgo", 27),
    "Saturn": ("Aries", 20),
}

# Zodiac sign order for calculations
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

_SIGN_ALIASES = {
    # Western
    "aries": "Aries",
    "taurus": "Taurus",
    "gemini": "Gemini",
    "cancer": "Cancer",
    "leo": "Leo",
    "virgo": "Virgo",
    "libra": "Libra",
    "scorpio": "Scorpio",
    "sagittarius": "Sagittarius",
    "capricorn": "Capricorn",
    "aquarius": "Aquarius",
    "pisces": "Pisces",
    # Vedic (Rashi) -> Western sign names (same 12-sign order, different labels)
    "mesha": "Aries",
    "vrishabha": "Taurus",
    "mithuna": "Gemini",
    "karka": "Cancer",
    "simha": "Leo",
    "kanya": "Virgo",
    "tula": "Libra",
    "vrischika": "Scorpio",
    "dhanu": "Sagittarius",
    "makara": "Capricorn",
    "kumbha": "Aquarius",
    "meena": "Pisces",
}


class PlanetaryStrengthService:
    """Service for calculating planetary strength and impact scores."""

    def __init__(self):
        pass

    def _normalize_sign_name(self, sign: str) -> str:
        value = (sign or "").strip()
        if not value:
            return "Aries"
        return _SIGN_ALIASES.get(value.lower(), value[:1].upper() + value[1:].lower())

    def _sign_to_index(self, sign: str) -> int:
        """Convert sign name to index (0-11)."""
        sign = self._normalize_sign_name(sign)
        try:
            return ZODIAC_SIGNS.index(sign)
        except ValueError:
            return 0

    def _calculate_sign_distance(self, sign1: str, sign2: str) -> int:
        """Calculate distance between two signs (0-11)."""
        idx1 = self._sign_to_index(sign1)
        idx2 = self._sign_to_index(sign2)
        return (idx2 - idx1) % 12

    def calculate_positional_strength(self, planet: str, sign: str, degree: float) -> Dict[str, Any]:
        """
        Calculate positional strength (Sthanabala) - simplified Shadbala component.

        Returns a score from 0-100 based on:
        - Exaltation/Debilitation
        - Sign placement (own sign, friendly sign, etc.)
        """
        sign = self._normalize_sign_name(sign)
        score = 50.0  # Neutral baseline

        # Check exaltation
        if planet in EXALTATION_POINTS:
            exalt_sign, exalt_degree = EXALTATION_POINTS[planet]
            if sign == exalt_sign:
                # Maximum strength at exact exaltation degree, scales with distance
                degree_diff = abs(degree - exalt_degree)
                exalt_strength = max(0, 50 - (degree_diff * 50 / 30))  # Linear drop across sign
                score += exalt_strength
                dignity = "exalted"
            else:
                dignity = "neutral"
        else:
            dignity = "neutral"

        # Check debilitation
        if planet in DEBILITATION_POINTS:
            debil_sign, debil_degree = DEBILITATION_POINTS[planet]
            if sign == debil_sign:
                degree_diff = abs(degree - debil_degree)
                debil_weakness = max(0, 50 - (degree_diff * 50 / 30))
                score -= debil_weakness
                dignity = "debilitated"

        # Clamp score to 0-100
        score = max(0, min(100, score))

        return {
            "score": round(score, 2),
            "dignity": dignity,
            "factors": {
                "exaltation_component": round(score - 50, 2) if score > 50 else 0,
                "debilitation_component": round(50 - score, 2) if score < 50 else 0,
            },
        }

    def calculate_directional_strength(self, planet: str, house: Optional[int]) -> float:
        """
        Calculate directional strength (Digbala).

        Certain planets gain strength in specific angular houses:
        - Mercury & Jupiter: 1st house (East)
        - Sun & Mars: 10th house (South)
        - Saturn: 7th house (West)
        - Moon & Venus: 4th house (North)
        """
        if house is None:
            return 50.0

        directional_houses = {
            "Mercury": 1,
            "Jupiter": 1,
            "Sun": 10,
            "Mars": 10,
            "Saturn": 7,
            "Moon": 4,
            "Venus": 4,
        }

        if planet in directional_houses:
            preferred_house = directional_houses[planet]
            if house == preferred_house:
                return 100.0  # Maximum strength
            elif house in [preferred_house - 1, preferred_house + 1]:
                return 75.0  # Adjacent house, good strength
            else:
                return 50.0  # Neutral
        else:
            return 50.0  # Rahu/Ketu don't have traditional digbala

    def calculate_temporal_strength(self, planet: str, is_day_birth: bool, is_retrograde: bool) -> Dict[str, float]:
        """
        Calculate temporal strength (Kalabala) components.

        Considers:
        - Day/Night strength (some planets are stronger during day, others at night)
        - Retrograde status (retrograde planets have special strength)
        """
        day_planets = ["Sun", "Jupiter", "Venus"]
        night_planets = ["Moon", "Mars", "Saturn"]

        day_night_strength = 50.0

        if planet in day_planets:
            day_night_strength = 75.0 if is_day_birth else 25.0
        elif planet in night_planets:
            day_night_strength = 75.0 if not is_day_birth else 25.0

        # Retrograde strength (retrograde planets are considered strong)
        retrograde_strength = 75.0 if is_retrograde else 50.0

        return {
            "day_night": day_night_strength,
            "retrograde": retrograde_strength,
        }

    def calculate_overall_strength(
        self,
        planet: str,
        sign: str,
        degree: float,
        house: Optional[int] = None,
        is_day_birth: bool = True,
        is_retrograde: bool = False,
    ) -> Dict[str, Any]:
        """
        Calculate overall planetary strength combining multiple factors.

        Returns a comprehensive strength analysis with scores and breakdown.
        """
        sign = self._normalize_sign_name(sign)
        positional = self.calculate_positional_strength(planet, sign, degree)
        directional = self.calculate_directional_strength(planet, house)
        temporal = self.calculate_temporal_strength(planet, is_day_birth, is_retrograde)

        # Weighted average (positional is most important)
        overall_score = (
            positional["score"] * 0.5 + directional * 0.25 + (temporal["day_night"] + temporal["retrograde"]) / 2 * 0.25
        )

        strength_label = "weak"
        if overall_score >= 75:
            strength_label = "very_strong"
        elif overall_score >= 60:
            strength_label = "strong"
        elif overall_score >= 40:
            strength_label = "moderate"

        return {
            "planet": planet,
            "overall_score": round(overall_score, 2),
            "strength_label": strength_label,
            "components": {
                "positional": positional,
                "directional": round(directional, 2),
                "temporal": temporal,
            },
            "dignity": positional["dignity"],
        }

    def calculate_dasha_impact(
        self, dasha_lord: str, planet_positions: Dict[str, Dict], birth_chart: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Calculate the impact of a dasha period across life areas.

        Args:
            dasha_lord: The ruling planet of the dasha
            planet_positions: Dictionary of planet positions {planet_name: {sign, degree, house, ...}}
            birth_chart: Optional birth chart data for contextual analysis

        Returns:
            Dictionary with impact scores for career, relationships, health, spiritual
        """
        # Get the dasha lord's position
        lord_position = planet_positions.get(dasha_lord, {})
        if not lord_position:
            # Fallback for Rahu/Ketu or missing data
            lord_position = {"sign": "Aries", "degree": 0, "house": None}

        # Calculate strength of dasha lord
        strength = self.calculate_overall_strength(
            dasha_lord,
            lord_position.get("sign", "Aries"),
            lord_position.get("degree", 0),
            lord_position.get("house"),
            is_retrograde=lord_position.get("retrograde", False),
        )

        # Base impact from planet's natural significations
        base_impact = PLANET_SIGNIFICATIONS.get(
            dasha_lord,
            {
                "career": 0.5,
                "relationships": 0.5,
                "health": 0.5,
                "spiritual": 0.5,
            },
        )

        # Adjust impact based on planet's strength
        strength_factor = strength["overall_score"] / 100.0

        # Calculate scores (0-10 scale)
        impact_scores = {
            "career": round(base_impact["career"] * strength_factor * 10, 1),
            "relationships": round(base_impact["relationships"] * strength_factor * 10, 1),
            "health": round(base_impact["health"] * strength_factor * 10, 1),
            "spiritual": round(base_impact["spiritual"] * strength_factor * 10, 1),
        }

        # Determine overall tone
        if strength_factor >= 0.75:
            tone = "supportive"
            tone_description = "Strong, favorable period with good results"
        elif strength_factor >= 0.60:
            tone = "positive"
            tone_description = "Generally positive with steady progress"
        elif strength_factor >= 0.40:
            tone = "mixed"
            tone_description = "Mixed results, requires effort and patience"
        elif strength_factor >= 0.25:
            tone = "challenging"
            tone_description = "Challenging period, obstacles may arise"
        else:
            tone = "transformative"
            tone_description = "Difficult but transformative, lessons to learn"

        return {
            "dasha_lord": dasha_lord,
            "strength": strength,
            "impact_scores": impact_scores,
            "tone": tone,
            "tone_description": tone_description,
            "keywords": PLANET_SIGNIFICATIONS.get(dasha_lord, {}).get("keywords", []),
        }

    def compare_dasha_impacts(self, current_lord: str, next_lord: str, planet_positions: Dict[str, Dict]) -> Dict[str, Any]:
        """
        Compare the impact of current vs next dasha period.

        Returns delta scores showing what increases/decreases in the transition.
        """
        current_impact = self.calculate_dasha_impact(current_lord, planet_positions)
        next_impact = self.calculate_dasha_impact(next_lord, planet_positions)

        deltas = {
            "career": round(next_impact["impact_scores"]["career"] - current_impact["impact_scores"]["career"], 1),
            "relationships": round(
                next_impact["impact_scores"]["relationships"] - current_impact["impact_scores"]["relationships"], 1
            ),
            "health": round(next_impact["impact_scores"]["health"] - current_impact["impact_scores"]["health"], 1),
            "spiritual": round(next_impact["impact_scores"]["spiritual"] - current_impact["impact_scores"]["spiritual"], 1),
        }

        # Determine major shift areas
        major_shifts = []
        for area, delta in deltas.items():
            if abs(delta) >= 2.0:
                direction = "increases" if delta > 0 else "decreases"
                major_shifts.append(f"{area} {direction} significantly")

        return {
            "current": current_impact,
            "next": next_impact,
            "deltas": deltas,
            "major_shifts": major_shifts,
            "transition_summary": f"Shifting from {current_impact['tone']} {current_lord} to {next_impact['tone']} {next_lord}",
        }
