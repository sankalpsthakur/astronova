from __future__ import annotations

from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity

from services.astro_calculator import AstroCalculator
from services.claude_ai import ClaudeService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

horoscope_bp = Blueprint('horoscope', __name__)
calculator = AstroCalculator()
claude = ClaudeService()
cloudkit = CloudKitService()

VALID_SIGNS = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
]

@horoscope_bp.route('', methods=['GET'])
def horoscope():
    sign = request.args.get('sign', 'aries').lower()
    
    if sign not in VALID_SIGNS:
        return jsonify({'error': 'Invalid zodiac sign'}), 400
    date_str = request.args.get('date')
    type_ = request.args.get('type', 'daily').lower()

    if date_str:
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format, use YYYY-MM-DD'}), 400
    else:
        dt = datetime.utcnow()
        date_str = dt.strftime('%Y-%m-%d')

    cache_key = f"horoscope:{sign}:{date_str}:{type_}"
    cached = cache.get(cache_key)
    if cached:
        return jsonify(cached)

    user_id = get_jwt_identity() or f"public_{sign}"
    stored = cloudkit.get_horoscope(user_id, sign, date_str, type_)
    if stored:
        cache.set(cache_key, stored, timeout=3600)
        return jsonify(stored)

    positions = calculator.get_positions(dt)
    position_lines = [
        f"{planet.title()}: {info['sign']} {info['degree']}" for planet, info in positions.items()
    ]
    prompt = (
        f"Generate a {type_} horoscope for the sign {sign.capitalize()} on {date_str}.\n"
        "Use the following planetary positions:\n" + "\n".join(position_lines)
    )
    try:
        content = claude.generate_content(prompt, max_tokens=300)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

    result = {'sign': sign, 'date': date_str, 'type': type_, 'horoscope': content}
    cache.set(cache_key, result, timeout=3600)
    
    # Save to CloudKit with proper structure
    cloudkit.save_horoscope({
        'userProfileId': user_id,
        'sign': sign,
        'date': date_str,
        'type': type_,
        'content': content
    })
    return jsonify(result)
