from __future__ import annotations

from datetime import datetime
from fastapi import APIRouter, Query, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from services.astro_calculator import AstroCalculator
from services.claude_ai import ClaudeService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
calculator = AstroCalculator()
claude = ClaudeService()
cloudkit = CloudKitService()

VALID_SIGNS = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
]

@router.get("")
@limiter.limit("50/hour")
async def horoscope(
    request: Request,
    sign: str = Query(default='aries', description="Zodiac sign"),
    date: str = Query(default=None, description="Date in YYYY-MM-DD format"),
    type: str = Query(default='daily', description="Horoscope type")
):
    sign = sign.lower()
    
    if sign not in VALID_SIGNS:
        raise HTTPException(status_code=400, detail='Invalid zodiac sign')
    
    date_str = date
    type_ = type.lower()

    if date_str:
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            raise HTTPException(status_code=400, detail='Invalid date format, use YYYY-MM-DD')
    else:
        dt = datetime.utcnow()
        date_str = dt.strftime('%Y-%m-%d')

    cache_key = f"horoscope:{sign}:{date_str}:{type_}"
    cached = cache.get(cache_key)
    if cached:
        return cached

    stored = cloudkit.get_horoscope(sign, date_str, type_)
    if stored:
        cache.set(cache_key, stored, timeout=3600)
        return stored

    positions = calculator.get_positions(dt)
    position_lines = [
        f"{planet.title()}: {info['sign']} {info['degree']}" for planet, info in positions.items()
    ]
    prompt = (
        f"Generate a {type_} horoscope for the sign {sign.capitalize()} on {date_str}.\n"
        "Use the following planetary positions:\n" + "\n".join(position_lines)
    )
    try:
        content = claude.generate_content(prompt, max_tokens=300)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    result = {'sign': sign, 'date': date_str, 'type': type_, 'horoscope': content}
    cache.set(cache_key, result, timeout=3600)
    cloudkit.save_horoscope(result)
    return result
