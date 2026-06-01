"""
Rajayoga Detection, Constraint Analysis, and Archetype Labeling Service.

Detects Vedic astrology Rajayoga patterns from planet positions and ascendant,
evaluates planetary optimization status, extracts chart-specific constraints,
and synthesises archetype labels with full narrative reports.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# Sign registry (Western canonical names with Vedic aliases)
# ---------------------------------------------------------------------------
ZODIAC_SIGNS: List[str] = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

_SIGN_ALIASES: Dict[str, str] = {
    # Western
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

# ---------------------------------------------------------------------------
# Dignity tables (sign + exact degree)
# ---------------------------------------------------------------------------
EXALTATION: Dict[str, Tuple[str, float]] = {
    "Sun": ("Aries", 10.0),
    "Moon": ("Taurus", 3.0),
    "Mars": ("Capricorn", 28.0),
    "Mercury": ("Virgo", 15.0),
    "Jupiter": ("Cancer", 5.0),
    "Venus": ("Pisces", 27.0),
    "Saturn": ("Libra", 20.0),
}

DEBILITATION: Dict[str, Tuple[str, float]] = {
    "Sun": ("Libra", 10.0),
    "Moon": ("Scorpio", 3.0),
    "Mars": ("Cancer", 28.0),
    "Mercury": ("Pisces", 15.0),
    "Jupiter": ("Capricorn", 5.0),
    "Venus": ("Virgo", 27.0),
    "Saturn": ("Aries", 20.0),
}

OWN_SIGNS: Dict[str, Set[str]] = {
    "Sun": {"Leo"},
    "Moon": {"Cancer"},
    "Mars": {"Aries", "Scorpio"},
    "Mercury": {"Gemini", "Virgo"},
    "Jupiter": {"Sagittarius", "Pisces"},
    "Venus": {"Taurus", "Libra"},
    "Saturn": {"Capricorn", "Aquarius"},
}

# Planet -> ruler (used for sign-to-planet lookup)
_SIGN_RULER: Dict[str, str] = {
    "Aries": "Mars", "Taurus": "Venus", "Gemini": "Mercury",
    "Cancer": "Moon", "Leo": "Sun", "Virgo": "Mercury",
    "Libra": "Venus", "Scorpio": "Mars", "Sagittarius": "Jupiter",
    "Capricorn": "Saturn", "Aquarius": "Saturn", "Pisces": "Jupiter",
}

# ---------------------------------------------------------------------------
# House sets
# ---------------------------------------------------------------------------
_KENDRA_HOUSES: Set[int] = {1, 4, 7, 10}
_TRIKONA_HOUSES: Set[int] = {1, 5, 9}
_DUSTHANA_HOUSES: Set[int] = {6, 8, 12}
_BENEFIC_PLANETS: Set[str] = {"Jupiter", "Venus", "Mercury", "Moon"}
_MALEFIC_PLANETS: Set[str] = {"Sun", "Mars", "Saturn", "Rahu", "Ketu"}

# Aspect offsets (Vedic graha drishti): (planet_house + offset) % 12 = aspected_house
_ASPECT_OFFSETS: Dict[str, Set[int]] = {
    "Sun": {6},
    "Moon": {6},
    "Mercury": {6},
    "Venus": {6},
    "Mars": {3, 6, 7},       # 4th, 7th, 8th
    "Jupiter": {4, 6, 8},    # 5th, 7th, 9th
    "Saturn": {2, 6, 9},     # 3rd, 7th, 10th
    "Rahu": {4, 6, 8},       # Treated like Jupiter in some classics
    "Ketu": {4, 6, 8},
}

# Directional strength (Digbala) houses
_DIGBALA_HOUSES: Dict[str, int] = {
    "Sun": 10, "Mars": 10,          # South (MC)
    "Moon": 4, "Venus": 4,          # North (IC)
    "Mercury": 1, "Jupiter": 1,     # East (Ascendant)
    "Saturn": 7,                    # West (Descendant)
}

# Ascendant element mapping
_LAGNA_ELEMENT: Dict[str, str] = {
    "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
    "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
    "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
    "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water",
}

# ---------------------------------------------------------------------------
# Archetype definitions
# ---------------------------------------------------------------------------
_ARCHETYPES: List[Dict[str, Any]] = [
    {
        "label": "Sovereign Creator",
        "keywords": ["lagna_lord_5th", "sun_strong", "fire_lagna", "jupiter_lagna"],
    },
    {
        "label": "Capital Engineer",
        "keywords": ["mars_exalted_2nd", "earth_lagna", "saturn_strong", "2nd_emphasis"],
    },
    {
        "label": "Network Architect",
        "keywords": ["venus_11th_own", "air_lagna", "11th_emphasis", "mercury_strong"],
    },
    {
        "label": "Hidden Systems Builder",
        "keywords": ["12th_emphasis", "ketu_strong", "debilitated_10th_lord", "water_lagna"],
    },
    {
        "label": "Constraint-First Architect",
        "keywords": ["saturn_lagna", "multiple_debilitated", "dusthana_emphasis", "saturn_aspect_lagna"],
    },
    {
        "label": "Platform Monetizer",
        "keywords": ["5th_11th_loop", "venus_strong", "2nd_11th_link", "jupiter_11th"],
    },
    {
        "label": "Research Oracle",
        "keywords": ["mercury_exalted", "8th_emphasis", "jupiter_exalted", "ketu_5th"],
    },
    {
        "label": "Industrial Executor",
        "keywords": ["mars_strong", "10th_emphasis", "sun_10th", "saturn_10th"],
    },
    {
        "label": "Diplomatic Strategist",
        "keywords": ["venus_strong", "7th_emphasis", "mercury_jupiter_link", "libra_lagna"],
    },
]


class RajayogaService:
    """Detect Rajayoga patterns, constraints, and archetypes from a natal chart."""

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _normalize_sign_name(sign: str) -> str:
        """Return the canonical Western sign name regardless of input casing or Vedic alias."""
        value = (sign or "").strip()
        if not value:
            return "Aries"
        return _SIGN_ALIASES.get(value.lower(), value[:1].upper() + value[1:].lower())

    @staticmethod
    def _sign_index(sign: str) -> int:
        """Return 0-based zodiac index (Aries=0 ... Pisces=11)."""
        return ZODIAC_SIGNS.index(RajayogaService._normalize_sign_name(sign))

    @staticmethod
    def _house_lords(lagna_sign: str) -> Dict[int, str]:
        """Compute the ruling planet for each house (1-12) given the ascendant sign."""
        lagna_idx = RajayogaService._sign_index(lagna_sign)
        lords: Dict[int, str] = {}
        for h in range(1, 13):
            sign = ZODIAC_SIGNS[(lagna_idx + h - 1) % 12]
            lords[h] = _SIGN_RULER[sign]
        return lords

    @staticmethod
    def _aspects_house(planet_name: str, planet_house: int, target_house: int) -> bool:
        """Return True if *planet_name* in *planet_house* aspects *target_house* (1-indexed)."""
        offsets = _ASPECT_OFFSETS.get(planet_name, {6})
        for offset in offsets:
            if ((planet_house - 1 + offset) % 12) + 1 == target_house:
                return True
        return False

    @staticmethod
    def _find_planet_house(planet_data: Dict[str, Dict], planet_name: str) -> Optional[int]:
        """Return the house number where *planet_name* sits, or None if missing."""
        info = planet_data.get(planet_name)
        if isinstance(info, dict) and "house" in info:
            return info["house"]
        return None

    @staticmethod
    def _exaltation_status(planet: str, sign: str, degree: float) -> Tuple[Optional[str], str]:
        """Return (status_label, reason_string) for exaltation/debilitation/own/neutral."""
        canon = RajayogaService._normalize_sign_name(sign)
        if planet in EXALTATION:
            ex_sign, ex_deg = EXALTATION[planet]
            if canon == ex_sign:
                diff = abs(degree - ex_deg)
                if diff <= 1.0:
                    return ("exalted", f"{planet} at {degree:.1f}° {canon} = exact exaltation point ({ex_deg}°)")
                elif diff <= 5.0:
                    return ("exalted", f"{planet} at {degree:.1f}° {canon} = near exaltation point ({ex_deg}°)")
                else:
                    return ("exalted", f"{planet} at {degree:.1f}° {canon} = in exaltation sign, away from exact degree ({ex_deg}°)")
        if planet in DEBILITATION:
            deb_sign, deb_deg = DEBILITATION[planet]
            if canon == deb_sign:
                diff = abs(degree - deb_deg)
                if diff <= 1.0:
                    return ("debilitated", f"{planet} at {degree:.1f}° {canon} = exact debilitation point ({deb_deg}°)")
                elif diff <= 5.0:
                    return ("debilitated", f"{planet} at {degree:.1f}° {canon} = near debilitation point ({deb_deg}°)")
                else:
                    return ("debilitated", f"{planet} at {degree:.1f}° {canon} = in debilitation sign, away from exact degree ({deb_deg}°)")
        if planet in OWN_SIGNS and canon in OWN_SIGNS[planet]:
            return ("own_sign", f"{planet} in {canon}, a sign it rules")
        return ("neutral", f"{planet} in {canon}, neither exalted/debilitated nor own sign")

    @staticmethod
    def _digbala_note(planet: str, house: Optional[int]) -> str:
        """Return a directional-strength note string."""
        if house is None:
            return "Directional strength unknown (no house data)."
        pref = _DIGBALA_HOUSES.get(planet)
        if pref is None:
            return ""
        if house == pref:
            return f"{planet} in house {house} = full Digbala (directional strength)."
        if house in {pref - 1, pref + 1}:
            return f"{planet} in house {house} = moderate Digbala (adjacent to house {pref})."
        return f"{planet} in house {house}, no special directional gain."

    @staticmethod
    def _ordinal(n: int) -> str:
        """Return '1st', '2nd', '3rd' etc. for the given integer."""
        if 11 <= (n % 100) <= 13:
            return f"{n}th"
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
        return f"{n}{suffix}"

    @staticmethod
    def _planet_in_sign(planet_data: Dict[str, Dict], planet_name: str, target_signs: Set[str]) -> bool:
        """Return True if *planet_name* is in any of *target_signs*."""
        info = planet_data.get(planet_name)
        if not isinstance(info, dict):
            return False
        canon = RajayogaService._normalize_sign_name(info.get("sign", ""))
        return canon in target_signs

    # ------------------------------------------------------------------
    # Method 1: Rajayoga pattern detection
    # ------------------------------------------------------------------

    def detect_rajayoga_patterns(self, planet_data: Dict[str, Dict], lagna: str) -> Dict[str, Any]:
        """Detect Rajayoga patterns, their strength, and blemish candidates.

        Args:
            planet_data: Dict keyed by planet name (e.g. "Sun") with sub-dicts
                         containing ``sign``, ``degree``, ``house``, ``retrograde``.
            lagna: Ascendant sign name (any casing / alias).

        Returns:
            Dict with ``yogas`` (list of found patterns), ``blemishes``, and a summary.
        """
        lagna = self._normalize_sign_name(lagna)
        lords = self._house_lords(lagna)

        # Resolve key planet houses
        lagna_lord = lords[1]
        fourth_lord = lords[4]
        tenth_lord = lords[10]
        eleventh_lord = lords[11]
        dusthana_lords = {h: lords[h] for h in _DUSTHANA_HOUSES}

        lagna_lord_house = self._find_planet_house(planet_data, lagna_lord)
        fourth_lord_house = self._find_planet_house(planet_data, fourth_lord)
        tenth_lord_house = self._find_planet_house(planet_data, tenth_lord)
        eleventh_lord_house = self._find_planet_house(planet_data, eleventh_lord)

        yogas: List[Dict[str, Any]] = []
        blemishes: List[Dict[str, Any]] = []

        # --- Yoga 1: 5th-11th-Lagna loop ---
        loop_triggered = False
        kendra_lords_in_5_11: List[str] = []
        for lord_name, lord_house in [
            (lagna_lord, lagna_lord_house),
            (fourth_lord, fourth_lord_house),
            (tenth_lord, tenth_lord_house),
        ]:
            if lord_house in (5, 11):
                kendra_lords_in_5_11.append(f"{lord_name} (lord) in house {lord_house}")
                loop_triggered = True

        # Also check if these lords aspect 5th or 11th
        for lord_name, lord_house in [
            (lagna_lord, lagna_lord_house),
            (fourth_lord, fourth_lord_house),
            (tenth_lord, tenth_lord_house),
        ]:
            if lord_house is None:
                continue
            if self._aspects_house(lord_name, lord_house, 5):
                kendra_lords_in_5_11.append(f"{lord_name} in house {lord_house} aspects 5th")
                loop_triggered = True
            if self._aspects_house(lord_name, lord_house, 11):
                kendra_lords_in_5_11.append(f"{lord_name} in house {lord_house} aspects 11th")
                loop_triggered = True

        if loop_triggered:
            strength = "strong" if len(kendra_lords_in_5_11) >= 2 else "moderate"
            yogas.append({
                "name": "5th-11th-Lagna Loop",
                "strength": strength,
                "description": (
                    "Key pillar lords (Lagna/4th/10th) connect to the 5th house of "
                    "creative intelligence or the 11th house of gains and networks. "
                    "This channels authority into self-directed creative output or "
                    "network-driven growth."
                ),
                "evidence": kendra_lords_in_5_11,
            })

        # --- Yoga 2: Lagna lord in 5th ---
        if lagna_lord_house == 5:
            yogas.append({
                "name": "Lagna Lord in 5th",
                "strength": "strong",
                "description": (
                    f"Your ascendant lord {lagna_lord} sits in the 5th house of "
                    "creativity, intelligence, and self-expression. This gives "
                    "self-directed creator authority — your identity is expressed "
                    "through what you create, teach, or author."
                ),
                "evidence": [f"{lagna_lord} in house 5"],
            })

        # --- Yoga 3: Venus in own sign in 11th ---
        venus_info = planet_data.get("Venus", {})
        venus_sign = self._normalize_sign_name(venus_info.get("sign", ""))
        venus_house = venus_info.get("house")
        if venus_sign in OWN_SIGNS.get("Venus", set()) and venus_house == 11:
            yogas.append({
                "name": "Venus Own-Sign 11th Network Engine",
                "strength": "strong",
                "description": (
                    "Venus in its own sign occupying the 11th house of gains and "
                    "networks acts as a powerful engine for income through social "
                    "connections, platforms, and audience-building."
                ),
                "evidence": [f"Venus in {venus_sign} (own sign), house 11"],
            })

        # --- Yoga 4: Mars exalted in 2nd ---
        mars_info = planet_data.get("Mars", {})
        mars_sign = self._normalize_sign_name(mars_info.get("sign", ""))
        mars_house = mars_info.get("house")
        mars_deg = mars_info.get("degree", 0.0)
        if mars_sign == "Capricorn" and mars_house == 2:
            diff = abs(mars_deg - 28.0)
            if diff <= 3.0:
                strength = "strong"
            else:
                strength = "moderate"
            yogas.append({
                "name": "Mars Exalted in 2nd — Wealth Engine",
                "strength": strength,
                "description": (
                    "Mars exalted in Capricorn occupying the 2nd house of wealth "
                    "and values creates a disciplined, tangible-output engine. "
                    "Earning power comes through structured execution, technical "
                    "mastery, and persistent effort."
                ),
                "evidence": [f"Mars at {mars_deg:.1f}° Capricorn (exaltation 28°), house 2"],
            })

        # --- Yoga 5: Jupiter aspecting Lagna ---
        jupiter_info = planet_data.get("Jupiter", {})
        jupiter_house = jupiter_info.get("house")
        if jupiter_house is not None and self._aspects_house("Jupiter", jupiter_house, 1):
            yogas.append({
                "name": "Jupiter Aspect on Lagna",
                "strength": "strong",
                "description": (
                    "Jupiter casts its protective, wisdom-bearing aspect on your "
                    "ascendant. This acts as a shield against poor decisions and "
                    "brings an innate sense of dharma and timing."
                ),
                "evidence": [f"Jupiter in house {jupiter_house} aspects house 1 (Lagna)"],
            })

        # --- BLEMISH CHECKS ---

        # Blemish: Debilitated planet aspecting 11th
        for planet_name in ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]:
            info = planet_data.get(planet_name, {})
            p_sign = self._normalize_sign_name(info.get("sign", ""))
            p_house = info.get("house")
            status, _ = self._exaltation_status(planet_name, p_sign, info.get("degree", 0.0))
            if status == "debilitated" and p_house is not None:
                if self._aspects_house(planet_name, p_house, 11):
                    blemishes.append({
                        "name": f"Debilitated {planet_name} Aspect on 11th",
                        "severity": "high",
                        "description": (
                            f"{planet_name} is debilitated in {p_sign} and aspects the "
                            "11th house of gains. Network income may face delays, "
                            "unreliable allies, or gains that come with hidden costs."
                        ),
                    })

        # Blemish: 10th lord in 12th
        if tenth_lord_house == 12:
            blemishes.append({
                "name": "10th Lord in 12th — Hidden Career",
                "severity": "critical",
                "description": (
                    f"Your 10th lord ({tenth_lord}) of career and public standing "
                    "sits in the 12th house of hidden expenses, foreign lands, and "
                    "dissolution. Traditional career paths will feel draining. "
                    "Success comes through backend systems, international work, "
                    "or institutions rather than corporate ladder climbing."
                ),
            })

        # Blemish: 3rd/6th/11th lord afflictions (debilitated or in dusthana)
        for lord_house, lord_name in {3: lords[3], 6: lords[6], 11: lords[11]}.items():
            lord_actual_house = self._find_planet_house(planet_data, lord_name)
            lord_info = planet_data.get(lord_name, {})
            lord_sign = self._normalize_sign_name(lord_info.get("sign", ""))
            status, _ = self._exaltation_status(lord_name, lord_sign, lord_info.get("degree", 0.0))
            reasons: List[str] = []
            if status == "debilitated":
                reasons.append(f"debilitated in {lord_sign}")
            if lord_actual_house in _DUSTHANA_HOUSES:
                reasons.append(f"placed in house {lord_actual_house} (dusthana)")
            if reasons:
                    area_labels = {3: "communication/courage", 6: "health/service", 11: "gains/networks"}
                    area = area_labels.get(lord_house, "that life area")
                    blemishes.append({
                        "name": f"{lord_house}th Lord ({lord_name}) Afflicted",
                        "severity": "high" if len(reasons) >= 2 else "moderate",
                        "description": (
                            f"The lord of the {lord_house}th house ({lord_name}) is "
                            f"{', '.join(reasons)}. This can create friction in {area}."
                        ),
                    })

        # Blemish: 12th house planets
        planets_in_12th = [
            p for p, info in planet_data.items()
            if isinstance(info, dict) and info.get("house") == 12
        ]
        if planets_in_12th:
            blemishes.append({
                "name": "12th House Accumulation",
                "severity": "moderate",
                "description": (
                    f"Planets in 12th house ({', '.join(planets_in_12th)}) signal "
                    "hidden expenses, backend dependency, or energy drained through "
                    "invisible channels. Rest and isolation are productive but may "
                    "delay visible results."
                ),
            })

        return {
            "lagna": lagna,
            "yogas": yogas,
            "blemishes": blemishes,
            "yoga_count": len(yogas),
            "blemish_count": len(blemishes),
            "summary": (
                f"Found {len(yogas)} Rajayoga pattern(s) and {len(blemishes)} blemish(es) "
                f"for {lagna} ascendant."
            ),
        }

    # ------------------------------------------------------------------
    # Method 2: Optimization matrix
    # ------------------------------------------------------------------

    def get_optimization_matrix(self, planet_data: Dict[str, Dict]) -> Dict[str, Any]:
        """Score each planet's optimisation status with colour-coded dignity.

        Returns:
            Dict with ``planets`` (list of per-planet status dicts) and a summary.
        """
        status_color: Dict[str, str] = {
            "exalted": "🟢 EXALTED",
            "debilitated": "🔴 DEBILITATED",
            "own_sign": "🔵 OWN_SIGN",
            "neutral": "⚪ NEUTRAL",
        }

        results: List[Dict[str, Any]] = []
        exalted_count = 0
        debilitated_count = 0

        for planet_name, info in planet_data.items():
            if not isinstance(info, dict):
                continue
            sign = self._normalize_sign_name(info.get("sign", ""))
            house = info.get("house")
            degree = float(info.get("degree", 0.0))
            retro = bool(info.get("retrograde", False))

            status, reason = self._exaltation_status(planet_name, sign, degree)
            digbala = self._digbala_note(planet_name, house)

            if status == "exalted":
                exalted_count += 1
            elif status == "debilitated":
                debilitated_count += 1

            # Retrograde modifier
            if retro:
                reason += " (retrograde — adds contemplative/internal strength)."
                if digbala:
                    digbala += " Retrograde motion adds depth."
                else:
                    digbala = "Retrograde motion adds contemplative depth."

            results.append({
                "planet": planet_name,
                "sign": sign,
                "house": house,
                "degree": degree,
                "retrograde": retro,
                "status": status,
                "status_color": status_color.get(status, "⚪ NEUTRAL"),
                "status_reason": reason,
                "directional_strength_note": digbala or "No special directional note.",
            })

        return {
            "planets": results,
            "exalted_count": exalted_count,
            "debilitated_count": debilitated_count,
            "summary": (
                f"{exalted_count} exalted, {debilitated_count} debilitated "
                f"across {len(results)} planets."
            ),
        }

    # ------------------------------------------------------------------
    # Method 3: Constraint extraction
    # ------------------------------------------------------------------

    def extract_constraints(
        self,
        planet_data: Dict[str, Dict],
        lagna: str,
        yoga_results: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        """Derive 3–5 chart-specific constraints with actionable guardrails.

        Args:
            planet_data: Planet positions dict.
            lagna: Ascendant sign.
            yoga_results: Output from ``detect_rajayoga_patterns``.

        Returns:
            List of constraint dicts with ``title``, ``description``, ``guardrail``, ``severity``.
        """
        lagna = self._normalize_sign_name(lagna)
        lords = self._house_lords(lagna)
        constraints: List[Dict[str, Any]] = []

        # Constraint 1: 12th house planets
        planets_12th = [
            p for p, info in planet_data.items()
            if isinstance(info, dict) and info.get("house") == 12
        ]
        if planets_12th:
            constraints.append({
                "title": f"12th House {' / '.join(planets_12th)} Leak",
                "description": (
                    f"Planets in your 12th house ({', '.join(planets_12th)}) pull "
                    "energy into hidden realms — backend work, foreign connections, "
                    "institutions, or spiritual practice. Visible output may lag "
                    "behind invisible effort."
                ),
                "guardrail": (
                    "Build cost-control systems. Never self-fund R&D without a "
                    "revenue anchor tethered to it. Let your backend complexity "
                    "power a simple frontend — your leverage is invisible plumbing, "
                    "not visible polish. Contract recurring expenses against a "
                    "hard cap."
                ),
                "severity": "critical" if len(planets_12th) >= 3 else "high",
            })

        # Constraint 2: Debilitated planets
        for planet_name in ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]:
            info = planet_data.get(planet_name, {})
            if not isinstance(info, dict):
                continue
            sign = self._normalize_sign_name(info.get("sign", ""))
            degree = float(info.get("degree", 0.0))
            house = info.get("house")
            status, _ = self._exaltation_status(planet_name, sign, degree)
            if status == "debilitated":
                constraints.append({
                    "title": f"Debilitated {planet_name} in {sign}",
                    "description": (
                        f"{planet_name} is debilitated in {sign} (house {house or '?'}). "
                        "This is where you face systematic friction — the area of "
                        "life ruled by this planet requires deliberate compensation. "
                        "Natural talent alone will not carry you here."
                    ),
                    "guardrail": (
                        f"Compensate with deliberate systems, not raw effort. If "
                        f"{planet_name} rules communication: publish on a fixed "
                        f"cadence, never trust 'I'll write when inspired.' If it "
                        f"rules wealth: automate savings before spending hits your "
                        f"account. Treat this domain like a muscle that needs "
                        f"programmed training, not natural talent."
                    ),
                    "severity": "critical",
                })

        # Constraint 3: Dusthana lords aspecting benefic houses
        for dh_house, dh_lord in {6: lords[6], 8: lords[8], 12: lords[12]}.items():
            dh_lord_house = self._find_planet_house(planet_data, dh_lord)
            if dh_lord_house is None:
                continue
            afflicted: List[int] = []
            for benefic_house in {1, 5, 9}:
                if self._aspects_house(dh_lord, dh_lord_house, benefic_house):
                    afflicted.append(benefic_house)
            if afflicted:
                constraints.append({
                    "title": f"{dh_house}th Lord ({dh_lord}) Aspect on Benefic Houses",
                    "description": (
                        f"The lord of the {dh_house}th dusthana house ({dh_lord}) "
                        f"in house {dh_lord_house} casts its aspect on house(s) "
                        f"{afflicted}. Obstacle-house energy colours otherwise "
                        f"auspicious areas of life."
                    ),
                    "guardrail": (
                        f"Every opportunity touching your {', '.join(self._ordinal(h) for h in afflicted)} house "
                        "needs a second opinion from someone with no stake in the "
                        "outcome. What looks like luck here often carries hidden "
                        "costs. Before committing, list three ways the deal could "
                        "entangle you — if you cannot find any, you have not looked "
                        "hard enough."
                    ),
                    "severity": "high" if 5 in afflicted or 9 in afflicted else "moderate",
                })

        # Constraint 4: Lagna lord weakness or conflicting placement
        lagna_lord = lords[1]
        lagna_lord_info = planet_data.get(lagna_lord, {})
        lagna_lord_house = lagna_lord_info.get("house") if isinstance(lagna_lord_info, dict) else None
        lagna_lord_sign = self._normalize_sign_name(
            lagna_lord_info.get("sign", "")
        ) if isinstance(lagna_lord_info, dict) else ""
        lagna_lord_status, _ = self._exaltation_status(
            lagna_lord, lagna_lord_sign, float(lagna_lord_info.get("degree", 0.0))
        ) if isinstance(lagna_lord_info, dict) else ("neutral", "")
        if lagna_lord_status == "debilitated" or lagna_lord_house in _DUSTHANA_HOUSES:
            reason = "debilitated" if lagna_lord_status == "debilitated" else f"in dusthana house {lagna_lord_house}"
            constraints.append({
                "title": f"Lagna Lord ({lagna_lord}) Weak — {reason}",
                "description": (
                    f"Your ascendant lord {lagna_lord} is {reason}. The self, "
                    "health, and life direction are the terrain of persistent work, "
                    "not effortless flow. Identity must be built deliberately."
                ),
                "guardrail": (
                    "Never define yourself through a job title or external label. "
                    "Build identity through a body of work you own — shipped "
                    "projects, published writing, launched products. Track health "
                    "metrics (sleep, HRV, blood work) quarterly; a weak lagna lord "
                    "means your body will not warn you before it breaks."
                ),
                "severity": "critical" if lagna_lord_status == "debilitated" else "high",
            })

        # Trim to top 5 by severity
        severity_order = {"critical": 0, "high": 1, "moderate": 2}
        constraints.sort(key=lambda c: severity_order.get(c.get("severity", "moderate"), 2))
        return constraints[:5]

    # ------------------------------------------------------------------
    # Method 4: Archetype determination
    # ------------------------------------------------------------------

    def determine_archetype(
        self,
        planet_data: Dict[str, Dict],
        lagna: str,
        yoga_results: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Synthesise the chart into 1–2 archetype labels with explanation.

        Args:
            planet_data: Planet positions dict.
            lagna: Ascendant sign.
            yoga_results: Output from ``detect_rajayoga_patterns``.

        Returns:
            Dict with ``primary``, ``secondary``, and ``synthesis`` keys.
        """
        lagna = self._normalize_sign_name(lagna)
        element = _LAGNA_ELEMENT.get(lagna, "Unknown")
        opt = self.get_optimization_matrix(planet_data)
        yogas_found = yoga_results.get("yogas", [])
        yoga_names: Set[str] = {y.get("name", "") for y in yogas_found}

        # Gather signals
        signals: Set[str] = set()

        # Element signal
        if element == "Fire":
            signals.update({"fire_lagna", "sun_strong"})
        elif element == "Earth":
            signals.update({"earth_lagna", "saturn_strong"})
        elif element == "Air":
            signals.update({"air_lagna", "mercury_strong"})
        elif element == "Water":
            signals.update({"water_lagna", "ketu_strong"})

        # Dignity signals
        for entry in opt.get("planets", []):
            if entry["status"] == "exalted":
                signals.add(f"{entry['planet'].lower()}_exalted")
            elif entry["status"] == "own_sign":
                signals.add(f"{entry['planet'].lower()}_strong")
            elif entry["status"] == "debilitated":
                signals.add(f"{entry['planet'].lower()}_debilitated")

        # House emphasis
        house_counts: Dict[int, int] = {}
        for info in planet_data.values():
            if isinstance(info, dict):
                h = info.get("house")
                if h is not None:
                    house_counts[h] = house_counts.get(h, 0) + 1
        for h, c in house_counts.items():
            if c >= 3:
                signals.add(f"{h}_emphasis")
            if c == 2:
                signals.add(f"{h}_emphasis")

        # Yoga-based signals
        if any("5th-11th-Lagna Loop" in n for n in yoga_names):
            signals.add("5th_11th_loop")
        if any("Lagna Lord in 5th" in n for n in yoga_names):
            signals.add("lagna_lord_5th")
        if any("Venus Own-Sign 11th" in n for n in yoga_names):
            signals.add("venus_11th_own")
        if any("Mars Exalted in 2nd" in n for n in yoga_names):
            signals.add("mars_exalted_2nd")
        if any("Jupiter Aspect on Lagna" in n for n in yoga_names):
            signals.add("jupiter_lagna")

        # Score archetypes by signal overlap
        scored: List[Tuple[int, Dict[str, Any]]] = []
        for arch in _ARCHETYPES:
            score = sum(1 for kw in arch["keywords"] if kw in signals)
            if score > 0:
                scored.append((score, arch))

        scored.sort(key=lambda x: x[0], reverse=True)

        # Assign primary and secondary
        primary = scored[0][1]["label"] if scored else "Constraint-First Architect"
        secondary = ""
        if len(scored) >= 2 and scored[1][0] >= 1:
            secondary = scored[1][1]["label"]
        elif len(scored) >= 1 and scored[0][0] > 2:
            # If primary is strong, pick a complementary secondary
            for arch in _ARCHETYPES:
                if arch["label"] != primary and any(kw in signals for kw in arch["keywords"]):
                    secondary = arch["label"]
                    break

        # Build synthesis paragraph
        synthesis = self._build_synthesis(primary, secondary, lagna, element, opt, yogas_found, signals)

        return {
            "primary": primary,
            "secondary": secondary or primary,
            "synthesis": synthesis,
            "signals_detected": sorted(signals),
        }

    def _build_synthesis(
        self,
        primary: str,
        secondary: str,
        lagna: str,
        element: str,
        opt: Dict[str, Any],
        yogas: List[Dict[str, Any]],
        signals: Set[str],
    ) -> str:
        """Compose a one-paragraph synthesis of the chart architecture."""
        parts: List[str] = []

        parts.append(f"With a {lagna} ascendant ({element} element),")

        # Strongest planet
        exalted = [p for p in opt.get("planets", []) if p["status"] == "exalted"]
        own_sign = [p for p in opt.get("planets", []) if p["status"] == "own_sign" and p["planet"] not in {e["planet"] for e in exalted}]
        debilitated = [p for p in opt.get("planets", []) if p["status"] == "debilitated"]

        if exalted:
            planet_names = ", ".join(p["planet"] for p in exalted)
            parts.append(f"your chart is powered by exalted {planet_names},")
        if own_sign:
            planet_names = ", ".join(p["planet"] for p in own_sign[:2])
            domain_word = "their own domains" if len(own_sign) > 1 else "its own domain"
            parts.append(f"with {planet_names} comfortably positioned in {domain_word},")
        if debilitated:
            planet_names = ", ".join(p["planet"] for p in debilitated)
            parts.append(f"while debilitated {planet_names} mark areas of deliberate compensation,")

        # Yoga texture
        if yogas:
            yoga_texts = [y["name"] for y in yogas]
            parts.append(f"the chart contains {', '.join(yoga_texts)},")

        # Archetype paragraph — each tells the user HOW to operate, not just what they are.
        arch_map: Dict[str, str] = {
            "Sovereign Creator": (
                "you operate best as an owner-creator. Your identity and your work "
                "are one — do not separate them. Build things you can sign your name "
                "to. Structure compensation as equity, royalties, or ownership, never "
                "pure salary. Every hour spent executing someone else's vision is an "
                "hour lost."
            ),
            "Capital Engineer": (
                "your architecture routes toward capital formation through disciplined "
                "execution. Wealth is engineered, not speculated — build repeatable "
                "systems that compound. Own the infrastructure, not just the output. "
                "Technical mastery plus process ownership equals durable income."
            ),
            "Network Architect": (
                "your value compounds through networks and platforms. Distribution is "
                "your edge — the right connection multiplies output more than working "
                "harder. Build audience before you build product. Spend 30% of your "
                "time on relationship infrastructure: intros, content, community."
            ),
            "Hidden Systems Builder": (
                "your strength is invisible plumbing. Build backend complexity that "
                "powers deceptively simple frontends. Automate before you hire. Let "
                "others present the work; you build the engine. Your market advantage "
                "is that competitors cannot reverse-engineer what they cannot see."
            ),
            "Constraint-First Architect": (
                "your chart is defined by constraints. Treat them as the design brief, "
                "not the obstacle. List your top three frictions explicitly — then build "
                "systems that operate within them rather than fighting them. The most "
                "elegant architectures emerge from the tightest constraints."
            ),
            "Platform Monetizer": (
                "your creative intelligence (5th house) routes into network income "
                "(11th house). Build once, distribute to many. Every piece of content "
                "or product should serve as both creative output and distribution "
                "engine. Scale through audience, not headcount."
            ),
            "Research Oracle": (
                "your mind is optimized for depth. Surface-level work will drain you — "
                "specialize ruthlessly. Build leverage through knowledge asymmetry: "
                "know one domain so deeply that your insight cannot be commoditized. "
                "Write; your written word is your best salesperson."
            ),
            "Industrial Executor": (
                "you are built for output at scale. Build teams, systems, and reputation "
                "in public. Your authority compounds through visible achievement — "
                "ship regularly and let the track record speak. Delegate execution "
                "details so you can focus on direction and standards."
            ),
            "Diplomatic Strategist": (
                "your influence flows through relationships and strategic alignment. "
                "Advance by aligning interests, never by overpowering. Before any move, "
                "map who wins and who loses — then structure the deal so everyone "
                "wins enough to stay at the table. Your power is in the architecture "
                "of the agreement, not the force behind it."
            ),
        }

        primary_text = arch_map.get(primary, f"{primary} archetype.")
        parts.append(f"collectively pointing to the {primary} archetype: {primary_text}")

        if secondary and secondary != primary:
            secondary_text = arch_map.get(secondary, "")
            if secondary_text:
                parts.append(f"The secondary {secondary} influence adds {secondary_text}")

        return " ".join(parts)

    # ------------------------------------------------------------------
    # Method 5: Full report
    # ------------------------------------------------------------------

    def full_rajayoga_report(self, planet_data: Dict[str, Dict], lagna: str) -> Dict[str, Any]:
        """Combine all Rajayoga analysis methods into one comprehensive report.

        Args:
            planet_data: Dict keyed by planet name with ``sign``, ``degree``,
                         ``house``, and optionally ``retrograde``.
            lagna: Ascendant sign (case-insensitive, supports Vedic aliases).

        Returns:
            Nested dict with ``yoga_analysis``, ``optimization_matrix``,
            ``constraints``, and ``archetype`` sections.
        """
        yoga_analysis = self.detect_rajayoga_patterns(planet_data, lagna)
        optimization_matrix = self.get_optimization_matrix(planet_data)
        constraints = self.extract_constraints(planet_data, lagna, yoga_analysis)
        archetype = self.determine_archetype(planet_data, lagna, yoga_analysis)

        return {
            "yoga_analysis": yoga_analysis,
            "optimization_matrix": optimization_matrix,
            "constraints": constraints,
            "archetype": archetype,
        }
