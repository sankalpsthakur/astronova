"""
Prediction Service -- Transit-triggered event prediction using a Bayesian framework.

Computes month-by-month event hypotheses by combining transit triggers from
slow-moving planets (Jupiter, Saturn, Rahu/Ketu), current dasha state, and
optional user-provided real-world context priors.

Transit computations use approximate mean longitudes and planetary speeds
rather than exact Swiss Ephemeris positions.  The ephemeris service handles
precise positions when needed; this service focuses on trigger timing.
"""

from __future__ import annotations

import logging
import math
from calendar import monthrange
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

J2000 = datetime(2000, 1, 1, 12, 0, 0)

# Mean longitudes at J2000.0 and mean daily motions (degrees / day).
SLOW_PLANETS: Dict[str, Dict[str, Any]] = {
    "Jupiter": {"mean_lon_j2000": 34.35, "daily_motion": 0.0831, "retrograde": False},
    "Saturn": {"mean_lon_j2000": 50.08, "daily_motion": 0.0335, "retrograde": False},
    "Rahu":    {"mean_lon_j2000": 125.04, "daily_motion": -0.0529, "retrograde": True},
}

# Ketu is always 180 degrees opposite Rahu.
KETU = "Ketu"

# All planets for which natal positions are computed.
NATAL_PLANETS = [
    "Sun", "Moon", "Mercury", "Venus", "Mars",
    "Jupiter", "Saturn", "Rahu", "Ketu",
]

# Mean longitudes at J2000 for fast-moving (natal-only) planets.
FAST_PLANET_J2000: Dict[str, float] = {
    "Sun": 280.46, "Moon": 218.32, "Mercury": 252.25,
    "Venus": 181.98, "Mars": 355.45,
}

# Aspect angles and orbs for slow-planet triggers.
ASPECT_CONFIG: Dict[str, Dict[str, Any]] = {
    "conjunction": {"angle": 0,   "orb": 8.0},
    "opposition":  {"angle": 180, "orb": 8.0},
    "trine":       {"angle": 120, "orb": 8.0},
    "square":      {"angle": 90,  "orb": 7.0},
}

HOUSE_TOPICS: Dict[int, str] = {
    1:  "identity, health, vitality",
    2:  "wealth, family, speech",
    3:  "courage, communication, skills",
    4:  "home, mother, property",
    5:  "creativity, children, romance",
    6:  "obstacles, service, health",
    7:  "relationships, partnerships",
    8:  "transformation, inheritance, occult",
    9:  "wisdom, fortune, higher learning",
    10: "career, status, authority",
    11: "gains, friendships, income",
    12: "spiritual, loss, foreign lands",
}

# Event class derivation keyed by (transiting_planet, house_number).
EVENT_CLASS_MAP: Dict[str, List[str]] = {
    "Jupiter_1":  ["spiritual", "capital"],
    "Jupiter_2":  ["capital"],
    "Jupiter_5":  ["capital", "relationship"],
    "Jupiter_7":  ["relationship", "capital"],
    "Jupiter_9":  ["spiritual", "relocation"],
    "Jupiter_10": ["career", "capital"],
    "Jupiter_11": ["capital"],
    "Saturn_1":   ["health", "spiritual"],
    "Saturn_4":   ["relocation", "relationship"],
    "Saturn_7":   ["relationship"],
    "Saturn_10":  ["career"],
    "Saturn_12":  ["spiritual", "relocation"],
    "Rahu_1":     ["spiritual", "health"],
    "Rahu_7":     ["relationship"],
    "Rahu_10":    ["career", "capital"],
    "Rahu_12":    ["spiritual", "relocation"],
    "Ketu_1":     ["health", "spiritual"],
    "Ketu_4":     ["relocation", "relationship"],
    "Ketu_7":     ["relationship"],
    "Ketu_10":    ["career"],
    "Ketu_12":    ["spiritual", "relocation"],
}

ASPECT_THEME: Dict[str, str] = {
    "conjunction": "intensification",
    "opposition":  "confrontation / awareness",
    "trine":       "flow / opportunity",
    "square":      "tension / breakthrough",
}

PROBABILITY_BANDS: List[str] = ["low", "medium-low", "medium", "medium-high", "high"]

# ---------------------------------------------------------------------------
# Helpers -- time
# ---------------------------------------------------------------------------


def _days_since_j2000(dt: datetime) -> float:
    """Return days elapsed since J2000.0 (2000-01-01 12:00 UTC)."""
    return (dt - J2000).total_seconds() / 86400.0


def _parse_iso_date(date_str: str) -> datetime:
    """Parse an ISO-8601 date or datetime string into a UTC-aware datetime."""
    s = date_str.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(s)
    except ValueError:
        return datetime.strptime(s[:10], "%Y-%m-%d")


def _month_key(dt: datetime) -> str:
    """Return YYYY-MM string for a datetime."""
    return dt.strftime("%Y-%m")


def _first_of_month(month_key: str) -> datetime:
    """Return a datetime for the first day of YYYY-MM."""
    return datetime.strptime(month_key, "%Y-%m")


def _format_date(dt: datetime) -> str:
    """Return ISO date-only string."""
    return dt.strftime("%Y-%m-%d")


# ---------------------------------------------------------------------------
# Helpers -- astronomy
# ---------------------------------------------------------------------------


def _mean_lon(planet: str, days: float) -> float:
    """Approximate mean ecliptic longitude for *planet* at *days* since J2000."""
    if planet == KETU:
        return (_mean_lon("Rahu", days) + 180.0) % 360.0

    if planet in SLOW_PLANETS:
        cfg = SLOW_PLANETS[planet]
        return (cfg["mean_lon_j2000"] + cfg["daily_motion"] * days) % 360.0

    if planet in FAST_PLANET_J2000:
        motions: Dict[str, float] = {
            "Sun": 0.9856, "Moon": 13.1764, "Mercury": 4.0923,
            "Venus": 1.6021, "Mars": 0.5240,
        }
        base = FAST_PLANET_J2000.get(planet, 0.0)
        daily = motions.get(planet, 0.0)
        return (base + daily * days) % 360.0

    return 0.0


def _angular_distance(a: float, b: float) -> float:
    """Shortest angular distance between two longitudes (degrees)."""
    diff = abs((a - b + 180.0) % 360.0 - 180.0)
    return diff


