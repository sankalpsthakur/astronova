"""Transit calculation service for relationship compatibility features.

This service calculates transit-to-natal aspects to determine when synastry
aspects are activated by current planetary movements.
"""

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from services.ephemeris_service import EphemerisService

logger = logging.getLogger(__name__)

# Aspect angles and their orbs (degrees of allowable deviation)
ASPECT_CONFIG = {
    "conjunction": {"angle": 0, "orb": 8, "harmonious": True},
    "sextile": {"angle": 60, "orb": 6, "harmonious": True},
    "square": {"angle": 90, "orb": 7, "harmonious": False},
    "trine": {"angle": 120, "orb": 8, "harmonious": True},
    "opposition": {"angle": 180, "orb": 8, "harmonious": False},
}

# Fast-moving planets that trigger transits (ordered by speed)
TRIGGER_PLANETS = ["moon", "mercury", "venus", "sun", "mars"]

# Relationship pulse states
PULSE_STATES = ["flowing", "electric", "magnetic", "grounded", "friction"]


def _angular_distance(lon1: float, lon2: float) -> float:
    """Calculate the shortest angular distance between two longitudes."""
    diff = abs((lon1 - lon2 + 180) % 360 - 180)
    return diff


def _check_aspect(transit_lon: float, natal_lon: float) -> Optional[Tuple[str, float, float]]:
    """Check if transit planet forms an aspect to natal planet.

    Returns: (aspect_type, orb_difference, strength) or None
    """
    for aspect_type, config in ASPECT_CONFIG.items():
        target_angle = config["angle"]
        max_orb = config["orb"]

        diff = _angular_distance(transit_lon, natal_lon)
        orb_diff = abs(diff - target_angle)

        if orb_diff <= max_orb:
            # Strength: 1.0 when exact, decays linearly to 0 at orb boundary
            strength = 1.0 - (orb_diff / max_orb)
            return (aspect_type, orb_diff, strength)

    return None


