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


@misc_bp.route("/report", methods=["GET"])
def generate_report():
    user_id = request.headers.get("X-User-ID")
    if not user_id:
        abort(401)

    profile = _get_user_profile(user_id)
    service: ReportsService = current_app.config["reports_service"]
    pdf_io = service.build_report(profile)
    return send_file(
        pdf_io,
        mimetype="application/pdf",
        as_attachment=True,
        download_name="report.pdf",
    )


@misc_bp.route("/planetary-positions", methods=["GET"])
def planetary_positions():
    """Return planetary positions as zodiac sign and degree."""
    dt_str = request.args.get('dt')
    date = datetime.fromisoformat(dt_str) if dt_str else None
    data = get_planetary_positions(date)
    return jsonify(data)