def _sign_index(lon: float) -> int:
    """Return zodiac sign index (0=Aries ... 11=Pisces) for a longitude."""
    return int(lon // 30) % 12


def _house_from_lon(planet_lon: float, ascendant_lon: float) -> int:
    """Whole-sign house number (1-12) for a planet longitude given the ascendant."""
    asc_sign = _sign_index(ascendant_lon)
    planet_sign = _sign_index(planet_lon)
    return ((planet_sign - asc_sign) % 12) + 1


def _compute_ascendant(birth_dt: datetime, lat: float, lon: float) -> float:
    """Approximate ascendant longitude in degrees.

    Uses a simplified formula from Meeus (Astronomical Algorithms, Ch. 14).
    Accuracy is ~0.5 degrees -- sufficient for whole-sign house assignment.
    """
    jd = _days_since_j2000(birth_dt) + 2451545.0
    gmst_0h = (280.46061837 + 360.98564736629 * (jd - 2451545.0)) % 360.0
    ut_hours = birth_dt.hour + birth_dt.minute / 60.0 + birth_dt.second / 3600.0
    gmst = (gmst_0h + ut_hours * 15.04107) % 360.0
    lst = (gmst + lon) % 360.0
    lst_rad = math.radians(lst)
    lat_rad = math.radians(lat)
    obliquity = math.radians(23.439 - 0.0000004 * (jd - 2451545.0))
    numerator = -math.cos(lst_rad)
    denominator = math.sin(lst_rad) * math.cos(obliquity) + math.tan(lat_rad) * math.sin(obliquity)
    asc_rad = math.atan2(numerator, denominator)
    return math.degrees(asc_rad) % 360.0


def _compute_natal_positions(birth_data: Dict[str, Any]) -> Dict[str, float]:
    """Compute approximate natal planet longitudes from *birth_data*."""
    date_str = birth_data.get("date", "")
    time_str = birth_data.get("time", "12:00:00")
    birth_dt = _parse_iso_date(f"{date_str}T{time_str}")
    days = _days_since_j2000(birth_dt)
    return {p: _mean_lon(p, days) for p in NATAL_PLANETS}


def _compute_natal_houses(
    natal_positions: Dict[str, float], ascendant_lon: float
) -> Dict[str, int]:
    """Map each planet to its whole-sign house (1-12)."""
    return {p: _house_from_lon(lon, ascendant_lon) for p, lon in natal_positions.items()}


# ---------------------------------------------------------------------------
# Trigger computation helpers
# ---------------------------------------------------------------------------


def _find_aspect_date(
    transiting_planet: str,
    natal_lon: float,
    aspect_angle: float,
    search_start_days: float,
    search_end_days: float,
) -> Optional[float]:
    """Return days-since-J2000 when *transiting_planet* exactly aspects *natal_lon*.

    Ketu is handled by deriving from Rahu with a 180-degree offset.
    """
    lookup_planet = "Rahu" if transiting_planet == KETU else transiting_planet
    cfg = SLOW_PLANETS[lookup_planet]
    base_lon = cfg["mean_lon_j2000"]
    motion = cfg["daily_motion"]
    if transiting_planet == KETU:
        base_lon = (base_lon + 180.0) % 360.0

    target_lon = (natal_lon + aspect_angle) % 360.0

    mid_days = (search_start_days + search_end_days) / 2.0
    k_approx = (motion * mid_days + base_lon - target_lon) / 360.0

    candidates: List[float] = []
    for k_offset in (-2, -1, 0, 1, 2):
        k = round(k_approx) + k_offset
        days = (target_lon + 360.0 * k - base_lon) / motion
        if search_start_days - 30 <= days <= search_end_days + 30:
            candidates.append(days)

    if not candidates:
        return None
    candidates.sort(key=lambda d: abs(d - mid_days))
    return candidates[0]


def _effective_window(
    exact_days: float, daily_motion: float, orb_deg: float
) -> Tuple[float, float]:
    """Return (start_days, end_days) during which the aspect is within orb."""
    half_window = orb_deg / abs(daily_motion)
    return (exact_days - half_window, exact_days + half_window)


def _date_from_days(days: float) -> datetime:
    """Convert days-since-J2000 back to a datetime."""
    return J2000 + timedelta(days=days)


def _event_class(transiting: str, natal: str, house: int, aspect_type: str) -> str:
    """Determine the primary event class for a trigger."""
    # Specific high-signal combinations first.
    if transiting == "Jupiter" and natal == "Mars":
        return "capital"
    if transiting == "Saturn" and natal == "Jupiter":
        return "career"
    if transiting == "Rahu" and natal == "Sun":
        return "career"
    if transiting == "Ketu" and natal == "Moon":
        return "relationship"
    if transiting == "Rahu" and natal == "Moon":
        return "relationship"
    if transiting == "Jupiter" and natal == "Venus":
        return "capital"
    if transiting == "Saturn" and natal == "Mercury":
        return "career"
    if transiting == "Rahu" and natal == "Venus":
        return "capital"
    if transiting == "Jupiter" and natal == "Mercury":
        return "capital"
    key = f"{transiting}_{house}"
    classes = EVENT_CLASS_MAP.get(key, ["spiritual"])
    return classes[0]


def _interpretation_text(
    transiting: str, natal: str, aspect_type: str, house: int, event_cls: str,
) -> str:
    """Generate a one-sentence interpretation for a trigger."""
    theme = ASPECT_THEME.get(aspect_type, "activation")
    house_topic = HOUSE_TOPICS.get(house, "life circumstances")
    templates: Dict[str, str] = {
        "capital": (
            f"{transiting} {aspect_type} natal {natal} activates resource and capital "
            f"flows through {house_topic} -- a {theme} period for financial decisions."
        ),
        "career": (
            f"{transiting} {aspect_type} natal {natal} triggers a {theme} in career "
            f"and public standing via {house_topic}."
        ),
        "relationship": (
            f"{transiting} {aspect_type} natal {natal} brings {theme} to relationships "
            f"through the domain of {house_topic}."
        ),
        "relocation": (
            f"{transiting} {aspect_type} natal {natal} signals {theme} around relocation "
            f"or environment change via {house_topic}."
        ),
        "health": (
            f"{transiting} {aspect_type} natal {natal} highlights {theme} in health "
            f"and daily routines through {house_topic}."
        ),
        "spiritual": (
            f"{transiting} {aspect_type} natal {natal} deepens spiritual {theme} "
            f"through {house_topic}."
        ),
    }
    return templates.get(event_cls, templates["spiritual"])


# ===================================================================
# PredictionService
# ===================================================================


class PredictionService:
    """Month-by-month transit-triggered event prediction with Bayesian priors.

    Combines slow-planet transit triggers, dasha state, and optional user
    context to produce a timeline of grounded, actionable event hypotheses.
    """

    # Planetary condition labels used in headlines and guidance.
    _PLANET_CONDITION: Dict[str, str] = {
        "Jupiter": "exalted, expansive",
        "Saturn": "compressive, structural",
        "Rahu":    "amplifying, destabilising",
        "Ketu":    "dissolving, clarifying",
        "Sun":     "authoritative, visible",
        "Moon":    "receptive, fluctuating",
        "Mars":    "combustive, executive",
        "Mercury": "analytical, transactional",
        "Venus":   "harmonising, valuing",
    }

    _ASPECT_POSTURE: Dict[str, str] = {
        "conjunction": "Intensification -- forces converge. Act with precision, not volume.",
        "opposition":  (
            "Polarity peaks. External pressure reveals internal gaps -- bridge them."
        ),
        "trine": (
            "Flow state opens. Effort multiplies; deploy during the window, "
            "don't plan through it."
        ),
        "square": (
            "Friction demands resolution. The obstacle IS the path -- "
            "break through or restructure."
        ),
    }

    # ------------------------------------------------------------------
    # Method 1: compute_transit_triggers
    # ------------------------------------------------------------------

    def compute_transit_triggers(
        self,
        birth_data: Dict[str, Any],
        start_date: str,
        end_date: str,
    ) -> List[Dict[str, Any]]:
        """Compute transit triggers from slow planets across a date window.

        Args:
            birth_data: Dict with keys date, time, timezone, latitude, longitude.
            start_date: ISO date string defining the window start.
            end_date: ISO date string defining the window end.

        Returns:
            List of trigger dicts, each with date, transiting_planet,
            natal_planet, aspect_type, orb, house_activated, event_class,
            interpretation.
        """
        start_dt = _parse_iso_date(start_date)
        end_dt = _parse_iso_date(end_date)
        start_days = _days_since_j2000(start_dt)
        end_days = _days_since_j2000(end_dt)

        natal_positions = _compute_natal_positions(birth_data)
        birth_dt = _parse_iso_date(
            f"{birth_data.get('date', '2000-01-01')}T"
            f"{birth_data.get('time', '12:00:00')}"
        )
        lat = float(birth_data.get("latitude", 0.0))
        lon = float(birth_data.get("longitude", 0.0))
        ascendant_lon = _compute_ascendant(birth_dt, lat, lon)
        natal_houses = _compute_natal_houses(natal_positions, ascendant_lon)

        triggers: List[Dict[str, Any]] = []

        for transiting_planet, cfg in SLOW_PLANETS.items():
            daily_motion = cfg["daily_motion"]

            transiting_bodies = [transiting_planet]
            if transiting_planet == "Rahu":
                transiting_bodies.append(KETU)

            for t_body in transiting_bodies:
                if t_body == KETU and transiting_planet != "Rahu":
                    continue
                body_motion = -daily_motion if t_body == KETU else daily_motion

                for natal_planet in NATAL_PLANETS:
                    natal_lon = natal_positions[natal_planet]
                    natal_house = natal_houses.get(natal_planet, 1)

                    for aspect_name, aspect_cfg in ASPECT_CONFIG.items():
                        aspect_angle = aspect_cfg["angle"]
                        orb_deg = aspect_cfg["orb"]

                        exact_days = _find_aspect_date(
                            t_body, natal_lon, aspect_angle, start_days, end_days,
                        )
                        if exact_days is None:
                            continue

                        exact_dt = _date_from_days(exact_days)
                        if exact_dt < start_dt or exact_dt > end_dt:
                            win_s, win_e = _effective_window(exact_days, body_motion, orb_deg)
                            win_start = _date_from_days(win_s)
                            win_end = _date_from_days(win_e)
                            if win_end < start_dt or win_start > end_dt:
                                continue

                        cls = _event_class(t_body, natal_planet, natal_house, aspect_name)
                        if t_body == natal_planet:
                            if t_body == "Jupiter":
                                cls = "spiritual"
                            elif t_body == "Saturn":
                                cls = "career"

                        transit_lon = _mean_lon(
                            t_body if t_body != KETU else "Rahu", exact_days
                        )
                        if t_body == KETU:
                            transit_lon = (transit_lon + 180.0) % 360.0
                        remaining_orb = _angular_distance(
                            transit_lon, (natal_lon + aspect_angle) % 360.0
                        )

                        triggers.append({
                            "date": _format_date(exact_dt),
                            "transiting_planet": t_body,
                            "natal_planet": natal_planet,
                            "aspect_type": aspect_name,
                            "orb": round(remaining_orb, 4),
                            "house_activated": natal_house,
                            "event_class": cls,
                            "interpretation": _interpretation_text(
                                t_body, natal_planet, aspect_name, natal_house, cls,
                            ),
                        })

        # Deduplicate and sort.
        seen: set = set()
        unique: List[Dict[str, Any]] = []
        for t in triggers:
            key = (t["date"], t["transiting_planet"], t["natal_planet"], t["aspect_type"])
            if key not in seen:
                seen.add(key)
                unique.append(t)
        unique.sort(key=lambda t: t["date"])

        logger.info(
            "Computed %d unique transit triggers for %s -> %s",
            len(unique), start_date, end_date,
        )
        return unique

    # ------------------------------------------------------------------
    # Method 2: generate_monthly_hypotheses
    # ------------------------------------------------------------------

    def generate_monthly_hypotheses(
        self,
        triggers: List[Dict[str, Any]],
        dasha_state: Dict[str, Any],
        start_date: str,
        end_date: str,
    ) -> List[Dict[str, Any]]:
        """Group transit triggers into monthly event hypotheses.

        Each hypothesis synthesises triggers active that month with the
        dasha lords to produce a concrete, grounded forecast -- specific
        DO and AVOID actions, not generic "favourable period" fluff.

        Args:
            triggers: Output from compute_transit_triggers.
            dasha_state: Dict with mahadasha.lord, antardasha.lord keys.
            start_date: ISO date string for window start.
            end_date: ISO date string for window end.

        Returns:
            List of monthly hypothesis dicts with keys month, primary_theme,
            secondary_theme, headline, trigger_summary, action_guidance,
            caution, probability_band, active_window (if triggers present).
        """
        start_dt = _parse_iso_date(start_date)
        end_dt = _parse_iso_date(end_date)

        maha_lord = (
            dasha_state.get("mahadasha", {}).get("lord", "")
            if isinstance(dasha_state.get("mahadasha"), dict) else ""
        )
        antar_lord = (
            dasha_state.get("antardasha", {}).get("lord", "")
            if isinstance(dasha_state.get("antardasha"), dict) else ""
        )

        triggers_by_month: Dict[str, List[Dict[str, Any]]] = {}
        for t in triggers:
            m = _month_key(_parse_iso_date(t["date"]))
            triggers_by_month.setdefault(m, []).append(t)

        current = datetime(start_dt.year, start_dt.month, 1)
        end_month = datetime(end_dt.year, end_dt.month, 1)

        hypotheses: List[Dict[str, Any]] = []
        while current <= end_month:
            mk = _month_key(current)
            month_triggers = triggers_by_month.get(mk, [])
            hypotheses.append(
                self._build_monthly_hypothesis(mk, month_triggers, maha_lord, antar_lord)
            )
            if current.month == 12:
                current = datetime(current.year + 1, 1, 1)
            else:
                current = datetime(current.year, current.month + 1, 1)

        logger.info(
            "Generated %d monthly hypotheses (%s -> %s, maha=%s, antar=%s)",
            len(hypotheses), start_date, end_date, maha_lord, antar_lord,
        )
        return hypotheses

    # ------------------------------------------------------------------
    # Hypothesis builder (grounded, actionable)
    # ------------------------------------------------------------------

    def _build_monthly_hypothesis(
        self,
        month_key: str,
        month_triggers: List[Dict[str, Any]],
        maha_lord: str,
        antar_lord: str,
    ) -> Dict[str, Any]:
        """Build a single month's hypothesis with grounded, concrete guidance.

        Every month gets a specific DO and a specific AVOID that reference
        the exact transit planets, dates, and dasha permission structure.
        """
        class_counts: Dict[str, int] = {}
        for t in month_triggers:
            cls = t["event_class"]
            class_counts[cls] = class_counts.get(cls, 0) + 1

        sorted_classes = sorted(class_counts.items(), key=lambda x: (-x[1], x[0]))
        primary_theme = sorted_classes[0][0] if sorted_classes else "spiritual"
        secondary_theme = sorted_classes[1][0] if len(sorted_classes) > 1 else "spiritual"

        # Headline.
        if month_triggers:
            top = max(
                month_triggers,
                key=lambda t: 0 if t["aspect_type"] in ("conjunction", "opposition") else 1,
            )
            headline = (
                f"{top['transiting_planet']} {top['aspect_type']} "
                f"natal {top['natal_planet']} -- "
                f"{self._pcond(top['transiting_planet'])}, "
                f"{self._pcond(top['natal_planet'])} natal. "
                f"{self._aposture(top['aspect_type'])}"
            )
            trigger_summary = "; ".join(
                f"{t['date']}: {t['transiting_planet']} {t['aspect_type']} "
                f"{t['natal_planet']} (house {t['house_activated']}, {t['event_class']})"
                for t in month_triggers
            )
            active_window = self._compute_active_window(month_triggers)
        else:
            headline = self._dasha_headline(maha_lord, antar_lord)
            trigger_summary = "No major slow-planet transits this month."
            active_window = None

        # Grounded guidance.
        if month_triggers:
            action_guidance, caution = self._build_grounded_guidance(
                month_triggers, maha_lord, antar_lord, primary_theme,
            )
        else:
            action_guidance, caution = self._build_dasha_only_guidance(maha_lord, antar_lord)

        # Probability band.
        n = len(month_triggers)
        if n >= 3:
            band = "high"
        elif n == 2:
            band = "medium-high"
        elif n == 1:
            band = "medium"
        elif maha_lord and antar_lord:
            band = "medium-low"
        else:
            band = "low"

        result: Dict[str, Any] = {
            "month": month_key,
            "primary_theme": primary_theme,
            "secondary_theme": secondary_theme,
            "headline": headline,
            "trigger_summary": trigger_summary,
            "action_guidance": action_guidance,
            "caution": caution,
            "probability_band": band,
            "trigger_count": n,
            "dasha_context": {"mahadasha_lord": maha_lord, "antardasha_lord": antar_lord},
        }
        if active_window:
            result["active_window"] = active_window
        return result

    # -- Condition / posture helpers --

    @classmethod
    def _pcond(cls, planet: str) -> str:
        return cls._PLANET_CONDITION.get(planet, "active")

    @classmethod
    def _aposture(cls, aspect_type: str) -> str:
        return cls._ASPECT_POSTURE.get(aspect_type, "Transit activation.")

    @staticmethod
    def _dasha_headline(maha_lord: str, antar_lord: str) -> str:
        permissions: Dict[str, str] = {
            "Jupiter": "expansion and teaching",
            "Saturn": "discipline and restructuring",
            "Mercury": "communication and commerce",
            "Venus": "relationships and value creation",
            "Mars": "action and initiative",
            "Sun": "authority and visibility",
            "Moon": "emotional integration and care",
            "Rahu": "ambition and disruption",
            "Ketu": "detachment and clarity",
        }
        maha_perm = permissions.get(maha_lord, "ongoing cycles")
        antar_perm = permissions.get(antar_lord, "refinement")
        if maha_lord and antar_lord:
            return (
                f"No major slow-planet triggers. {maha_lord} Mahadasha permits "
                f"{maha_perm}; {antar_lord} Antardasha focuses {antar_perm}. "
                f"Consolidation window -- build infrastructure, not headlines."
            )
        if maha_lord:
            return (
                f"No major slow-planet triggers. {maha_lord} Mahadasha permits "
                f"{maha_perm}. Integration and consolidation."
            )
        return "No major slow-planet triggers. Integration and consolidation."

    @staticmethod
    def _compute_active_window(month_triggers: List[Dict[str, Any]]) -> str:
        dates = sorted(t["date"] for t in month_triggers)
        return dates[0] if len(dates) == 1 else f"{dates[0]} - {dates[-1]}"

    # ------------------------------------------------------------------
    # Grounded guidance engine
    # ------------------------------------------------------------------

    def _build_grounded_guidance(
        self,
        month_triggers: List[Dict[str, Any]],
        maha_lord: str,
        antar_lord: str,
        primary_theme: str,
    ) -> Tuple[str, str]:
        """Build concrete DO and AVOID sentences from the actual transit
        configuration and dasha permission structure.

        Each trigger contributes one DO sentence. The AVOID aggregates
        risk patterns from all triggers.
        """
        do_parts: List[str] = []
        avoid_parts: List[str] = []

        for t in month_triggers:
            do_s, avoid_s = self._guidance_for_trigger(t, maha_lord, antar_lord)
            if do_s:
                do_parts.append(do_s)
            if avoid_s:
                avoid_parts.append(avoid_s)

        # Append dasha permission note.
        if maha_lord or antar_lord:
            note = self._dasha_permission_note(maha_lord, antar_lord)
            if note:
                do_parts.append(note)

        action = " ".join(do_parts) if do_parts else (
            f"No concrete triggers this month. "
            f"Use {maha_lord or 'the current'} dasha energy for foundational work."
        )
        caution = " ".join(avoid_parts) if avoid_parts else (
            "No specific transit cautions. Maintain baseline discipline."
        )
        return action, caution

    def _guidance_for_trigger(
        self, t: Dict[str, Any], maha_lord: str, antar_lord: str,
    ) -> Tuple[str, str]:
        """Return (do_sentence, avoid_sentence) for a single trigger.

        Looks up the master _TRIGGER_GUIDANCE table at module level.
        Falls back to theme-based templates if no exact match.
        """
        tp = t["transiting_planet"]
        np_ = t["natal_planet"]
        aspect = t["aspect_type"]
        cls = t["event_class"]
        date = t["date"]
        house = t["house_activated"]
        cond = self._pcond(tp)
        natal_cond = self._pcond(np_)
        dasha_str = (
            f"{maha_lord}/{antar_lord}" if maha_lord and antar_lord
            else (maha_lord or "ongoing")
        )
        orb_days = self._aspect_effective_days(tp, aspect)
        window = self._format_window(date, orb_days)

        key = (tp, np_, aspect, cls)
        guidance = _TRIGGER_GUIDANCE.get(key)
        if guidance:
            do_tpl, avoid_tpl = guidance
            fmt = dict(
                tp=tp, np=np_, cond=cond, natal_cond=natal_cond,
                dasha=dasha_str, window=window, house=house,
                maha=maha_lord, antar=antar_lord,
            )
            return do_tpl.format(**fmt), avoid_tpl.format(**fmt)

        return self._theme_guidance_fallback(
            tp, np_, aspect, cls, window, cond, dasha_str,
        )

    @staticmethod
    def _aspect_effective_days(transiting_planet: str, aspect_type: str) -> int:
        cfg = SLOW_PLANETS.get(transiting_planet, {"daily_motion": 0.08})
        orb = ASPECT_CONFIG.get(aspect_type, {}).get("orb", 7.0)
        raw = max(5, round(orb / abs(cfg["daily_motion"])))
        # Cap displayed window at 30 days for actionable focus.
        return min(raw, 30)

    @staticmethod
    def _format_window(date_str: str, orb_days: int) -> str:
        try:
            center = datetime.strptime(date_str, "%Y-%m-%d")
            start = center - timedelta(days=orb_days // 2)
            end = center + timedelta(days=orb_days // 2)
            return f"{start.strftime('%b %-d')} - {end.strftime('%b %-d')}"
        except ValueError:
            return date_str

    @classmethod
    def _dasha_permission_note(cls, maha_lord: str, antar_lord: str) -> str:
        if not maha_lord:
            return ""
        parts = [f"{maha_lord} Mahadasha gives the karmic mandate"]
        if antar_lord and antar_lord != maha_lord:
            parts.append(f"{antar_lord} Antardasha governs tactical execution")
        return " -- ".join(parts) + "."

    @classmethod
    def _theme_guidance_fallback(
        cls, tp: str, np_: str, aspect: str, cls_: str,
        window: str, cond: str, dasha_str: str,
    ) -> Tuple[str, str]:
        """Fallback concrete guidance when no exact trigger match exists
        in the master guidance table."""
        do_map: Dict[str, str] = {
            "capital": (
                f"{tp} ({cond}) activates capital structure {window}. "
                f"Close outstanding terms with decision-makers. "
                f"Push paid deployment or revenue milestone before the window closes. "
                f"Deploy resources toward long-lived assets, not consumption. "
                f"Sign after the exact aspect date."
            ),
            "career": (
                f"{tp} ({cond}) triggers career/visibility shift {window}. "
                f"Publish, present, or pitch during this window -- your profile work "
                f"compounds. Update positioning. Ask for the title, the role, "
                f"the board seat. Dasha permission ({dasha_str}) backs "
                f"structural career moves."
            ),
            "relationship": (
                f"{tp} ({cond}) activates relationship dynamics {window}. "
                f"Initiate the tough conversation. Formalize the partnership terms. "
                f"Resolve lingering tension with a direct ask. "
                f"The transit gives leverage -- use it before the window closes."
            ),
            "relocation": (
                f"{tp} ({cond}) signals relocation pressure {window}. "
                f"Scout target geography. Book the trip, sign the lease, "
                f"or submit the visa application during this window. "
                f"Do not decide from a distance -- go there."
            ),
            "health": (
                f"{tp} ({cond}) highlights health and routines {window}. "
                f"Schedule the overdue check-up. Start or adjust exercise/diet protocol. "
                f"Sleep and recovery are strategic inputs, not downtime."
            ),
            "spiritual": (
                f"{tp} ({cond}) deepens spiritual inquiry {window}. "
                f"Start the practice you have been deferring -- meditation, "
                f"journaling, retreat. Study a text or teacher. "
                f"Let insight accumulate; act after the window closes."
            ),
        }
        avoid_map: Dict[str, str] = {
            "capital": (
                f"Avoid speculative bets and leveraged positions during "
                f"{tp} {aspect} {np_}. Don't commit capital before the exact date. "
                f"Don't chase velocity over structure."
            ),
            "career": (
                f"Avoid burning bridges -- {tp} {aspect} {np_} amplifies consequences. "
                f"Don't resign impulsively or issue ultimatums during the window."
            ),
            "relationship": (
                f"Avoid ultimatums and permanent break decisions during the "
                f"{window} window. Let the transit energy settle before finalizing."
            ),
            "relocation": (
                f"Don't commit to a location you haven't visited. "
                f"{tp} {aspect} {np_} amplifies impulsivity around place -- scout first."
            ),
            "health": (
                f"Don't ignore subtle body signals during {tp} {aspect} {np_}. "
                f"Overexertion compounds with delay -- rest before you're forced to."
            ),
            "spiritual": (
                f"Don't isolate completely. {tp} {aspect} {np_} can pull toward "
                f"withdrawal -- stay connected to at least one trusted sounding board."
            ),
        }
        return (
            do_map.get(cls_, do_map["spiritual"]),
            avoid_map.get(cls_, avoid_map["spiritual"]),
        )

    def _build_dasha_only_guidance(
        self, maha_lord: str, antar_lord: str,
    ) -> Tuple[str, str]:
        """Build concrete guidance for months without transit triggers.

        Grounded in what the dasha lords permit -- not generic fluff.
        """
        do_specifics: Dict[str, str] = {
            "Jupiter": (
                "Build teaching/curriculum assets. Expand your network through "
                "generous introductions. Write the long-form piece."
            ),
            "Saturn": (
                "Audit systems and processes. Shore up operational gaps. "
                "Document protocols. Build the thing that will outlast you."
            ),
            "Mercury": (
                "Write, pitch, and publish. Run the A/B test. Ship the integration. "
                "Every communication is a deposit."
            ),
            "Venus": (
                "Strengthen key relationships. Negotiate terms. Refine the product "
                "aesthetic. Invest in team culture."
            ),
            "Mars": (
                "Execute on the backlog. Ship the feature. Run the sprint. "
                "Physical discipline compounds -- train, don't just plan."
            ),
            "Sun": (
                "Be visible. Post, speak, present. Claim your authority in your "
                "domain. Visibility is the strategy this month."
            ),
            "Moon": (
                "Tend to team morale and personal relationships. "
                "Emotional infrastructure is real infrastructure."
            ),
            "Rahu": (
                "Experiment with unconventional approaches. Launch the moonshot "
                "project. Network outside your sector -- cross-pollination pays."
            ),
            "Ketu": (
                "Cut what isn't working. Simplify the product, the team, the "
                "calendar. Subtraction is the strategy."
            ),
        }
        avoid_specifics: Dict[str, str] = {
            "Jupiter": "Don't overcommit. Expansion without structure creates chaos.",
            "Saturn": (
                "Don't rigidity yourself into irrelevance. Discipline without "
                "adaptation is brittle."
            ),
            "Mercury": (
                "Don't scatter. Pick one channel or message per audience and stay on it."
            ),
            "Venus": (
                "Don't people-please. Harmony without boundaries breeds resentment."
            ),
            "Mars": "Don't burn out your team. Speed without recovery produces injury.",
            "Sun": (
                "Don't confuse visibility with value. Presence without substance backfires."
            ),
            "Moon": (
                "Don't absorb everyone's emotions. Empathy without boundaries is self-harm."
            ),
            "Rahu": (
                "Don't chase every disruption. Novelty without conviction wastes momentum."
            ),
            "Ketu": (
                "Don't detach so far you disengage. Cutting must leave something standing."
            ),
        }

        do_sentence = do_specifics.get(antar_lord) or do_specifics.get(maha_lord) or (
            f"Build foundational infrastructure under {maha_lord or 'ongoing'} energy. "
            f"Ship the thing you have been deferring."
        )
        avoid_sentence = avoid_specifics.get(
            antar_lord
        ) or avoid_specifics.get(maha_lord) or (
            f"Avoid major directional changes without transit support. "
            f"Consolidation months are for building, not pivoting."
        )

        if maha_lord and antar_lord and maha_lord != antar_lord:
            do_sentence += (
                f" {maha_lord} Mahadasha gives the long arc; "
                f"{antar_lord} Antardasha governs the monthly tactics."
            )

        return do_sentence, avoid_sentence

    # ------------------------------------------------------------------
    # Method 3: apply_bayesian_priors
    # ------------------------------------------------------------------

    def apply_bayesian_priors(
        self,
        monthly_hypotheses: List[Dict[str, Any]],
        user_priors: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        """Adjust probability bands using real-world user context.

        Maps user priors (projects, career_target, location, current_focus)
        to astrological themes and boosts hypotheses whose themes align.

        Args:
            monthly_hypotheses: Output from generate_monthly_hypotheses.
            user_priors: Dict with optional keys projects, career_target,
                         location, current_focus.

        Returns:
            Updated monthly hypotheses with prior_context, prior_alignment_score,
            and adjusted probability_band values.
        """
        projects = self._normalize_prior_projects(user_priors.get("projects") or [])
        career_target = user_priors.get("career_target", "")
        location = user_priors.get("location", "")
        current_focus = user_priors.get("current_focus", "")

        domain_theme_map: Dict[str, str] = {
            "capital": "capital", "fundraising": "capital",
            "finance": "capital", "revenue": "capital", "sales": "capital",
            "career": "career", "job": "career", "promotion": "career",
            "leadership": "career",
            "relationship": "relationship", "partnership": "relationship",
            "dating": "relationship", "marriage": "relationship",
            "relocation": "relocation", "moving": "relocation",
            "travel": "relocation",
            "health": "health", "wellness": "health", "fitness": "health",
            "spiritual": "spiritual", "meditation": "spiritual",
            "retreat": "spiritual", "growth": "spiritual",
        }

        prior_themes: Dict[str, float] = {}
        for proj in projects:
            domain = (proj.get("domain") or "").lower()
            stage = (proj.get("stage") or "").lower()
            theme = domain_theme_map.get(domain)
            if theme:
                weight = 0.8 if stage in ("active", "launch", "scaling", "growth") else 0.5
                prior_themes[theme] = max(prior_themes.get(theme, 0.0), weight)

        if career_target:
            prior_themes["career"] = max(prior_themes.get("career", 0.0), 0.7)
        if location:
            prior_themes["relocation"] = max(prior_themes.get("relocation", 0.0), 0.6)
        if current_focus:
            focus_lower = current_focus.lower()
            matched = domain_theme_map.get(focus_lower)
            if matched:
                prior_themes[matched] = max(prior_themes.get(matched, 0.0), 0.9)
            else:
                for kw in set(domain_theme_map.values()):
                    if kw in focus_lower:
                        prior_themes[kw] = max(prior_themes.get(kw, 0.0), 0.7)

        updated: List[Dict[str, Any]] = []
        for h in monthly_hypotheses:
            primary = h["primary_theme"]
            secondary = h["secondary_theme"]
            alignment_score = prior_themes.get(primary, 0.0) * 0.7
            alignment_score += prior_themes.get(secondary, 0.0) * 0.3

            current_band = h["probability_band"]
            band_idx = PROBABILITY_BANDS.index(current_band)

            if alignment_score > 0.7:
                boost = 2
            elif alignment_score > 0.3:
                boost = 1
            else:
                boost = 0

            new_idx = min(band_idx + boost, len(PROBABILITY_BANDS) - 1)
            adjusted_band = PROBABILITY_BANDS[new_idx]

            context_parts: List[str] = []
            for proj in projects:
                context_parts.append(
                    f"Project '{proj.get('name', 'unnamed')}' "
                    f"[{proj.get('domain', 'unknown')}, {proj.get('stage', 'unknown')}]"
                )
            if career_target:
                context_parts.append(f"Career target: {career_target}")
            if location:
                context_parts.append(f"Location intent: {location}")
            if current_focus:
                context_parts.append(f"Focus: {current_focus}")

            updated_h = dict(h)
            updated_h["probability_band"] = adjusted_band
            updated_h["prior_alignment_score"] = round(alignment_score, 3)
            updated_h["prior_context"] = (
                "; ".join(context_parts) if context_parts
                else "No user priors provided."
            )
            if boost > 0:
                updated_h["prior_adjustment"] = (
                    f"Boosted from {current_band} -> {adjusted_band} "
                    f"(alignment={alignment_score:.2f})"
                )
            updated.append(updated_h)

        logger.info(
            "Applied Bayesian priors to %d hypotheses (%d themes matched)",
            len(updated), len(prior_themes),
        )
        return updated

    def _normalize_prior_projects(self, projects: Any) -> List[Dict[str, str]]:
        """Accept both Swift client project strings and structured project dicts."""
        if not isinstance(projects, list):
            return []

        normalized: List[Dict[str, str]] = []
        for project in projects:
            if isinstance(project, dict):
                normalized.append({
                    "name": str(project.get("name") or "unnamed"),
                    "domain": str(project.get("domain") or ""),
                    "stage": str(project.get("stage") or ""),
                })
            elif isinstance(project, str):
                normalized.append({
                    "name": project,
                    "domain": project,
                    "stage": "active",
                })
        return normalized

    # ------------------------------------------------------------------
    # Method 4: full_prediction_report
    # ------------------------------------------------------------------

    def full_prediction_report(
        self,
        birth_data: Dict[str, Any],
        dasha_state: Dict[str, Any],
        start_date: str,
        end_date: str,
        user_priors: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Produce a complete prediction report combining all methods.

        Args:
            birth_data: Dict with date, time, timezone, latitude, longitude.
            dasha_state: Current dasha period information.
            start_date: ISO date string for window start.
            end_date: ISO date string for window end.
            user_priors: Optional real-world context.

        Returns:
            Dict with triggers, monthly_timeline, summary, peak_windows,
            geographic_hint, metadata.
        """
        triggers = self.compute_transit_triggers(birth_data, start_date, end_date)
        hypotheses = self.generate_monthly_hypotheses(
            triggers, dasha_state, start_date, end_date,
        )
        if user_priors:
            hypotheses = self.apply_bayesian_priors(hypotheses, user_priors)

        summary = self._build_summary(triggers, hypotheses, dasha_state, user_priors)
        peak_windows = self._build_peak_windows(hypotheses)
        geographic_hint = self._geographic_hint(triggers, dasha_state)

        report: Dict[str, Any] = {
            "triggers": triggers,
            "monthly_timeline": hypotheses,
            "summary": summary,
            "peak_windows": peak_windows,
            "geographic_hint": geographic_hint,
            "metadata": {
                "start_date": start_date,
                "end_date": end_date,
                "trigger_count": len(triggers),
                "months_covered": len(hypotheses),
                "has_user_priors": user_priors is not None,
            },
        }
        logger.info(
            "Full prediction report: %d triggers, %d months, %d peak windows",
            len(triggers), len(hypotheses), len(peak_windows),
        )
        return report

    # ------------------------------------------------------------------
    # Internal: summary, peaks, geography
    # ------------------------------------------------------------------

    def _build_summary(
        self,
        triggers: List[Dict[str, Any]],
        hypotheses: List[Dict[str, Any]],
        dasha_state: Dict[str, Any],
        user_priors: Optional[Dict[str, Any]],
    ) -> str:
        """Build a one-paragraph synthesis of the prediction period."""
        maha_lord = (
            dasha_state.get("mahadasha", {}).get("lord", "the current Mahadasha")
            if isinstance(dasha_state.get("mahadasha"), dict)
            else "the current Mahadasha"
        )
        antar_lord = (
            dasha_state.get("antardasha", {}).get("lord", "")
            if isinstance(dasha_state.get("antardasha"), dict) else ""
        )

        theme_counts: Dict[str, int] = {}
        for t in triggers:
            theme_counts[t["event_class"]] = theme_counts.get(t["event_class"], 0) + 1
        top_themes = sorted(theme_counts.items(), key=lambda x: -x[1])[:3]
        theme_str = (
            ", ".join(f"{th} ({c}x)" for th, c in top_themes)
            if top_themes else "general integration"
        )

        trigger_months: Dict[str, int] = {}
        for t in triggers:
            mk = _month_key(_parse_iso_date(t["date"]))
            trigger_months[mk] = trigger_months.get(mk, 0) + 1
        peak_entry = max(trigger_months.items(), key=lambda x: x[1]) if trigger_months else (None, 0)

        high_months = [
            h for h in hypotheses
            if h["probability_band"] in ("high", "medium-high")
        ]

        summary = (
            f"Under {maha_lord} Mahadasha"
            + (f" / {antar_lord} Antardasha" if antar_lord else "")
            + f", {len(triggers)} transit triggers activate across "
            f"{len(hypotheses)} months. "
            f"Dominant themes: {theme_str}. "
        )
        if peak_entry[0]:
            summary += (
                f"Peak activity clusters around {peak_entry[0]} "
                f"({peak_entry[1]} triggers). "
            )
        if high_months:
            summary += (
                f"{len(high_months)} month(s) carry high or medium-high probability. "
            )
        if user_priors:
            projs = self._normalize_prior_projects(user_priors.get("projects") or [])
            if projs:
                names = ", ".join(p.get("name", "?") for p in projs[:3])
                summary += f"User context ({names}) aligned with forecast themes. "
        summary += (
            "Align key actions with exact transit dates; use the month before "
            "a major conjunction for preparation and the month after for integration."
        )
        return summary

    def _build_peak_windows(
        self, hypotheses: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """Identify consecutive runs of high-probability months."""
        windows: List[Dict[str, Any]] = []
        in_window = False
        window_months: List[str] = []

        for h in hypotheses:
            is_peak = h["probability_band"] in ("high", "medium-high")
            if is_peak:
                if not in_window:
                    in_window = True
                window_months.append(h["month"])
            else:
                if in_window and window_months:
                    windows.append(self._make_window(window_months, hypotheses))
                    window_months = []
                in_window = False

        if in_window and window_months:
            windows.append(self._make_window(window_months, hypotheses))

        if not windows and hypotheses:
            best = max(
                hypotheses,
                key=lambda h: PROBABILITY_BANDS.index(h["probability_band"]),
            )
            windows.append({
                "date_range": best["month"],
                "theme": best["primary_theme"],
                "probability": best["probability_band"],
            })
        return windows

    def _make_window(
        self, months: List[str], hypotheses: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """Build a peak-window dict from a list of month keys."""
        start_m = months[0]
        end_m = months[-1]
        end_dt = _first_of_month(end_m)
        last_day = monthrange(end_dt.year, end_dt.month)[1]
        end_str = f"{end_m}-{last_day:02d}"

        theme_counts: Dict[str, int] = {}
        for h in hypotheses:
            if h["month"] in months:
                theme_counts[h["primary_theme"]] = (
                    theme_counts.get(h["primary_theme"], 0) + 1
                )
        theme = (
            max(theme_counts.items(), key=lambda x: x[1])[0]
            if theme_counts else "spiritual"
        )

        best_band = "medium"
        for h in hypotheses:
            if h["month"] in months:
                if PROBABILITY_BANDS.index(h["probability_band"]) > PROBABILITY_BANDS.index(best_band):
                    best_band = h["probability_band"]

        return {
            "date_range": f"{start_m}-01 to {end_str}",
            "theme": theme,
            "probability": best_band,
            "months": months,
        }

    def _geographic_hint(
        self,
        triggers: List[Dict[str, Any]],
        dasha_state: Dict[str, Any],
    ) -> str:
        """Derive a geographic hint from the transit and dasha pattern."""
        direction_map: Dict[str, str] = {
            "Sun": "East", "Moon": "Northwest", "Mars": "South",
            "Mercury": "North", "Jupiter": "Northeast", "Venus": "Southeast",
            "Saturn": "West", "Rahu": "Southwest",
            "Ketu": "spiritual -- any direction inward",
        }
        maha_lord = (
            dasha_state.get("mahadasha", {}).get("lord", "")
            if isinstance(dasha_state.get("mahadasha"), dict) else ""
        )
        transiting_set: set = set(t["transiting_planet"] for t in triggers)

        primary_planet = maha_lord or (
            list(transiting_set)[0] if transiting_set else ""
        )
        if "Jupiter" in transiting_set:
            primary_planet = "Jupiter"
        if "Rahu" in transiting_set and len(triggers) >= 3:
            primary_planet = "Rahu"

        direction = direction_map.get(primary_planet, "your current base")
        if primary_planet:
            return (
                f"Best action geography: {direction} (aligned with {primary_planet}). "
                f"Favourable directional moves compound transit and dasha effects."
            )
        return (
            "Best action geography: your current base. "
            "No strong directional pull detected."
        )


# ===================================================================
# Master trigger-guidance table (module-level constant)
# ===================================================================
# Maps (transiting_planet, natal_planet, aspect_type, event_class) ->
# (do_template, avoid_template).  Templates receive .format(tp=, np=,
# cond=, natal_cond=, dasha=, window=, house=, maha=, antar=).
# Referenced at runtime from _guidance_for_trigger.

_TRIGGER_GUIDANCE: Dict[Tuple[str, str, str, str], Tuple[str, str]] = {

    # -- Jupiter aspects natal Mars (capital/product activation) --
    ("Jupiter", "Mars", "conjunction", "capital"): (
        "{tp} conjunct natal {np} {window}: Capital/product execution peak. "
        "Close the enterprise PoC with decision-maker access. Push for paid "
        "deployment before {window} closes. {cond} {tp} gives execution power; "
        "use it to convert pipeline into revenue. Ship the feature, sign the "
        "term sheet, launch the paid tier. Under {dasha}, the karmic wind is "
        "at your back -- don't negotiate against yourself.",
        "Don't spread capital across experiments. {tp} conjunction {np} demands "
        "focused execution, not exploration. Avoid speculative hires or untested "
        "channels during the {window} window. The energy is for closing, not opening.",
    ),
    ("Jupiter", "Mars", "trine", "capital"): (
        "{tp} trine natal {np} {window}: Capital/product momentum window. "
        "The flow state is open -- deploy resources where you already have "
        "traction. Expand successful channels; double down on what is already "
        "converting. {cond} {tp} trine means effort multiplies -- a 10-hour "
        "week compounds like a 30-hour week. Use it for the hard push.",
        "Don't start new initiatives from scratch. {tp} trine {np} rewards "
        "amplification of existing momentum, not fresh builds. Avoid greenfield "
        "projects during {window}.",
    ),
    ("Jupiter", "Mars", "square", "capital"): (
        "{tp} square natal {np} {window}: Capital/product tension demands "
        "resolution. The friction between growth ambition and execution capacity "
        "is the signal -- address the bottleneck directly. Restructure the pricing "
        "model, renegotiate the cap table term, or cut the feature dragging "
        "velocity. {cond} {tp} square {np} means the obstacle IS the growth lever.",
        "Don't paper over execution gaps with more capital. {tp} square {np} "
        "exposes structural weaknesses -- adding resources before fixing the "
        "structure compounds the problem. No bandaids during {window}.",
    ),
    ("Jupiter", "Mars", "opposition", "capital"): (
        "{tp} opposition natal {np} {window}: External capital pressure meets "
        "internal execution capacity. A partner, investor, or competitor forces "
        "the conversation -- be ready with your numbers. Use the external pressure "
        "to justify internal change. {cond} {tp} opposed means the push comes from "
        "outside; your job is to channel it, not resist it.",
        "Don't let external pressure force premature commitments. {tp} opposition "
        "{np} creates urgency that is partially real, partially perceived. "
        "Negotiate terms, don't accept ultimatums during {window}.",
    ),

    # -- Jupiter conjunct natal Venus (network/revenue peak) --
    ("Jupiter", "Venus", "conjunction", "capital"): (
        "{tp} conjunct natal {np} {window}: Network/revenue peak. "
        "Your network unlocks capital this month -- reach out to the five people "
        "who can change your trajectory. Host the dinner, send the proposal, "
        "make the ask. {cond} {tp} expands {np}'s domain; revenue conversations "
        "that start now close larger than expected.",
        "Don't confuse social warmth with deal momentum. {tp} conjunction {np} "
        "makes everyone feel like a yes -- wait for signed terms. Avoid "
        "over-indexing on relationship at the expense of structure.",
    ),
    ("Jupiter", "Venus", "trine", "capital"): (
        "{tp} trine natal {np} {window}: Revenue/network flow opens. "
        "Partnerships and referrals compound. Attend the event, join the community, "
        "say yes to introductions. {cond} {tp} trine {np} means network effects "
        "work in your favour -- the person you meet this month closes a deal in three.",
        "Don't transact too early. {tp} trine {np} is for relationship-building, "
        "not hard closes. Avoid pushing for commitment during the first half of {window}.",
    ),

    # -- Jupiter return (12-year cycle) --
    ("Jupiter", "Jupiter", "conjunction", "spiritual"): (
        "{tp} return ({window}): 12-year cycle reset. Review the last decade's "
        "growth pattern. What worked? Double down. What didn't? Cut it. "
        "Set the intention for the next 12-year arc -- the decisions you make "
        "during a Jupiter return have compound duration. Under {dasha}, "
        "this reset carries extra weight.",
        "Don't chase every opportunity that appears during the {window} window. "
        "Jupiter return opens doors but doesn't tell you which ones to walk "
        "through. Avoid commitment to long-term contracts before the exact date passes.",
    ),

    # -- Saturn conjunct natal Jupiter (vision compression) --
    ("Saturn", "Jupiter", "conjunction", "career"): (
        "{tp} conjunct natal {np} {window}: Vision compression. "
        "The big-picture thinker meets structural reality. Audit your current "
        "trajectory against actual results -- not aspirations. Cut the projects "
        "that survived on optimism alone. {cond} {tp} rewards honest accounting: "
        "what is the smallest version of your vision that ships this quarter? "
        "Build that. The {dasha} transit demands substance over story.",
        "Don't abandon the vision entirely. {tp} conjunction {np} creates "
        "pessimism that is as distorting as the prior optimism. Avoid killing "
        "projects during the {window} window -- freeze them, re-scope them, "
        "but don't delete. The clarity is real; the despair is temporary.",
    ),
    ("Saturn", "Jupiter", "opposition", "career"): (
        "{tp} opposition natal {np} {window}: Career structure versus growth "
        "mandate collide. External constraints (budget, board, market) press "
        "against your expansion plans. Use the friction to strengthen the plan, "
        "not abandon it. {cond} {tp} opposed to {np} means discipline is being "
        "tested -- hold the frame. Under {dasha}, structural integrity wins.",
        "Don't overleverage to force growth through a Saturn opposition window. "
        "The compression is real; fighting it burns capital and credibility. "
        "Avoid major hires or debt during {window}.",
    ),

    # -- Rahu conjunct natal Sun (visibility/authority spike) --
    ("Rahu", "Sun", "conjunction", "career"): (
        "{tp} conjunct natal {np} {window}: Visibility/authority spike. "
        "You will be seen -- control what they see. Publish, present, post. "
        "The algorithm, the room, the board -- all amplify you this month. "
        "{cond} {tp} on {np} can make or break a reputation. Prepare your "
        "positioning in advance; the window amplifies whatever you put into it. "
        "Under {dasha}, this spike compounds with the career arc.",
        "Don't chase visibility without substance. {tp} conjunction {np} "
        "amplifies everything including errors. Avoid making claims you cannot "
        "substantiate. The spotlight during {window} is real -- and it burns.",
    ),
    ("Rahu", "Sun", "opposition", "career"): (
        "{tp} opposition natal {np} {window}: Others challenge your authority. "
        "A competitor, critic, or institutional force puts your positioning "
        "under pressure. Don't defend -- demonstrate. Ship the evidence. "
        "{cond} {tp} opposed to {np} means the challenge is external; "
        "your response should be visible and undeniable.",
        "Don't get drawn into public conflict. {tp} opposition {np} feeds on "
        "reaction. Avoid responding to critics in real-time during {window} -- "
        "let your work speak, not your replies.",
    ),

    # -- Ketu conjunct natal Moon (emotional/relationship reset) --
    ("Ketu", "Moon", "conjunction", "relationship"): (
        "{tp} conjunct natal {np} {window}: Emotional/relationship reset. "
        "Patterns that stopped serving you become visible. End the relationship "
        "that drains, restructure the one that matters, or formalize what has "
        "been informal too long. {cond} {tp} strips away what is not real; "
        "what survives the {window} window is what belongs. "
        "Under {dasha}, this reset carries finality.",
        "Don't make permanent decisions from transient emotion. {tp} conjunction "
        "{np} amplifies every feeling -- wait 48 hours after the exact date before "
        "sending the message or signing the separation. Avoid dramatic exits "
        "during {window}.",
    ),
    ("Ketu", "Moon", "opposition", "relationship"): (
        "{tp} opposition natal {np} {window}: External relationship pressure "
        "forces internal clarity. A partner, family member, or situation holds "
        "up a mirror. What you see may be uncomfortable -- sit with it before "
        "acting. {cond} {tp} opposed to receptive {np} means the insight comes "
        "through others, not introspection.",
        "Don't project the discomfort onto others. {tp} opposition {np} makes "
        "it easy to blame the messenger. Avoid confrontation during {window} -- "
        "the signal is for you, not them.",
    ),

    # -- Rahu/Ketu nodal returns (18-year karmic resets) --
    ("Rahu", "Rahu", "conjunction", "spiritual"): (
        "{tp} nodal return ({window}): 18-year karmic reset. The direction you "
        "set now compounds for nearly two decades. Audit your ambition: is it "
        "yours, or inherited? Cut the goals that belong to someone else. "
        "{cond} {tp} return demands authenticity -- the world rewards the real "
        "version, not the performed one.",
        "Don't mistake intensity for direction. {tp} nodal return amplifies "
        "desire without clarifying which desires are yours. Avoid major life "
        "decisions during {window} without sitting with them for at least a week.",
    ),
    ("Ketu", "Ketu", "conjunction", "spiritual"): (
        "{tp} nodal return ({window}): 18-year release point. What are you "
        "still carrying that you outgrew years ago? Relationships, identities, "
        "obligations -- if it doesn't survive the {window} window, let it go. "
        "{cond} {tp} return is the cleanest cut you will get.",
        "Don't cut everything. {tp} nodal return creates a purity impulse that "
        "can become destructive. Avoid quitting the job, the relationship, or "
        "the project simultaneously during {window}. Pace the release.",
    ),

    # -- Saturn return (~29-year structural reset) --
    ("Saturn", "Saturn", "conjunction", "career"): (
        "{tp} return ({window}): ~29-year structural reset. The foundation you "
        "built in your late 20s is up for review. What held? What cracked? "
        "Rebuild the cracked parts now -- the next Saturn cycle depends on it. "
        "Under {dasha}, this return is the most consequential career checkpoint "
        "of the decade. Ship the evidence of mastery.",
        "Don't resist the audit. {tp} return exposes what you have been avoiding. "
        "Avoid defending broken structures during {window} -- rebuild them instead. "
        "The pain of the audit is less than the cost of continuing with a cracked "
        "foundation.",
    ),

    # -- Jupiter conjunction Sun (authority expansion) --
    ("Jupiter", "Sun", "conjunction", "spiritual"): (
        "{tp} conjunct natal {np} {window}: Authority and visibility expand. "
        "Your domain expertise is being noticed -- publish the definitive piece, "
        "give the talk, launch the course. {cond} {tp} on authoritative {np} "
        "means what you put out this month defines your positioning for the year. "
        "Under {dasha}, this is a leadership activation window.",
        "Don't let expansion become inflation. {tp} conjunction {np} can tip "
        "from confidence into arrogance. Avoid overpromising during {window} -- "
        "what you claim now you must deliver later.",
    ),
    ("Jupiter", "Sun", "trine", "spiritual"): (
        "{tp} trine natal {np} {window}: Effortless authority. "
        "People defer to you without you asking. Use the natural leadership "
        "posture to advance stalled initiatives. {cond} {tp} trine {np} means "
        "the room gives you the floor -- take it.",
        "Don't coast on deference. {tp} trine {np} makes it easy to accept "
        "unearned authority. Avoid letting others do the work of positioning "
        "you during {window}.",
    ),

    # -- Ketu conjunction Sun (identity dissolution) --
    ("Ketu", "Sun", "conjunction", "spiritual"): (
        "{tp} conjunct natal {np} {window}: Identity dissolution. "
        "The story you tell about yourself is under review. Who are you without "
        "the title, the company, the role? {cond} {tp} strips ego -- let it. "
        "The identity that survives the {window} window is the real one. "
        "Under {dasha}, this clarity resets your trajectory.",
        "Don't cling to outdated self-concepts. {tp} conjunction {np} makes "
        "ego-defensiveness painful and counterproductive. Avoid doubling down "
        "on a persona that no longer fits during {window}.",
    ),

    # -- Rahu opposition Moon (emotional volatility / relationship turbulence) --
    ("Rahu", "Moon", "opposition", "relationship"): (
        "{tp} opposition natal {np} {window}: Emotional amplification meets "
        "relationship pressure. Someone or something triggers a disproportionate "
        "reaction -- the signal is in the overreaction, not the trigger. "
        "Name the pattern you are repeating. {cond} {tp} opposed to receptive "
        "{np} makes emotions feel like facts; verify before acting.",
        "Don't send the message you write at 2am. {tp} opposition {np} distorts "
        "emotional intensity -- what feels urgent during {window} is rarely "
        "as critical as it seems. Avoid confrontation while the aspect is exact.",
    ),

    # -- Saturn opposition Mercury (communication/career friction) --
    ("Saturn", "Mercury", "opposition", "career"): (
        "{tp} opposition natal {np} {window}: Communication meets structural "
        "resistance. Proposals, pitches, and negotiations face scrutiny -- prepare "
        "for harder questions than expected. {cond} {tp} opposed to analytical "
        "{np} means your ideas are being stress-tested, not rejected. "
        "Answer the hard questions; they make the work stronger.",
        "Don't withdraw from communication under pressure. {tp} opposition {np} "
        "can make you second-guess every word -- the avoidance is costlier than "
        "the imperfect articulation. Don't go silent during {window}.",
    ),
}
