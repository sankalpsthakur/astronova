from flask import Blueprint, request, jsonify
from datetime import datetime

from backend.services.chart_service import calculate_positions, compute_aspects

bp = Blueprint('misc', __name__)


def _parse_chart(data):
    date_str = data.get('date')
    time_str = data.get('time', '00:00')
    lat = float(data.get('lat', 0.0))
    lon = float(data.get('lon', 0.0))
    dt = datetime.fromisoformat(f"{date_str}T{time_str}")
    return calculate_positions(dt, lat, lon)


@bp.route('/aspects', methods=['POST'])
def aspects():
    payload = request.get_json(force=True)
    chart1 = _parse_chart(payload['chart1'])
    chart2 = _parse_chart(payload['chart2'])
    aspects = compute_aspects(chart1, chart2)
    return jsonify(aspects)
