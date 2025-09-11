from flask import Blueprint, jsonify, request
from services.ephemeris_service import EphemerisService
try:
    from services.ephemeris_service import SWE_AVAILABLE, swe as _swe
except Exception:  # pragma: no cover
    SWE_AVAILABLE = False
    _swe = None
from datetime import datetime

ephemeris_bp = Blueprint('ephemeris', __name__)
service = EphemerisService()

@ephemeris_bp.route('', methods=['GET'])
def ephemeris_info():
    """Get ephemeris service information"""
    return jsonify({
        'service': 'ephemeris',
        'status': 'available',
        'endpoints': {
            'GET /current': 'Get current planetary positions'
        }
    })


VEDIC_SIGNS = [
    "Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya",
    "Tula", "Vrischika", "Dhanu", "Makara", "Kumbha", "Meena"
]


def _compute_positions(dt: datetime, lat: float | None, lon: float | None, system: str = 'western'):
    """Compute planetary positions, optionally in sidereal (vedic) mode."""
    system = (system or 'western').lower()
    use_vedic = system in ('vedic', 'sidereal')

    positions = {}
    if SWE_AVAILABLE and _swe is not None:
        try:
            if use_vedic:
                _swe.set_sid_mode(_swe.SIDM_LAHIRI, 0, 0)
            jd = _swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)
            for name, planet_code in EphemerisService.PLANETS.items() if hasattr(EphemerisService, 'PLANETS') else {
                'sun': _swe.SUN, 'moon': _swe.MOON, 'mercury': _swe.MERCURY, 'venus': _swe.VENUS,
                'mars': _swe.MARS, 'jupiter': _swe.JUPITER, 'saturn': _swe.SATURN, 'uranus': _swe.URANUS,
                'neptune': _swe.NEPTUNE, 'pluto': _swe.PLUTO
            }.items():
                flags = _swe.FLG_SIDEREAL if use_vedic else 0
                xx, _ = _swe.calc_ut(jd, planet_code, flags)
                lon_deg = float(xx[0])
                sign_index = int(lon_deg // 30) % 12
                degree = lon_deg % 30
                positions[name] = {
                    'sign': (VEDIC_SIGNS if use_vedic else EphemerisService.ZODIAC_SIGNS)[sign_index] if hasattr(EphemerisService, 'ZODIAC_SIGNS') else (VEDIC_SIGNS if use_vedic else [
                        "Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
                    ])[sign_index],
                    'degree': round(degree, 2),
                    'longitude': round(lon_deg, 2),
                    'retrograde': bool(xx[3] < 0) if len(xx) > 3 else False
                }
        except Exception:
            positions = None  # Falls back below

    if not positions:
        # Fallback: use service (tropical) and approximate sidereal by subtracting Lahiri ayanamsha ~24°
        base = service.get_positions_for_date(dt, lat, lon).get('planets', {})
        AYAN = 24.0  # rough constant; acceptable for minimal fallback
        for k, v in base.items():
            lon_deg = float(v.get('longitude', 0.0))
            if use_vedic:
                lon_deg = (lon_deg - AYAN) % 360
                sign_index = int(lon_deg // 30) % 12
                degree = lon_deg % 30
                sign_name = VEDIC_SIGNS[sign_index]
            else:
                sign_name = v.get('sign', 'Unknown')
                degree = float(v.get('degree', 0.0))
            positions[k] = {
                'sign': sign_name,
                'degree': round(degree, 2),
                'longitude': round(lon_deg, 2),
                'retrograde': bool(v.get('retrograde', False))
            }
    return positions


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
        system = (request.args.get('system') or 'western').lower()
        positions = _compute_positions(datetime.utcnow(), lat, lon, system)

        # Transform data for iOS app format
        planets = []
        for planet_name, planet_data in positions.items():
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


@ephemeris_bp.route('/at', methods=['GET'])
def positions_at_date():
    """
    Get planetary positions for a specific date (UTC).
    Query parameters:
    - date: YYYY-MM-DD (required)
    - lat: optional latitude
    - lon: optional longitude
    """
    try:
        date_str = request.args.get('date')
        if not date_str:
            return jsonify({'error': 'date parameter required (YYYY-MM-DD)'}), 400
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400

        lat = request.args.get('lat', type=float)
        lon = request.args.get('lon', type=float)
        system = (request.args.get('system') or 'western').lower()

        positions = _compute_positions(dt, lat, lon, system)

        planets = []
        for planet_name, planet_data in positions.items():
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
            "timestamp": dt.isoformat(),
            "has_rising_sign": lat is not None and lon is not None
        })

    except Exception as e:
        return jsonify({'error': f'Failed to get positions: {str(e)}'}), 500

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
