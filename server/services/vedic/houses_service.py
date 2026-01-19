"""Whole-sign house helpers for Vedic charts."""

from __future__ import annotations

from .constants import HOUSE_MEANINGS, VEDIC_SIGN_INDEX, VEDIC_SIGN_RULERS, VEDIC_SIGNS


def house_number_for_sign(*, lagna_sign: str, planet_sign: str) -> int | None:
    lagna_idx = VEDIC_SIGN_INDEX.get(lagna_sign)
    planet_idx = VEDIC_SIGN_INDEX.get(planet_sign)
    if lagna_idx is None or planet_idx is None:
        return None
    return ((planet_idx - lagna_idx) % 12) + 1


def build_whole_sign_houses(*, lagna_sign: str, planets_by_name: dict[str, dict]) -> dict[str, dict]:
    """Build a Vedic whole-sign house map (1..12)."""
    lagna_idx = VEDIC_SIGN_INDEX.get(lagna_sign, 0)

    house_planets: dict[int, list[str]] = {i: [] for i in range(1, 13)}
    for planet, info in planets_by_name.items():
        if planet == "ascendant":
            continue
        sign = str(info.get("sign", ""))
        house = house_number_for_sign(lagna_sign=lagna_sign, planet_sign=sign)
        if house is None:
            continue
        house_planets[house].append(planet)

    houses: dict[str, dict] = {}
    for house_num in range(1, 13):
        sign = VEDIC_SIGNS[(lagna_idx + house_num - 1) % 12]
        houses[str(house_num)] = {
            "house": house_num,
            "sign": sign,
            "lord": VEDIC_SIGN_RULERS.get(sign),
            "meaning": HOUSE_MEANINGS.get(house_num, ""),
            "planets": sorted(house_planets.get(house_num, [])),
        }
    return houses

