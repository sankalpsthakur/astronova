import datetime as _dt
from typing import Dict

from .ephemeris_service import get_planetary_positions

AYANAMSA_OFFSET = 24  # rough offset for Vedic calculations

class AstroCalculator:
    """Simple wrapper around ephemeris calculations."""

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
