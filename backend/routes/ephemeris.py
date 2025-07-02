from flask import Blueprint, jsonify, request
from services.ephemeris_service import EphemerisService
from datetime import datetime

ephemeris_bp = Blueprint('ephemeris', __name__)
service = EphemerisService()


@ephemeris_bp.route('/current', methods=['GET'])
def current_positions():
    """
    Get current planetary positions for iOS app.
    Optional query parameters:
    - lat: latitude for rising sign calculation
    - lon: longitude for rising sign calculation
    """
    try:
        # Get optional location parameters for rising sign
        lat = request.args.get('lat', type=float)
        lon = request.args.get('lon', type=float)
        
        positions_data = service.get_current_positions(lat=lat, lon=lon)
        
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
        
        return jsonify({
            "planets": planets,
            "timestamp": datetime.now().isoformat(),
            "has_rising_sign": lat is not None and lon is not None
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to get current positions: {str(e)}'}), 500

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
        'pluto': '♇',
        'ascendant': '⟰'
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
        'pluto': 'Transformation and power',
        'ascendant': 'Rising sign and outer personality'
    }
    return significance.get(planet_name.lower(), 'Cosmic influence')
