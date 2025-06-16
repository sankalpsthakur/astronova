from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from services.ephemeris_service import EphemerisService
from datetime import datetime

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
service = EphemerisService()


@router.get('/current')
@limiter.limit("100/hour")
async def current_positions(request: Request):
    """
    Get current planetary positions for iOS app
    """
    try:
        positions_data = service.get_current_positions()
        
        # Transform data for iOS app format
        planets = []
        if 'planets' in positions_data:
            for planet_name, planet_data in positions_data['planets'].items():
                planet_entry = {
                    "id": planet_name.lower(),
                    "symbol": get_planet_symbol(planet_name),
                    "name": planet_name.title(),
                    "sign": planet_data.get('sign', 'Unknown'),
                    "degree": planet_data.get('degree', 0.0),
                    "retrograde": planet_data.get('retrograde', False),
                    "house": planet_data.get('house'),
                    "significance": get_planet_significance(planet_name)
                }
                planets.append(planet_entry)
        
        return {
            "planets": planets,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Failed to get current positions: {str(e)}')

def get_planet_symbol(planet_name: str) -> str:
    """Get the symbol for a planet"""
    symbols = {
        'sun': '☉',
        'moon': '☽', 
        'mercury': '☿',
        'venus': '♀',
        'mars': '♂',
        'jupiter': '♃',
        'saturn': '♄',
        'uranus': '♅',
        'neptune': '♆',
        'pluto': '♇'
    }
    return symbols.get(planet_name.lower(), '⭐')

def get_planet_significance(planet_name: str) -> str:
    """Get the significance description for a planet"""
    significance = {
        'sun': 'Core identity and vitality',
        'moon': 'Emotions and intuition',
        'mercury': 'Communication and thinking',
        'venus': 'Love and values',
        'mars': 'Energy and action',
        'jupiter': 'Growth and wisdom',
        'saturn': 'Structure and discipline',
        'uranus': 'Innovation and change',
        'neptune': 'Dreams and spirituality',
        'pluto': 'Transformation and power'
    }
    return significance.get(planet_name.lower(), 'Cosmic influence')