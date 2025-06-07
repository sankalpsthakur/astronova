from __future__ import annotations

import datetime as _dt
from dataclasses import dataclass
from datetime import datetime
from zoneinfo import ZoneInfo
from typing import Dict, List

from .chart_service import calculate_positions, compute_aspects, PLANETS
from .ephemeris_service import get_planetary_positions

AYANAMSA_OFFSET = 24  # rough offset for Vedic calculations

ZODIAC_SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]

CHINESE_SIGNS = [
    "Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
    "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"
]

@dataclass
class BirthData:
    date: str
    time: str
    timezone: str
    latitude: float
    longitude: float

class AstroCalculator:
    """Utility class for basic astrology calculations."""

    def western_chart(self, dt: _dt.datetime) -> Dict[str, Dict[str, float]]:
        """Return planetary positions for a western chart."""
        return get_planetary_positions(dt)

    def vedic_chart(self, dt: _dt.datetime) -> Dict[str, Dict[str, float]]:
        """Return positions adjusted for Vedic astrology."""
        positions = get_planetary_positions(dt)
        for info in positions.values():
            deg = (info["degree"] - AYANAMSA_OFFSET) % 30
            info["degree"] = round(deg, 2)
        return positions

    @staticmethod
    def _to_datetime(data: BirthData) -> datetime:
        dt = datetime.fromisoformat(f"{data.date}T{data.time}")
        return dt.replace(tzinfo=ZoneInfo(data.timezone))

    @staticmethod
    def calculate_birth_chart(data: BirthData) -> Dict[str, Dict[str, str]]:
        """Return planetary positions for the given birth data."""
        dt = AstroCalculator._to_datetime(data)
        positions = calculate_positions(dt, data.latitude, data.longitude)
        chart = {}
        for planet, lon in positions.items():
            sign_index = int(lon // 30) % 12
            sign = ZODIAC_SIGNS[sign_index]
            degree = round(lon % 30, 2)
            chart[planet] = {"sign": sign, "degree": str(degree)}
        return chart

    @staticmethod
    def synastry_aspects(chart1: Dict[str, Dict[str, str]], chart2: Dict[str, Dict[str, str]]) -> List[Dict[str, float]]:
        pos1 = {p: float(c["degree"]) + ZODIAC_SIGNS.index(c["sign"]) * 30 for p, c in chart1.items()}
        pos2 = {p: float(c["degree"]) + ZODIAC_SIGNS.index(c["sign"]) * 30 for p, c in chart2.items()}
        return compute_aspects(pos1, pos2)

    @staticmethod
    def chinese_zodiac_sign(year: int) -> str:
        return CHINESE_SIGNS[year % 12]

    @staticmethod
    def chinese_compatibility(year1: int, year2: int) -> int:
        diff = abs(year1 - year2) % 12
        score = int((12 - diff) / 12 * 100)
        return score

    @staticmethod
    def vedic_compatibility(year1: int, year2: int) -> int:
        diff = abs(year1 - year2)
        score = max(0, 36 - diff % 36)
        return score