class TransitService:
    """Service for calculating transit activations on synastry aspects."""

    def __init__(self, ephemeris_service: Optional[EphemerisService] = None):
        self.ephemeris = ephemeris_service or EphemerisService()

    def is_aspect_activated_now(
        self,
        synastry_aspect: Dict[str, Any],
        target_date: datetime,
        natal_a: Dict[str, Any],
        natal_b: Dict[str, Any],
    ) -> Tuple[bool, float]:
        """Check if a synastry aspect is currently activated by transits.

        A synastry aspect is "activated" when a transiting planet forms an aspect
        to either of the natal planets involved in the synastry aspect.

        Args:
            synastry_aspect: Dict with 'planet1'/'planetA' and 'planet2'/'planetB' keys
            target_date: Date to check transits for
            natal_a: First person's natal positions {'planets': {...}}
            natal_b: Second person's natal positions {'planets': {...}}

        Returns:
            Tuple of (is_activated, activation_strength) where strength is 0.0-1.0
        """
        # Get transiting planet positions
        transits = self.ephemeris.get_positions_for_date(target_date)
        transit_planets = transits.get("planets", {})

        # Extract the natal planets in the synastry aspect
        planet_a_key = synastry_aspect.get("planet1") or synastry_aspect.get("planetA", "")
        planet_b_key = synastry_aspect.get("planet2") or synastry_aspect.get("planetB", "")

        # Normalize to lowercase for lookup
        planet_a_key = planet_a_key.lower()
        planet_b_key = planet_b_key.lower()

        # Get natal longitudes
        natal_a_planets = natal_a.get("planets", {})
        natal_b_planets = natal_b.get("planets", {})

        # Planet A is from person A, Planet B is from person B
        natal_lon_a = natal_a_planets.get(planet_a_key, {}).get("longitude")
        natal_lon_b = natal_b_planets.get(planet_b_key, {}).get("longitude")

        max_strength = 0.0
        is_activated = False

        # Check if any fast-moving transiting planet aspects either natal planet
        for trigger_planet in TRIGGER_PLANETS:
            transit_data = transit_planets.get(trigger_planet, {})
            transit_lon = transit_data.get("longitude")

            if transit_lon is None:
                continue

            # Check transit to natal planet A
            if natal_lon_a is not None:
                aspect_result = _check_aspect(transit_lon, natal_lon_a)
                if aspect_result:
                    aspect_type, _, strength = aspect_result
                    # Boost harmonious transits slightly
                    if ASPECT_CONFIG[aspect_type]["harmonious"]:
                        strength *= 1.1
                    max_strength = max(max_strength, strength)
                    is_activated = True

            # Check transit to natal planet B
            if natal_lon_b is not None:
                aspect_result = _check_aspect(transit_lon, natal_lon_b)
                if aspect_result:
                    aspect_type, _, strength = aspect_result
                    if ASPECT_CONFIG[aspect_type]["harmonious"]:
                        strength *= 1.1
                    max_strength = max(max_strength, strength)
                    is_activated = True

        return is_activated, min(1.0, max_strength)

    def get_day_activations(
        self,
        synastry_aspects: List[Dict[str, Any]],
        target_date: datetime,
        natal_a: Dict[str, Any],
        natal_b: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        """Get all aspect activations for a specific day.

        Returns list of activated aspects with their strengths.
        """
        activations = []

        for aspect in synastry_aspects:
            is_active, strength = self.is_aspect_activated_now(
                aspect, target_date, natal_a, natal_b
            )

            if is_active and strength >= 0.3:  # Minimum threshold
                planet1 = aspect.get("planet1") or aspect.get("planetA", "")
                planet2 = aspect.get("planet2") or aspect.get("planetB", "")
                aspect_type = aspect.get("aspect") or aspect.get("aspectType", "")
                is_harmonious = aspect.get("compatibility", 0) > 0 or aspect.get("isHarmonious", True)

                activations.append({
                    "aspect": aspect,
                    "strength": strength,
                    "is_harmonious": is_harmonious,
                    "description": f"{planet1} {aspect_type} {planet2}",
                })

        # Sort by strength descending
        activations.sort(key=lambda x: x["strength"], reverse=True)
        return activations

    def find_next_significant_transit(
        self,
        synastry_aspects: List[Dict[str, Any]],
        start_date: datetime,
        natal_a: Dict[str, Any],
        natal_b: Dict[str, Any],
        days_ahead: int = 30,
    ) -> Dict[str, Any]:
        """Find the next significant shift in relationship energy.

        Scans ahead to find when a new major transit activation begins.

        Returns:
            Dict with date, days_away, description, predicted_state, suggestion
        """
        previous_activations = self.get_day_activations(
            synastry_aspects, start_date, natal_a, natal_b
        )
        previous_count = len(previous_activations)

        for day_offset in range(1, days_ahead + 1):
            check_date = start_date + timedelta(days=day_offset)

            current_activations = self.get_day_activations(
                synastry_aspects, check_date, natal_a, natal_b
            )

            # Detect significant changes
            current_count = len(current_activations)
            new_activations = [
                a for a in current_activations
                if a["strength"] >= 0.7 and not any(
                    self._same_aspect(a, prev) for prev in previous_activations
                )
            ]

            # Significant shift: new high-strength activation or major change
            if new_activations or abs(current_count - previous_count) >= 2:
                # Determine the nature of the shift
                harmonious_count = sum(1 for a in current_activations if a["is_harmonious"])
                challenging_count = len(current_activations) - harmonious_count

                if harmonious_count > challenging_count:
                    predicted_state = "flowing"
                    description = "Harmonious transits activate - energy flows more easily"
                    suggestion = "Great time for meaningful conversations and connection"
                elif challenging_count > harmonious_count:
                    predicted_state = "friction"
                    description = "Challenging transits require patience and understanding"
                    suggestion = "Be patient and avoid escalating disagreements"
                else:
                    predicted_state = "electric"
                    description = "Mixed energy creates dynamic tension and excitement"
                    suggestion = "Stay flexible and embrace the unexpected"

                return {
                    "date": check_date.isoformat(),
                    "days_away": day_offset,
                    "description": description,
                    "predicted_state": predicted_state,
                    "suggestion": suggestion,
                }

            previous_activations = current_activations
            previous_count = current_count

        # No major shift found - return gentle fallback
        fallback_date = start_date + timedelta(days=7)
        return {
            "date": fallback_date.isoformat(),
            "days_away": 7,
            "description": "Energy continues in current pattern with subtle shifts",
            "predicted_state": "grounded",
            "suggestion": "Maintain steady connection and be present",
        }

    def calculate_pulse_from_transits(
        self,
        synastry_aspects: List[Dict[str, Any]],
        target_date: datetime,
        natal_a: Dict[str, Any],
        natal_b: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Calculate relationship pulse from actual transit activations.

        Returns:
            Dict with state, score, label, topActivations
        """
        activations = self.get_day_activations(
            synastry_aspects, target_date, natal_a, natal_b
        )

        harmonious_count = sum(1 for a in activations if a["is_harmonious"])
        challenging_count = len(activations) - harmonious_count
        total_strength = sum(a["strength"] for a in activations)

        # Determine state based on activation balance
        # Scores are calibrated so: 85+=peak, 70+=intense, 55+=strong, 40+=moderate, <40=gentle
        if not activations:
            state = "grounded"
            score = 50  # moderate
        elif harmonious_count > challenging_count * 1.5:
            state = "flowing"
            # Scale from 55 (strong) to 80 (intense) based on harmonious count
            score = min(80, 55 + int(harmonious_count * 5))
        elif harmonious_count > challenging_count:
            state = "electric"
            # Scale from 50 to 70
            score = min(70, 50 + int(harmonious_count * 4))
        elif challenging_count > harmonious_count:
            state = "friction"
            # Lower scores for friction (40-55)
            score = max(35, 55 - int(challenging_count * 4))
        else:
            state = "magnetic"
            # Balanced state (55-75)
            score = min(75, 55 + int(total_strength * 5))

        # Get top activations for display
        top_activations = [a["description"] for a in activations[:2]]
        if not top_activations:
            top_activations = ["Gentle cosmic rhythm"]

        return {
            "state": state,
            "score": score,
            "label": state.title(),
            "topActivations": top_activations,
        }

    def build_journey_forecast(
        self,
        synastry_aspects: List[Dict[str, Any]],
        target_date: datetime,
        natal_a: Dict[str, Any],
        natal_b: Dict[str, Any],
        days: int = 30,
    ) -> Dict[str, Any]:
        """Build a multi-day journey forecast based on real transits.

        Returns:
            Dict with dailyMarkers and peakWindows
        """
        daily_markers = []
        peak_windows = []

        in_peak_window = False
        peak_start = None
        peak_days = []

        for day_offset in range(days):
            current_date = target_date + timedelta(days=day_offset)

            activations = self.get_day_activations(
                synastry_aspects, current_date, natal_a, natal_b
            )

            # Calculate intensity
            harmonious = sum(1 for a in activations if a["is_harmonious"])
            challenging = len(activations) - harmonious
            total_strength = sum(a["strength"] for a in activations)

            if not activations:
                intensity = "quiet"
                reason = None
            elif total_strength >= 1.8 and harmonious >= 2:
                intensity = "peak"
                reason = activations[0]["description"] if activations else None
            elif total_strength >= 1.2 and harmonious >= 1:
                intensity = "elevated"
                reason = activations[0]["description"] if activations else None
            elif challenging > harmonious:
                intensity = "challenging"
                reason = activations[0]["description"] if activations else None
            else:
                intensity = "neutral"
                reason = None

            daily_markers.append({
                "date": current_date.isoformat(),
                "intensity": intensity,
                "reason": reason,
            })

            # Track peak windows
            if intensity in ("peak", "elevated") and harmonious > 0:
                if not in_peak_window:
                    in_peak_window = True
                    peak_start = current_date
                    peak_days = [current_date]
                else:
                    peak_days.append(current_date)
            else:
                if in_peak_window and len(peak_days) >= 2:
                    peak_windows.append({
                        "startDate": peak_start.isoformat(),
                        "endDate": peak_days[-1].isoformat(),
                        "label": "Harmony window",
                        "suggestion": "Perfect for meaningful conversations and romantic moments",
                    })
                in_peak_window = False
                peak_days = []

        # Close any open peak window
        if in_peak_window and len(peak_days) >= 2:
            peak_windows.append({
                "startDate": peak_start.isoformat(),
                "endDate": peak_days[-1].isoformat(),
                "label": "Connection peak",
                "suggestion": "Great opportunity for deepening your bond",
            })

        return {
            "dailyMarkers": daily_markers,
            "peakWindows": peak_windows[:3],  # Limit to 3 peak windows
        }

    def _same_aspect(self, a: Dict[str, Any], b: Dict[str, Any]) -> bool:
        """Check if two activation dicts refer to the same aspect."""
        return a.get("description") == b.get("description")
