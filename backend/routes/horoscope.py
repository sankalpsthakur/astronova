from __future__ import annotations

from datetime import datetime
from flask import Blueprint, request, jsonify

from services.astro_calculator import AstroCalculator
from services.claude_ai import ClaudeService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

horoscope_bp = Blueprint('horoscope', __name__)
calculator = AstroCalculator()
claude = ClaudeService()
cloudkit = CloudKitService()


@horoscope_bp.route('', methods=['GET'])
def horoscope():
    sign = request.args.get('sign', 'aries').lower()
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

    stored = cloudkit.get_horoscope(sign, date_str, type_)
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
    cloudkit.save_horoscope(result)
    return jsonify(result)
