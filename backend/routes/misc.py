from datetime import datetime
from fastapi import APIRouter, Query

from ..services.ephemeris_service import get_planetary_positions

router = APIRouter()


@router.get("/planetary-positions")
async def planetary_positions(dt: str | None = Query(default=None, description="ISO datetime")):
    """Return planetary positions as zodiac sign and degree."""
    date = datetime.fromisoformat(dt) if dt else None
    data = get_planetary_positions(date)
    return data
