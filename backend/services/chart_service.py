from datetime import datetime
from typing import Dict, List

import swisseph as swe

# Map planet names to Swiss Ephemeris constants
PLANETS = {
    'sun': swe.SUN,
    'moon': swe.MOON,
    'mercury': swe.MERCURY,
    'venus': swe.VENUS,
    'mars': swe.MARS,
    'jupiter': swe.JUPITER,
    'saturn': swe.SATURN,
    'uranus': swe.URANUS,
    'neptune': swe.NEPTUNE,
    'pluto': swe.PLUTO,
}

ASPECTS = {
    'conjunction': 0,
    'sextile': 60,
    'square': 90,
    'trine': 120,
    'opposition': 180,
}

DEFAULT_ORB = 6.0


def _julian_day(dt: datetime) -> float:
    """Convert naive datetime to Julian Day."""
    return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)


def calculate_positions(dt: datetime, lat: float, lon: float) -> Dict[str, float]:
    """Calculate planetary longitudes for given datetime and location."""
    swe.set_topo(lon, lat, 0)
    jd = _julian_day(dt)
    positions = {}
    for name, code in PLANETS.items():
        result = swe.calc_ut(jd, code)
        if len(result) >= 2:
            lon, lat = result[0], result[1]
        else:
            lon = result[0] if result else 0.0
        positions[name] = lon  # ecliptic longitude in degrees
    return positions


def compute_aspects(chart1: Dict[str, float], chart2: Dict[str, float], orb: float = DEFAULT_ORB) -> List[Dict[str, float]]:
    """Compute major aspects between two charts.

    Returns a list of dictionaries with planet1, planet2, aspect name and orb.
    """
    results = []
    for p1, lon1 in chart1.items():
        for p2, lon2 in chart2.items():
            diff = abs((lon1 - lon2 + 180) % 360 - 180)
            for name, angle in ASPECTS.items():
                delta = abs(diff - angle)
                if delta <= orb:
                    results.append({
                        'planet1': p1,
                        'planet2': p2,
                        'aspect': name,
                        'orb': round(delta, 2),
                    })
    return results
