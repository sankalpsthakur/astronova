from __future__ import annotations

import datetime as _dt
from datetime import datetime
from flask import Blueprint, current_app, request, send_file, abort, jsonify

from services.chart_service import calculate_positions, compute_aspects
from services.location_service import get_location
from services.reports_service import ReportsService
from services.ephemeris_service import get_planetary_positions

misc_bp = Blueprint('misc', __name__)


def _parse_chart(data):
    date_str = data.get('date')
    time_str = data.get('time', '00:00')
    lat = float(data.get('lat', 0.0))
    lon = float(data.get('lon', 0.0))
    dt = datetime.fromisoformat(f"{date_str}T{time_str}")
    return calculate_positions(dt, lat, lon)


def _get_user_profile(user_id: str) -> dict:
    """Placeholder for fetching a user profile."""
    return {
        "full_name": "Test User",
        "birth_datetime": _dt.datetime(1990, 1, 1, 12, 0),
        "latitude": 0.0,
        "longitude": 0.0,
    }


@misc_bp.route('/aspects', methods=['POST'])
def aspects():
    payload = request.get_json(force=True)
    chart1 = _parse_chart(payload['chart1'])
    chart2 = _parse_chart(payload['chart2'])
    aspects = compute_aspects(chart1, chart2)
    return jsonify(aspects)


