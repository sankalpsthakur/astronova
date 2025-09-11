from __future__ import annotations

from flask import Blueprint, jsonify, request
from datetime import datetime
from zoneinfo import ZoneInfo
import uuid

from services.ephemeris_service import EphemerisService

chart_bp = Blueprint('chart', __name__)
_ephem = EphemerisService()


def _parse_birth_payload(data: dict) -> tuple[datetime, float, float, str]:
    # Accept nested { birthData: { date, time, timezone, latitude, longitude }} or flat keys
    bd = data.get('birthData', data)
    date = bd.get('date') or bd.get('birth_date')
    time = bd.get('time') or bd.get('birth_time') or '12:00'
    tz = bd.get('timezone') or 'UTC'
    lat = float(bd.get('latitude'))
    lon = float(bd.get('longitude'))
    # Create a naive UTC datetime based on provided local time to keep minimal behavior consistent
    try:
        dt_local = datetime.fromisoformat(f"{date}T{time}")
        dt = dt_local.replace(tzinfo=ZoneInfo(tz)).astimezone(ZoneInfo('UTC')).replace(tzinfo=None)
    except Exception:
        dt = datetime.utcnow()
    return dt, lat, lon, tz


def _positions_to_chart_system(positions: dict) -> dict:
    # positions: { 'planets': { name: { sign, degree, ... } } }
    result = {}
    for name, info in positions.get('planets', {}).items():
        key = name.title()
        result[key] = {
            'degree': float(info.get('degree', 0.0)),
            'sign': str(info.get('sign', 'Unknown')),
        }
    return result


def _compute_aspects(lon_map: dict[str, float], orb: float = 6.0) -> list[dict]:
    aspects = {
        'conjunction': 0,
        'sextile': 60,
        'square': 90,
        'trine': 120,
        'opposition': 180,
    }
    planets = list(lon_map.keys())
    results: list[dict] = []
    for i in range(len(planets)):
        for j in range(i + 1, len(planets)):
            p1, p2 = planets[i], planets[j]
            lon1, lon2 = lon_map[p1], lon_map[p2]
            diff = abs((lon1 - lon2 + 180) % 360 - 180)
            for name, angle in aspects.items():
                delta = abs(diff - angle)
                if delta <= orb:
                    results.append({
                        'planet1': p1,
                        'planet2': p2,
                        'aspect': name,
                        'orb': round(delta, 2)
                    })
    return results


@chart_bp.route('/generate', methods=['POST'])
def generate_chart():
    payload = request.get_json(silent=True) or {}
    dt, lat, lon, tz = _parse_birth_payload(payload)
    positions = _ephem.get_positions_for_date(dt, lat, lon)

    western_positions = _positions_to_chart_system(positions)

    resp = {
        'chartId': str(uuid.uuid4()),
        'charts': {
            'western': {
                'positions': western_positions,
                'svg': ''
            }
        },
        'type': payload.get('chartType', 'natal'),
        'westernChart': None,
        'vedicChart': None,
        'chineseChart': None,
    }
    return jsonify(resp)


@chart_bp.route('/aspects', methods=['POST'])
def chart_aspects():
    payload = request.get_json(silent=True) or {}
    # Prefer birthData if present
    if 'birthData' in payload or 'date' in payload:
        if 'birthData' in payload:
            dt, lat, lon, tz = _parse_birth_payload(payload)
        else:
            # Support flat {date, time?, timezone?, latitude?, longitude?}
            dt, lat, lon, tz = _parse_birth_payload(payload)
    else:
        dt, lat, lon, tz = datetime.utcnow(), None, None, 'UTC'  # type: ignore[assignment]

    positions = _ephem.get_positions_for_date(dt, lat, lon)
    lon_map = {}
    for name, info in positions.get('planets', {}).items():
        if 'longitude' in info:
            lon_map[name] = float(info['longitude'])
    aspects = _compute_aspects(lon_map)
    return jsonify(aspects)


@chart_bp.route('/aspects', methods=['GET'])
def chart_aspects_by_date():
    from datetime import datetime as _dt
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'error': 'date parameter required (YYYY-MM-DD)'}), 400
    try:
        dt = _dt.strptime(date_str, '%Y-%m-%d')
    except ValueError:
        return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400
    positions = _ephem.get_positions_for_date(dt)
    lon_map = {name: float(info.get('longitude', 0.0)) for name, info in positions.get('planets', {}).items()}
    aspects = _compute_aspects(lon_map)
    return jsonify(aspects)
