from __future__ import annotations

from datetime import datetime
from flask import Blueprint, request, jsonify

horoscope_bp = Blueprint('horoscope', __name__)

VALID_SIGNS = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
]


def _simple_horoscope(sign: str, dt: datetime, period: str) -> str:
    seed = (hash(sign) + dt.timetuple().tm_yday + len(period)) % 5
    themes = [
        "Focus on steady progress and small wins.",
        "Be open to new ideas and connections.",
        "Trust your intuition and set clear boundaries.",
        "Take action on one meaningful goal today.",
        "Reflect, recharge, and plan your next step.",
    ]
    guidance = themes[seed]
    return f"{sign.title()} — {guidance}"


@horoscope_bp.route('', methods=['GET'])
def horoscope():
    sign = request.args.get('sign', 'aries').lower()
    if sign not in VALID_SIGNS:
        return jsonify({'error': 'Invalid zodiac sign'}), 400

    date_str = request.args.get('date')
    period = request.args.get('type', 'daily').lower()

    if date_str:
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400
    else:
        dt = datetime.utcnow()

    content = _simple_horoscope(sign, dt, period)

    return jsonify({
        'id': f'{sign}-{dt.strftime("%Y%m%d")}-{period}',
        'sign': sign,
        'date': dt.isoformat(),
        'type': period,
        'content': content,
        'luckyElements': {},
        'legacy': {
            'sign': sign,
            'date': dt.strftime('%Y-%m-%d'),
            'type': period,
            'horoscope': content
        }
    })


@horoscope_bp.route('/daily', methods=['GET'])
def daily_horoscope():
    # Convenience endpoint that forces daily type
    sign = request.args.get('sign', 'aries').lower()
    if sign not in VALID_SIGNS:
        return jsonify({'error': 'Invalid zodiac sign'}), 400

    date_str = request.args.get('date')
    if date_str:
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400
    else:
        dt = datetime.utcnow()

    content = _simple_horoscope(sign, dt, 'daily')

    return jsonify({
        'id': f'{sign}-{dt.strftime("%Y%m%d")}-daily',
        'sign': sign,
        'date': dt.isoformat(),
        'type': 'daily',
        'content': content,
        'luckyElements': {},
        'legacy': {
            'sign': sign,
            'date': dt.strftime('%Y-%m-%d'),
            'type': 'daily',
            'horoscope': content
        }
    })
