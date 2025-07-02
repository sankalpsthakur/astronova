import datetime
from datetime import datetime
from typing import Dict, Any, Optional
import swisseph as swe

from .cache_service import cache

ZODIAC_SIGNS = [
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
]

PLANETS = {
    "sun": swe.SUN,
    "moon": swe.MOON,
    "mercury": swe.MERCURY,
    "venus": swe.VENUS,
    "mars": swe.MARS,
    "jupiter": swe.JUPITER,
    "saturn": swe.SATURN,
    "uranus": swe.URANUS,
    "neptune": swe.NEPTUNE,
    "pluto": swe.PLUTO,
}

def _julian_day(dt: datetime) -> float:
    """Convert datetime to Julian Day."""
    return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)

def _calculate_rising_sign(dt: datetime, lat: float, lon: float) -> Dict[str, Any]:
    """Calculate rising sign (ascendant) using Swiss Ephemeris."""
    jd = _julian_day(dt)
    # Calculate houses using Placidus system (most common)
    houses, ascmc = swe.houses(jd, lat, lon, b'P')
    
    # Ascendant is the first value in ascmc array
    ascendant_lon = ascmc[0]
    sign_index = int(ascendant_lon // 30) % 12
    degree = ascendant_lon % 30
    
    return {
        "sign": ZODIAC_SIGNS[sign_index],
        "degree": round(degree, 2),
        "longitude": round(ascendant_lon, 2)
    }

class EphemerisService:
    def get_current_positions(self, lat: Optional[float] = None, lon: Optional[float] = None):
        """Get current planetary positions using Swiss Ephemeris."""
        dt = datetime.utcnow()
        return self.get_positions_for_date(dt, lat, lon)

    def get_positions_for_date(self, dt: datetime, lat: Optional[float] = None, lon: Optional[float] = None):
        """Get planetary positions for specific date using Swiss Ephemeris."""
        jd = _julian_day(dt)
        positions = {}
        
        for name, planet_code in PLANETS.items():
            try:
                result = swe.calc_ut(jd, planet_code)
                # Extract longitude - result[0] is a tuple (longitude, latitude, distance, ...)
                lon_deg = result[0][0] if isinstance(result[0], (tuple, list)) else result[0]
                
                sign_index = int(lon_deg // 30) % 12
                degree = lon_deg % 30
                
                # Extract speed for retrograde calculation
                speed = result[0][3] if isinstance(result[0], (tuple, list)) and len(result[0]) > 3 else 1.0
                
                positions[name] = {
                    "sign": ZODIAC_SIGNS[sign_index],
                    "degree": round(degree, 2),
                    "longitude": round(lon_deg, 2),
                    "retrograde": speed < 0
                }
            except Exception as e:
                # Fallback for any calculation errors
                positions[name] = {
                    "sign": "Unknown",
                    "degree": 0.0,
                    "longitude": 0.0,
                    "retrograde": False
                }
        
        # Add rising sign if location provided
        if lat is not None and lon is not None:
            try:
                positions["ascendant"] = _calculate_rising_sign(dt, lat, lon)
            except Exception:
                positions["ascendant"] = {
                    "sign": "Unknown",
                    "degree": 0.0,
                    "longitude": 0.0
                }
        
        return {"planets": positions}

def get_planetary_positions(dt: datetime | None = None) -> Dict[str, Dict[str, Any]]:
    """Return zodiac sign and degree for major planets at the given datetime."""
    if dt is None:
        dt = datetime.utcnow()
    
    service = EphemerisService()
    result = service.get_positions_for_date(dt)
    return result.get("planets", {})
