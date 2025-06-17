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
                cloudkit.save_birth_chart({
                    'userProfileId': user_id,
                    'chartType': data.chartType,
                    'systems': data.systems,
                    'planetaryPositions': chart.get('positions', []),
                    'chartSVG': chart.get('svg', ''),
                    'birthData': {
                        'birthDate': data.birthData.birthDate,
                        'birthTime': data.birthData.birthTime,
                        'latitude': data.birthData.latitude,
                        'longitude': data.birthData.longitude,
                        'timezone': data.birthData.timezone
                    }
                })

        chart_id = str(uuid.uuid4())
        return jsonify({'chartId': chart_id, 'charts': results, 'type': data.chartType})
    except Exception:
        return jsonify({'error': 'Chart generation failed'}), 500


