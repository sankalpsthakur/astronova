from flask import Blueprint, request, jsonify

horoscope_bp = Blueprint('horoscope', __name__)

@horoscope_bp.route('', methods=['GET'])
def horoscope():
    sign = request.args.get('sign', 'aries')
    return jsonify({'sign': sign, 'horoscope': 'Today will be great!'})
