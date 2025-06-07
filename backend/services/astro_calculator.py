from __future__ import annotations

from datetime import datetime
from typing import Dict, Any

from .ephemeris_service import get_planetary_positions


class AstroCalculator:
    """Simple wrapper around ephemeris calculations."""

    def get_positions(self, dt: datetime | None = None) -> Dict[str, Dict[str, Any]]:
        """Return planetary positions for the given datetime."""
        return get_planetary_positions(dt)
