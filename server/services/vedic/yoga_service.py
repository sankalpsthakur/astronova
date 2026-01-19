"""Yoga detection (report-friendly subset).

This is intentionally conservative: we detect a small set of widely-used yogas
with clear conditions and plain-language explanations.
"""

from __future__ import annotations

from dataclasses import dataclass

from .constants import VEDIC_SIGNS, VEDIC_SIGN_INDEX, VEDIC_SIGN_RULERS

_KENDRA_HOUSES = {1, 4, 7, 10}
_TRIKONA_HOUSES = {1, 5, 9}
_DUSTHANA_HOUSES = {6, 8, 12}

_EXALTATION: dict[str, str] = {
    "Mars": "Makara",
    "Mercury": "Kanya",
    "Jupiter": "Karka",
    "Venus": "Meena",
    "Saturn": "Tula",
}

_OWN_SIGNS: dict[str, set[str]] = {
    "Mars": {"Mesha", "Vrischika"},
    "Mercury": {"Mithuna", "Kanya"},
    "Jupiter": {"Dhanu", "Meena"},
    "Venus": {"Vrishabha", "Tula"},
    "Saturn": {"Makara", "Kumbha"},
}

_NATURAL_BENEFICS = {"jupiter", "venus", "mercury"}
_NATURAL_MALEFICS = {"sun", "mars", "saturn", "rahu", "ketu"}


@dataclass(frozen=True)
class Yoga:
    name: str
    category: str
    description: str
    evidence: dict[str, object]


def _sign_index(sign: str) -> int | None:
    return VEDIC_SIGN_INDEX.get(sign)


def _house_from_sign(*, lagna_sign: str, sign: str) -> int | None:
    lagna_idx = _sign_index(lagna_sign)
    idx = _sign_index(sign)
    if lagna_idx is None or idx is None:
        return None
    return ((idx - lagna_idx) % 12) + 1


def _relative_house(*, from_sign: str, to_sign: str) -> int | None:
    from_idx = _sign_index(from_sign)
    to_idx = _sign_index(to_sign)
    if from_idx is None or to_idx is None:
        return None
    return ((to_idx - from_idx) % 12) + 1


def _conjunct(*, lon1: float, lon2: float, orb_deg: float = 8.0) -> bool:
    diff = abs((lon1 - lon2 + 180.0) % 360.0 - 180.0)
    return diff <= orb_deg


def _aspected_signs(planet: str, sign_index: int) -> set[int]:
    # Basic Vedic aspects (rashi drishti approximation).
    targets = {(sign_index + 6) % 12}  # 7th aspect (all planets)
    if planet.lower() == "mars":
        targets |= {(sign_index + 3) % 12, (sign_index + 7) % 12}
    if planet.lower() == "jupiter":
        targets |= {(sign_index + 4) % 12, (sign_index + 8) % 12}
    if planet.lower() == "saturn":
        targets |= {(sign_index + 2) % 12, (sign_index + 9) % 12}
    if planet.lower() in {"rahu", "ketu"}:
        targets |= {(sign_index + 4) % 12, (sign_index + 8) % 12}
    return targets


