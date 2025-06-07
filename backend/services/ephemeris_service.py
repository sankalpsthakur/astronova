from datetime import datetime
from typing import Dict, Any

from astroquery.jplhorizons import Horizons
from astropy.time import Time
from astropy.coordinates import SkyCoord, GeocentricTrueEcliptic
import astropy.units as u

from .cache import cache

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

# JPL Horizons IDs for major solar system bodies
PLANET_IDS = {
    "sun": "10",
    "moon": "301",
    "mercury": "199",
    "venus": "299",
    "mars": "499",
    "jupiter": "599",
    "saturn": "699",
    "uranus": "799",
    "neptune": "899",
    "pluto": "999",
}


@cache(maxsize=32)
def get_planetary_positions(dt: datetime | None = None) -> Dict[str, Dict[str, Any]]:
    """Return zodiac sign and degree for major planets at the given datetime."""
    if dt is None:
        dt = datetime.utcnow()

    time = Time(dt)
    positions: Dict[str, Dict[str, Any]] = {}

    for name, pid in PLANET_IDS.items():
        obj = Horizons(id=pid, location="500", epochs=time.jd)
        eph = obj.ephemerides()

        ra = eph["RA"][0] * u.deg
        dec = eph["DEC"][0] * u.deg
        coord = SkyCoord(ra=ra, dec=dec, frame="icrs", obstime=time)
        ecl = coord.transform_to(GeocentricTrueEcliptic(equinox=time))
        lon = float(ecl.lon.wrap_at(360 * u.deg).deg)

        sign_index = int(lon // 30)
        sign = ZODIAC_SIGNS[sign_index]
        degree = lon % 30

        positions[name] = {
            "sign": sign,
            "degree": round(degree, 2),
        }

    return positions
