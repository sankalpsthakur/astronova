from flask import Blueprint, request, jsonify
from datetime import datetime

from backend.services.chart_service import calculate_positions, compute_aspects
from backend.services.location_service import get_location

misc_bp = Blueprint('misc', __name__)


def _parse_chart(data):
    date_str = data.get('date')
    time_str = data.get('time', '00:00')
    lat = float(data.get('lat', 0.0))
    lon = float(data.get('lon', 0.0))
    dt = datetime.fromisoformat(f"{date_str}T{time_str}")
    return calculate_positions(dt, lat, lon)


@misc_bp.route('/aspects', methods=['POST'])
def aspects():
    payload = request.get_json(force=True)
    chart1 = _parse_chart(payload['chart1'])
    chart2 = _parse_chart(payload['chart2'])
    aspects = compute_aspects(chart1, chart2)
    return jsonify(aspects)


@misc_bp.route('/location', methods=['GET'])
def location():
    address = request.args.get('address')
    if not address and request.is_json:
        address = request.json.get('address')
    if not address:
        return jsonify({'error': 'address is required'}), 400
    try:
        info = get_location(address)
        return jsonify(info)
    except Exception as exc:
        return jsonify({'error': str(exc)}), 500