def _mutual_aspect(p1: str, lon1: float, p2: str, lon2: float) -> bool:
    s1 = int((lon1 % 360.0) // 30) % 12
    s2 = int((lon2 % 360.0) // 30) % 12
    return (s2 in _aspected_signs(p1, s1)) and (s1 in _aspected_signs(p2, s2))


def _is_own_or_exalted(planet: str, sign: str) -> tuple[bool, str]:
    if planet in _OWN_SIGNS and sign in _OWN_SIGNS[planet]:
        return True, "own"
    if _EXALTATION.get(planet) == sign:
        return True, "exalted"
    return False, "neutral"


def _house_lords(*, lagna_sign: str) -> dict[int, str]:
    lagna_idx = _sign_index(lagna_sign) or 0
    lords: dict[int, str] = {}
    for house in range(1, 13):
        sign = VEDIC_SIGNS[(lagna_idx + house - 1) % 12]
        lords[house] = VEDIC_SIGN_RULERS.get(sign, "")
    return lords


def _planet_key_from_lord_name(name: str) -> str:
    key = (name or "").strip().lower()
    mapping = {
        "sun": "sun",
        "moon": "moon",
        "mars": "mars",
        "mercury": "mercury",
        "jupiter": "jupiter",
        "venus": "venus",
        "saturn": "saturn",
        "rahu": "rahu",
        "ketu": "ketu",
    }
    return mapping.get(key, key)


def detect_yogas(*, lagna_sign: str, planets: dict[str, dict]) -> list[dict[str, object]]:
    """Detect a subset of yogas from sidereal positions."""
    yogas: list[Yoga] = []
    seen: set[tuple[str, str]] = set()

    # Helper to fetch planet longitude and sign.
    def pinfo(name: str) -> tuple[str | None, float | None]:
        info = planets.get(name)
        if not isinstance(info, dict):
            return None, None
        sign = info.get("sign")
        lon = info.get("longitude")
        try:
            return (str(sign) if isinstance(sign, str) else None, float(lon) if lon is not None else None)
        except Exception:
            return (str(sign) if isinstance(sign, str) else None, None)

    # Panch Mahapurusha Yogas (kendra + own/exalted).
    for planet, yoga_name in [
        ("mars", "Ruchaka Yoga"),
        ("mercury", "Bhadra Yoga"),
        ("jupiter", "Hamsa Yoga"),
        ("venus", "Malavya Yoga"),
        ("saturn", "Shasha Yoga"),
    ]:
        sign, lon = pinfo(planet)
        if sign is None or lon is None:
            continue
        house = _house_from_sign(lagna_sign=lagna_sign, sign=sign)
        if house not in _KENDRA_HOUSES:
            continue
        ok, dignity = _is_own_or_exalted(planet.title(), sign)
        if not ok:
            continue
        yogas.append(
            Yoga(
                name=yoga_name,
                category="Panch Mahapurusha",
                description=f"{planet.title()} is strong (own/exalted) and placed in a pillar house (1/4/7/10), amplifying its good results.",
                evidence={"planet": planet, "house": house, "sign": sign, "dignity": dignity},
            )
        )

    def add(y: Yoga) -> None:
        key = (y.name, y.category)
        if key in seen:
            return
        seen.add(key)
        yogas.append(y)

    # Budhaditya Yoga: Sun + Mercury conjunction (within orb).
    sun_sign, sun_lon = pinfo("sun")
    mer_sign, mer_lon = pinfo("mercury")
    if sun_lon is not None and mer_lon is not None and _conjunct(lon1=sun_lon, lon2=mer_lon, orb_deg=8.0):
        add(
            Yoga(
                name="Budhaditya Yoga",
                category="Conjunction",
                description="Sun + Mercury close together can support confidence, clarity, and communication skills.",
                evidence={"planets": ["sun", "mercury"], "orb_deg": round(abs((sun_lon - mer_lon + 180) % 360 - 180), 2)},
            )
        )

    # Chandra-Mangal Yoga: Moon + Mars conjunction (within orb).
    moon_sign, moon_lon = pinfo("moon")
    mars_sign, mars_lon = pinfo("mars")
    if moon_lon is not None and mars_lon is not None and _conjunct(lon1=moon_lon, lon2=mars_lon, orb_deg=8.0):
        add(
            Yoga(
                name="Chandra-Mangal Yoga",
                category="Conjunction",
                description="Moon + Mars together can bring initiative and strong drive, especially around goals and resources.",
                evidence={"planets": ["moon", "mars"], "orb_deg": round(abs((moon_lon - mars_lon + 180) % 360 - 180), 2)},
            )
        )

    # Gajakesari Yoga: Jupiter in kendra from Moon (sign-based).
    jup_sign, jup_lon = pinfo("jupiter")
    if moon_sign and jup_sign:
        m_idx = _sign_index(moon_sign)
        j_idx = _sign_index(jup_sign)
        if m_idx is not None and j_idx is not None:
            rel_house = ((j_idx - m_idx) % 12) + 1
            if rel_house in _KENDRA_HOUSES:
                add(
                    Yoga(
                        name="Gajakesari Yoga",
                        category="Lunar",
                        description="Jupiter placed in a pillar position from the Moon can support wisdom, opportunities, and emotional stability over time.",
                        evidence={"moon_sign": moon_sign, "jupiter_sign": jup_sign, "relative_house_from_moon": rel_house},
                    )
                )

    # Lunar yogas based on planets around the Moon (Sunapha/Anapha/Durudhara).
    if moon_sign:
        planets_from_moon: dict[int, list[str]] = {i: [] for i in range(1, 13)}
        for planet in planets.keys():
            if planet in {"moon", "ascendant"}:
                continue
            sign, _lon = pinfo(planet)
            if not sign:
                continue
            rel = _relative_house(from_sign=moon_sign, to_sign=sign)
            if rel:
                planets_from_moon[rel].append(planet)

        sunapha_planets = [p for p in planets_from_moon.get(2, []) if p not in {"sun"}]
        anapha_planets = [p for p in planets_from_moon.get(12, []) if p not in {"sun"}]

        if sunapha_planets:
            add(
                Yoga(
                    name="Sunapha Yoga",
                    category="Lunar",
                    description="Planets in the 2nd sign from the Moon are said to support confidence, resources, and self-sufficiency.",
                    evidence={"planets": sorted(sunapha_planets), "fromMoonHouse": 2},
                )
            )
        if anapha_planets:
            add(
                Yoga(
                    name="Anapha Yoga",
                    category="Lunar",
                    description="Planets in the 12th sign from the Moon are said to support inner strength, reflection, and resilience.",
                    evidence={"planets": sorted(anapha_planets), "fromMoonHouse": 12},
                )
            )
        if sunapha_planets and anapha_planets:
            add(
                Yoga(
                    name="Durudhara Yoga",
                    category="Lunar",
                    description="Planets on both sides of the Moon (2nd and 12th) are said to create balance and steady support through life phases.",
                    evidence={"planets2nd": sorted(sunapha_planets), "planets12th": sorted(anapha_planets)},
                )
            )

        # Adhi Yoga (classic): Jupiter/Venus/Mercury all fall in 6/7/8 from Moon (any arrangement).
        benefic_houses = {6, 7, 8}
        houses_of_benefics = {}
        for b in _NATURAL_BENEFICS:
            sign, _ = pinfo(b)
            if not sign:
                continue
            rel = _relative_house(from_sign=moon_sign, to_sign=sign)
            if rel:
                houses_of_benefics[b] = rel
        if houses_of_benefics and all(h in benefic_houses for h in houses_of_benefics.values()) and len(houses_of_benefics) == 3:
            add(
                Yoga(
                    name="Adhi Yoga",
                    category="Lunar",
                    description="When key benefics cluster in the 6th–8th from the Moon, it’s traditionally read as support for authority, stability, and problem-solving.",
                    evidence={"benefics": houses_of_benefics},
                )
            )

        # Vasumati Yoga (simplified): benefics in upachaya houses (3,6,10,11) from Moon.
        upachaya = {3, 6, 10, 11}
        benefics_upachaya = []
        for b in _NATURAL_BENEFICS:
            sign, _ = pinfo(b)
            if not sign:
                continue
            rel = _relative_house(from_sign=moon_sign, to_sign=sign)
            if rel in upachaya:
                benefics_upachaya.append(b)
        if len(benefics_upachaya) >= 2:
            add(
                Yoga(
                    name="Vasumati Yoga",
                    category="Lunar",
                    description="Benefics in growth houses from the Moon are traditionally linked with comfort, resources, and steady gains over time.",
                    evidence={"benefics": sorted(benefics_upachaya), "fromMoonHouses": sorted(upachaya)},
                )
            )

    # Dharma-Karmadhipati Yoga: 9th lord + 10th lord association.
    lords = _house_lords(lagna_sign=lagna_sign)
    ninth = lords.get(9)
    tenth = lords.get(10)
    if ninth and tenth:
        # Find those planets in the chart.
        p9 = ninth.lower()
        p10 = tenth.lower()
        s9, lon9 = pinfo(p9)
        s10, lon10 = pinfo(p10)
        assoc = False
        assoc_type = None
        if lon9 is not None and lon10 is not None and _conjunct(lon1=lon9, lon2=lon10, orb_deg=10.0):
            assoc = True
            assoc_type = "conjunction"
        elif lon9 is not None and lon10 is not None and _mutual_aspect(p1=p9, lon1=lon9, p2=p10, lon2=lon10):
            assoc = True
            assoc_type = "mutual_aspect"
        else:
            # Parivartana (sign exchange).
            if s9 and s10:
                lord_of_s9 = VEDIC_SIGN_RULERS.get(s9)
                lord_of_s10 = VEDIC_SIGN_RULERS.get(s10)
                if lord_of_s9 == tenth and lord_of_s10 == ninth:
                    assoc = True
                    assoc_type = "exchange"
        if assoc:
            add(
                Yoga(
                    name="Dharma-Karmadhipati Yoga",
                    category="Raja Yoga",
                    description="A strong link between the 9th and 10th house lords is traditionally associated with purpose (dharma) supporting career (karma).",
                    evidence={"9th_lord": ninth, "10th_lord": tenth, "association": assoc_type},
                )
            )

    # Generic Raja Yogas: trikona lord + kendra lord association.
    trikona_lords = {house: lords.get(house) for house in sorted(_TRIKONA_HOUSES)}
    kendra_lords = {house: lords.get(house) for house in sorted(_KENDRA_HOUSES)}
    for t_house, t_lord in trikona_lords.items():
        if not t_lord:
            continue
        for k_house, k_lord in kendra_lords.items():
            if not k_lord or k_lord == t_lord:
                continue
            p_t = _planet_key_from_lord_name(t_lord)
            p_k = _planet_key_from_lord_name(k_lord)
            s_t, lon_t = pinfo(p_t)
            s_k, lon_k = pinfo(p_k)
            if lon_t is None or lon_k is None:
                continue
            assoc = None
            if _conjunct(lon1=lon_t, lon2=lon_k, orb_deg=10.0):
                assoc = "conjunction"
            elif _mutual_aspect(p1=p_t, lon1=lon_t, p2=p_k, lon2=lon_k):
                assoc = "mutual_aspect"
            else:
                if s_t and s_k:
                    lord_of_t = VEDIC_SIGN_RULERS.get(s_t)
                    lord_of_k = VEDIC_SIGN_RULERS.get(s_k)
                    if lord_of_t == k_lord and lord_of_k == t_lord:
                        assoc = "exchange"
            if assoc:
                add(
                    Yoga(
                        name="Raja Yoga",
                        category="Raja Yoga",
                        description="A link between a ‘purpose’ house lord (1/5/9) and a ‘pillar’ house lord (1/4/7/10) is traditionally read as supportive for growth and recognition.",
                        evidence={
                            "trikonaHouse": t_house,
                            "trikonaLord": t_lord,
                            "kendraHouse": k_house,
                            "kendraLord": k_lord,
                            "association": assoc,
                        },
                    )
                )

    # Viparita Raja Yoga: dusthana lords placed in dusthana houses (simplified).
    for from_house in sorted(_DUSTHANA_HOUSES):
        lord_name = lords.get(from_house)
        if not lord_name:
            continue
        p = _planet_key_from_lord_name(lord_name)
        sign, _lon = pinfo(p)
        if not sign:
            continue
        placed_house = _house_from_sign(lagna_sign=lagna_sign, sign=sign)
        if placed_house in _DUSTHANA_HOUSES and placed_house != from_house:
            add(
                Yoga(
                    name="Viparita Raja Yoga",
                    category="Raja Yoga",
                    description="When certain challenge-house lords land in other challenge houses, it’s traditionally read as ‘turning obstacles into advantage’ over time.",
                    evidence={"dusthanaLord": lord_name, "lordOfHouse": from_house, "placedInHouse": placed_house},
                )
            )

    # Dhana Yogas (simplified).
    second_lord = lords.get(2)
    eleventh_lord = lords.get(11)
    if second_lord and eleventh_lord:
        p2 = _planet_key_from_lord_name(second_lord)
        p11 = _planet_key_from_lord_name(eleventh_lord)
        s2, lon2 = pinfo(p2)
        s11, lon11 = pinfo(p11)
        assoc = None
        if lon2 is not None and lon11 is not None and _conjunct(lon1=lon2, lon2=lon11, orb_deg=10.0):
            assoc = "conjunction"
        elif lon2 is not None and lon11 is not None and _mutual_aspect(p1=p2, lon1=lon2, p2=p11, lon2=lon11):
            assoc = "mutual_aspect"
        elif s2 and s11:
            lord_s2 = VEDIC_SIGN_RULERS.get(s2)
            lord_s11 = VEDIC_SIGN_RULERS.get(s11)
            if lord_s2 == eleventh_lord and lord_s11 == second_lord:
                assoc = "exchange"
        if assoc:
            add(
                Yoga(
                    name="Dhana Yoga",
                    category="Wealth",
                    description="A link between the 2nd (resources) and 11th (gains) lords is traditionally associated with better earning/growth potential.",
                    evidence={"2ndLord": second_lord, "11thLord": eleventh_lord, "association": assoc},
                )
            )

    # Lakshmi Yoga (simplified): 9th lord in kendra/trikona + Venus strong.
    ninth_lord = lords.get(9)
    venus_sign, _venus_lon = pinfo("venus")
    if ninth_lord and venus_sign:
        p9 = _planet_key_from_lord_name(ninth_lord)
        sign9, _ = pinfo(p9)
        if sign9:
            h9 = _house_from_sign(lagna_sign=lagna_sign, sign=sign9)
            hvenus = _house_from_sign(lagna_sign=lagna_sign, sign=venus_sign)
            venus_ok, venus_dignity = _is_own_or_exalted("Venus", venus_sign)
            if h9 in (_KENDRA_HOUSES | _TRIKONA_HOUSES) and hvenus in (_KENDRA_HOUSES | _TRIKONA_HOUSES) and venus_ok:
                add(
                    Yoga(
                        name="Lakshmi Yoga",
                        category="Prosperity",
                        description="A traditional prosperity yoga combining strong fortune indicators (9th house) with a strong Venus (comfort, harmony).",
                        evidence={
                            "9thLord": ninth_lord,
                            "9thLordHouse": h9,
                            "venusHouse": hvenus,
                            "venusDignity": venus_dignity,
                        },
                    )
                )

    return [y.__dict__ for y in yogas]
