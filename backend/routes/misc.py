from flask import Blueprint, request, jsonify

from backend.services.location_service import get_location

misc_bp = Blueprint('misc', __name__)


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
