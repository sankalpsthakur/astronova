"""Divisional chart helpers (Varga charts).

For now we implement the most-requested charts for reports:
- D9 (Navamsa): partnership/marriage + inner strength
- D10 (Dasamsa): career/public contribution
"""

from __future__ import annotations

from .constants import VEDIC_SIGNS

_NAVAMSA_SPAN = 30.0 / 9.0  # 3°20'


def _navamsa_sign_index(*, sign_index: int, degree_in_sign: float) -> int:
    pada0 = int(float(degree_in_sign) / _NAVAMSA_SPAN)  # 0..8
    element_group = sign_index % 4  # Fire/Earth/Air/Water sequence in zodiac
    # Starting navamsa signs for the element group:
    # Fire -> Aries, Earth -> Capricorn, Air -> Libra, Water -> Cancer
    starting = [0, 9, 6, 3][element_group]
    return (starting + pada0) % 12


def _dasamsa_sign_index(*, sign_index: int, degree_in_sign: float) -> int:
    segment0 = int(float(degree_in_sign) / 3.0)  # 0..9
    # Odd signs (Aries=1) correspond to index%2==0.
    is_odd = (sign_index % 2) == 0
    start = sign_index if is_odd else (sign_index + 8) % 12  # 9th sign from even signs
    return (start + segment0) % 12


def compute_d9_d10(*, planets_by_name: dict[str, dict]) -> dict[str, dict]:
    """Return D9/D10 sign placements for each planet based on sidereal sign+degree."""
    d9: dict[str, dict] = {}
    d10: dict[str, dict] = {}

    for planet, info in planets_by_name.items():
        if planet == "ascendant":
            continue
        try:
            lon = float(info.get("longitude"))
        except Exception:
            continue
        sign_index = int((lon % 360.0) // 30) % 12
        deg_in_sign = (lon % 30.0)
        d9_idx = _navamsa_sign_index(sign_index=sign_index, degree_in_sign=deg_in_sign)
        d10_idx = _dasamsa_sign_index(sign_index=sign_index, degree_in_sign=deg_in_sign)
        d9[planet] = {"sign": VEDIC_SIGNS[d9_idx]}
        d10[planet] = {"sign": VEDIC_SIGNS[d10_idx]}

    return {"D9": d9, "D10": d10}

