from __future__ import annotations

import datetime as _dt
from dataclasses import dataclass

ANIMALS = [
    "Rat",
    "Ox",
    "Tiger",
    "Rabbit",
    "Dragon",
    "Snake",
    "Horse",
    "Goat",
    "Monkey",
    "Rooster",
    "Dog",
    "Pig",
]

ELEMENTS = ["Wood", "Fire", "Earth", "Metal", "Water"]

@dataclass
class ChineseChart:
    animal: str
    element: str
    year: int

class ChineseAstrologyService:
    """Very small Chinese astrology helper."""

    def chart_for_date(self, date: _dt.date) -> ChineseChart:
        year = date.year
        animal = ANIMALS[(year - 4) % 12]
        element = ELEMENTS[((year - 4) // 2) % 5]
        return ChineseChart(animal=animal, element=element, year=year)
