from flask import Blueprint, jsonify, request
from services.ephemeris_service import EphemerisService
from datetime import datetime

ephemeris_bp = Blueprint('ephemeris', __name__)
service = EphemerisService()

@ephemeris_bp.route('/positions', methods=['GET'])
def positions():
    date_str = request.args.get('date')
    if date_str:
        try:
            datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400
    
    try:
        return jsonify(service.get_current_positions())
    except Exception as e:
        return jsonify({'error': 'Failed to get positions'}), 500
