"""Panchang calculations (Tithi, Karana, Yoga) for a moment in time."""

from __future__ import annotations

from dataclasses import dataclass

from .constants import KARANA_FIXED, KARANA_MOVABLE, TITHI_NAMES, YOGA_NAMES


@dataclass(frozen=True)
class TithiInfo:
    number: int  # 1..30
    paksha: str  # Shukla / Krishna
    name: str
    percent_complete: float


@dataclass(frozen=True)
class KaranaInfo:
    half_index: int  # 0..59
    name: str


@dataclass(frozen=True)
class YogaInfo:
    number: int  # 1..27
    name: str


def calculate_panchang(*, sun_longitude: float, moon_longitude: float) -> dict[str, object]:
    """Return panchang data using ecliptic longitudes (sidereal or tropical).

    Note: Tithi/Yoga depend on relative Sun–Moon geometry; if both are sidereal,
    the ayanamsha cancels and the result remains stable.
    """

    sun_lon = float(sun_longitude) % 360.0
    moon_lon = float(moon_longitude) % 360.0

    # Tithi = (Moon - Sun) / 12° (0..30)
    diff = (moon_lon - sun_lon) % 360.0
    tithi_float = diff / 12.0
    tithi_number = int(tithi_float) + 1  # 1..30
    tithi_number = max(1, min(tithi_number, 30))

    paksha = "Shukla" if tithi_number <= 15 else "Krishna"
    in_paksha = tithi_number if tithi_number <= 15 else tithi_number - 15
    base_name = TITHI_NAMES[in_paksha - 1]
    if in_paksha == 15:
        base_name = "Purnima" if paksha == "Shukla" else "Amavasya"

    tithi_percent = (tithi_float - int(tithi_float)) * 100.0

    # Karana = half-tithi
    half_index = int(tithi_float * 2.0)  # 0..59
    half_index = max(0, min(half_index, 59))
    if half_index in KARANA_FIXED:
        karana_name = KARANA_FIXED[half_index]
    else:
        karana_name = KARANA_MOVABLE[(half_index - 1) % 7]

    # Yoga = (Sun + Moon) / 13°20' (0..27)
    yoga_float = ((sun_lon + moon_lon) % 360.0) / (360.0 / 27.0)
    yoga_number = int(yoga_float) + 1
    yoga_number = max(1, min(yoga_number, 27))
    yoga_name = YOGA_NAMES[yoga_number - 1]

    return {
        "tithi": TithiInfo(
            number=tithi_number,
            paksha=paksha,
            name=f"{paksha} {base_name}",
            percent_complete=round(tithi_percent, 2),
        ).__dict__,
        "karana": KaranaInfo(half_index=half_index, name=karana_name).__dict__,
        "yoga": YogaInfo(number=yoga_number, name=yoga_name).__dict__,
        "explainLikeImFive": {
            "tithi": "A lunar day (based on how far the Moon is from the Sun).",
            "karana": "Half of a tithi (used for timing; mostly a repeating cycle).",
            "yoga": "A combined Sun+Moon pattern (a 27-part cycle used in panchang).",
        },
    }
