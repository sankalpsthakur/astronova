"""Dosha checks (report-friendly subset)."""

from __future__ import annotations

from .constants import VEDIC_SIGN_INDEX


_MANGALIK_HOUSES = {1, 4, 7, 8, 12}


def _house_from_sign(*, reference_sign: str, target_sign: str) -> int | None:
    ref = VEDIC_SIGN_INDEX.get(reference_sign)
    tgt = VEDIC_SIGN_INDEX.get(target_sign)
    if ref is None or tgt is None:
        return None
    return ((tgt - ref) % 12) + 1


def manglik_status(*, lagna_sign: str, moon_sign: str, venus_sign: str, mars_sign: str) -> dict[str, object]:
    from_lagna = _house_from_sign(reference_sign=lagna_sign, target_sign=mars_sign)
    from_moon = _house_from_sign(reference_sign=moon_sign, target_sign=mars_sign)
    from_venus = _house_from_sign(reference_sign=venus_sign, target_sign=mars_sign)

    flags = {
        "fromLagna": from_lagna in _MANGALIK_HOUSES if from_lagna else False,
        "fromMoon": from_moon in _MANGALIK_HOUSES if from_moon else False,
        "fromVenus": from_venus in _MANGALIK_HOUSES if from_venus else False,
    }
    severity = sum(1 for v in flags.values() if v)
    label = "Not Manglik"
    if severity == 1:
        label = "Mild Manglik"
    elif severity == 2:
        label = "Moderate Manglik"
    elif severity >= 3:
        label = "Strong Manglik"

    return {
        "label": label,
        "checks": flags,
        "explainLikeImFive": (
            "Manglik is a traditional check that looks at where Mars sits from key reference points (Lagna/Moon/Venus). "
            "It’s commonly used in matchmaking; it’s not a deterministic ‘good/bad’ label."
        ),
    }


def kalsarpa_status(*, longitudes: dict[str, float], lagna_sign: str | None = None) -> dict[str, object]:
    """Kalsarpa: all planets hemmed between Rahu and Ketu (inclusive) in a half-zodiac arc."""
    rahu = longitudes.get("rahu")
    ketu = longitudes.get("ketu")
    if rahu is None or ketu is None:
        return {"present": False, "reason": "Rahu/Ketu missing"}

    r = float(rahu) % 360.0
    k = float(ketu) % 360.0
    # Normalize to Rahu=0 frame.
    rel_k = (k - r) % 360.0
    # Expect ~180°.
    half = rel_k
    if half <= 0:
        half = 180.0

    planets_to_check = [p for p in longitudes.keys() if p not in {"rahu", "ketu", "ascendant"}]
    rels = {p: (float(longitudes[p]) - r) % 360.0 for p in planets_to_check if p in longitudes}

    within_first_half = all(0.0 <= rel <= half for rel in rels.values())
    within_second_half = all(rel >= half for rel in rels.values())

    present = within_first_half or within_second_half
    result: dict[str, object] = {
        "present": bool(present),
        "explainLikeImFive": (
            "Kalsarpa is a traditional pattern check: if most planets fall on one side of the Rahu–Ketu axis, "
            "the chart is said to have a ‘hemmed in’ feel in certain life areas."
        ),
    }
    if not present:
        return result

    rahu_house = None
    if lagna_sign:
        ref = VEDIC_SIGN_INDEX.get(lagna_sign)
        r_sign = int((r // 30) % 12)
        if ref is not None:
            rahu_house = ((r_sign - ref) % 12) + 1

    type_by_house = {
        1: "Anant",
        2: "Kulik",
        3: "Vasuki",
        4: "Shankhpal",
        5: "Padma",
        6: "Mahapadma",
        7: "Takshak",
        8: "Karkotak",
        9: "Shankachood",
        10: "Ghatak",
        11: "Vishdhar",
        12: "Sheshnag",
    }

    result["type"] = type_by_house.get(rahu_house) if rahu_house else None
    result["rahuHouse"] = rahu_house
    return result

