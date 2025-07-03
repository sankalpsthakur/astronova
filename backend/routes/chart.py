from __future__ import annotations

import base64
import uuid
from datetime import datetime

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from utils.validators import validate_request
from models.schemas import ChartRequest
from services.astro_calculator import AstroCalculator
from services.ephemeris_service import EphemerisService
from services.chinese_astrology_service import ChineseAstrologyService
from services.cloudkit_service import CloudKitService
from services.redis_cache import get as redis_get, set as redis_set

chart_bp = Blueprint('chart', __name__)

astro = AstroCalculator()
ephemeris = EphemerisService()
chinese_service = ChineseAstrologyService()
cloudkit = CloudKitService()

@chart_bp.route('', methods=['GET'])
def chart_info():
    """Get chart service information"""
    return jsonify({
        'service': 'chart',
        'status': 'available',
        'endpoints': {
            'POST /generate': 'Generate birth chart'
        }
    })


def _chart_cache_key(system: str, req: ChartRequest) -> str:
    b = req.birthData
    return f"chart:{system}:{b.date}:{b.time}:{b.latitude}:{b.longitude}"


def _svg_from_dict(title: str, data: dict) -> str:
    lines = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300">',
        '<rect width="100%" height="100%" fill="white" stroke="black"/>',
        f'<text x="10" y="20" font-size="16">{title} Chart</text>'
    ]
    y = 40
    for key, val in data.items():
        lines.append(f'<text x="10" y="{y}" font-size="12">{key}: {val}</text>')
        y += 15
    lines.append('</svg>')
    return ''.join(lines)


@chart_bp.route('/aspects', methods=['POST'])
@jwt_required(optional=True)
@validate_request(ChartRequest)
def get_chart_aspects(data: ChartRequest):
    """Get astrological aspects for a birth chart"""
    try:
        birth = data.birthData
        dt = datetime.fromisoformat(f"{birth.date}T{birth.time}")
        
        # Calculate planetary positions
        positions = astro.western_chart(dt)
        
        # Calculate aspects between planets
        aspects = []
        planet_names = list(positions.keys())
        
        for i, planet1 in enumerate(planet_names):
            for planet2 in planet_names[i+1:]:
                pos1 = positions[planet1]
                pos2 = positions[planet2]
                
                # Calculate aspect angle
                angle = abs(pos1['longitude'] - pos2['longitude'])
                if angle > 180:
                    angle = 360 - angle
                
                # Check for major aspects (with 6-degree orb)
                major_aspects = {
                    'conjunction': (0, 6),
                    'sextile': (60, 6),
                    'square': (90, 6),
                    'trine': (120, 6),
                    'opposition': (180, 6)
                }
                
                for aspect_name, (target_angle, orb) in major_aspects.items():
                    if abs(angle - target_angle) <= orb:
                        aspects.append({
                            'planet1': planet1,
                            'planet2': planet2,
                            'aspect': aspect_name,
                            'angle': round(angle, 2),
                            'orb': round(abs(angle - target_angle), 2),
                            'exact': abs(angle - target_angle) < 1
                        })
                        break
        
        return jsonify({
            'aspects': aspects,
            'planetaryPositions': positions,
            'chartType': data.chartType,
            'timestamp': datetime.utcnow().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to calculate aspects: {str(e)}'}), 500

@chart_bp.route('/generate', methods=['POST'])
@jwt_required(optional=True)
@validate_request(ChartRequest)
def generate(data: ChartRequest):
    try:
        birth = data.birthData
        dt = datetime.fromisoformat(f"{birth.date}T{birth.time}")
        systems = [s.lower() for s in data.systems]
        results: dict[str, dict] = {}
        user_id = get_jwt_identity()

        for system in systems:
            key = _chart_cache_key(system, data)
            cached = redis_get(key)
            if cached:
                results[system] = cached
                continue

            if system == 'western':
                positions = astro.western_chart(dt)
                svg = _svg_from_dict('Western', {p: f"{v['sign']} {v['degree']}" for p, v in positions.items()})
                chart = {
                    'svg': base64.b64encode(svg.encode()).decode(),
                    'positions': positions,
                }
            elif system == 'vedic':
                positions = astro.vedic_chart(dt)
                svg = _svg_from_dict('Vedic', {p: f"{v['sign']} {v['degree']}" for p, v in positions.items()})
                chart = {
                    'svg': base64.b64encode(svg.encode()).decode(),
                    'positions': positions,
                }
            elif system == 'chinese':
                cz = chinese_service.chart_for_date(dt.date())
                svg = _svg_from_dict('Chinese', {'animal': cz.animal, 'element': cz.element, 'year': cz.year})
                chart = {
                    'svg': base64.b64encode(svg.encode()).decode(),
                    'animal': cz.animal,
                    'element': cz.element,
                }
            else:
                continue

            results[system] = chart
            redis_set(key, chart)

            if user_id:
                try:
                    cloudkit.save_birth_chart({
                        'userProfileId': user_id,
                        'chartType': data.chartType,
                        'systems': data.systems,
                        'planetaryPositions': chart.get('positions', []),
                        'chartSVG': chart.get('svg', ''),
                        'birthData': {
                            'birthDate': data.birthData.date,
                            'birthTime': data.birthData.time,
                            'latitude': data.birthData.latitude,
                            'longitude': data.birthData.longitude,
                            'timezone': data.birthData.timezone
                        }
                    })
                except Exception as e:
                    # Don't block the response path – log and continue
                    from flask import current_app
                    current_app.logger.exception("CloudKit save_birth_chart failed")

        chart_id = str(uuid.uuid4())
        return jsonify({'chartId': chart_id, 'charts': results, 'type': data.chartType})
    except Exception:
        return jsonify({'error': 'Chart generation failed'}), 500


