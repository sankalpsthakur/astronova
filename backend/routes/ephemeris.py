from flask import Blueprint, jsonify
from services.ephemeris_service import EphemerisService

ephemeris_bp = Blueprint('ephemeris', __name__)
service = EphemerisService()

@ephemeris_bp.route('/positions', methods=['GET'])
def positions():
    return jsonify(service.get_current_positions())
