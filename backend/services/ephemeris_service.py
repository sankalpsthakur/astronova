import datetime
from datetime import datetime
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

try:
    import swisseph as swe
    SWE_AVAILABLE = True
except ImportError:
    logger.warning("Swiss Ephemeris not available. Using fallback calculations.")
    SWE_AVAILABLE = False
    swe = None

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
    "sun": swe.SUN if SWE_AVAILABLE else 0,
    "moon": swe.MOON if SWE_AVAILABLE else 1,
    "mercury": swe.MERCURY if SWE_AVAILABLE else 2,
    "venus": swe.VENUS if SWE_AVAILABLE else 3,
    "mars": swe.MARS if SWE_AVAILABLE else 4,
    "jupiter": swe.JUPITER if SWE_AVAILABLE else 5,
    "saturn": swe.SATURN if SWE_AVAILABLE else 6,
    "uranus": swe.URANUS if SWE_AVAILABLE else 7,
    "neptune": swe.NEPTUNE if SWE_AVAILABLE else 8,
    "pluto": swe.PLUTO if SWE_AVAILABLE else 9,
}

def _julian_day(dt: datetime) -> float:
    """Convert datetime to Julian Day."""
    if SWE_AVAILABLE:
        return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)
    else:
        # Simple Julian Day calculation for fallback
        a = (14 - dt.month) // 12
        y = dt.year + 4800 - a
        m = dt.month + 12 * a - 3
        jdn = dt.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
        return jdn + (dt.hour - 12) / 24.0 + dt.minute / 1440.0 + dt.second / 86400.0

def _calculate_rising_sign(dt: datetime, lat: float, lon: float) -> Dict[str, Any]:
    """Calculate rising sign (ascendant) using Swiss Ephemeris."""
    if SWE_AVAILABLE:
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
    else:
        # Simplified fallback calculation
        # This is a very rough approximation and should not be used for serious astrology
        hour_angle = (dt.hour + dt.minute / 60.0) * 15.0  # Convert to degrees
        base_asc = (hour_angle + lon) % 360
        
        # Adjust for latitude (rough approximation)
        lat_factor = abs(lat) / 90.0
        adjusted_asc = (base_asc + lat_factor * 30) % 360
        
        sign_index = int(adjusted_asc // 30) % 12
        degree = adjusted_asc % 30
        
        return {
            "sign": ZODIAC_SIGNS[sign_index],
            "degree": round(degree, 2),
            "longitude": round(adjusted_asc, 2)
        }

class EphemerisService:
    def get_current_positions(self, lat: Optional[float] = None, lon: Optional[float] = None):
        """Get current planetary positions using Swiss Ephemeris."""
        dt = datetime.utcnow()
        return self.get_positions_for_date(dt, lat, lon)

    def get_positions_for_date(self, dt: datetime, lat: Optional[float] = None, lon: Optional[float] = None):
        """Get planetary positions for specific date using Swiss Ephemeris."""
        positions = {}
        
        if SWE_AVAILABLE:
            jd = _julian_day(dt)
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
        else:
            # Fallback calculations when Swiss Ephemeris is not available
            # These are simplified approximations
            day_of_year = dt.timetuple().tm_yday
            year_progress = day_of_year / 365.25
            
            # Approximate positions based on average speeds
            planet_speeds = {
                "sun": 1.0,  # ~1 degree per day
                "moon": 13.2,  # ~13.2 degrees per day
                "mercury": 1.6,
                "venus": 1.2,
                "mars": 0.52,
                "jupiter": 0.08,
                "saturn": 0.03,
                "uranus": 0.01,
                "neptune": 0.006,
                "pluto": 0.004
            }
            
            for name in PLANETS.keys():
                # Calculate approximate position
                base_pos = (year_progress * 360 * planet_speeds.get(name, 1.0)) % 360
                
                # Add some variation based on planet
                if name == "moon":
                    base_pos = (base_pos + dt.day * 13.2) % 360
                elif name == "mercury":
                    base_pos = (base_pos + dt.day * 1.6) % 360
                
                sign_index = int(base_pos // 30) % 12
                degree = base_pos % 30
                
                positions[name] = {
                    "sign": ZODIAC_SIGNS[sign_index],
                    "degree": round(degree, 2),
                    "longitude": round(base_pos, 2),
                    "retrograde": False  # No retrograde in fallback
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
