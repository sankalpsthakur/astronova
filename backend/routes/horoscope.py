from __future__ import annotations

from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
import logging

from services.astro_calculator import AstroCalculator
from services.gemini_ai import GeminiService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

logger = logging.getLogger(__name__)

horoscope_bp = Blueprint('horoscope', __name__)
calculator = AstroCalculator()
gemini = GeminiService()
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

    # Try to get user ID safely, fallback to public user
    try:
        verify_jwt_in_request(optional=True)
        user_id = get_jwt_identity() or f"public_{sign}"
    except Exception:
        user_id = f"public_{sign}"
    
    # Try to get from CloudKit but don't fail if service is down
    try:
        stored = cloudkit.get_horoscope(user_id, sign, date_str, type_)
        if stored:
            cache.set(cache_key, stored, timeout=3600)
            return jsonify(stored)
    except Exception as e:
        # Log error but continue with generation
        logger.warning(f"CloudKit fetch failed for horoscope: {e}")

    positions = calculator.get_positions(dt)
    position_lines = [
        f"{planet.title()}: {info['sign']} {info['degree']}" for planet, info in positions.items()
    ]
    prompt = (
        f"Generate a {type_} horoscope for the sign {sign.capitalize()} on {date_str}.\n"
        "Use the following planetary positions:\n" + "\n".join(position_lines)
    )
    try:
        content = gemini.generate_content(prompt, max_tokens=300)
    except Exception as e:
        # Fallback to a simple horoscope template when Claude API fails
        content = f"Today brings unique cosmic energies for {sign.title()}. " \
                 f"With the current planetary alignments, focus on personal growth and positive intentions. " \
                 f"The stars encourage you to embrace new opportunities while staying grounded in your values."

    # Format response to match ERD schema for Swift compatibility
    import uuid
    horoscope_id = str(uuid.uuid4())
    
    result = {
        'id': horoscope_id,
        'userProfileId': user_id,
        'sign': sign,
        'date': dt.isoformat(),  # Use ISO timestamp format
        'type': type_,
        'content': content,
        'luckyElements': {},  # Placeholder for future lucky elements feature
        # Keep legacy format for backward compatibility
        'legacy': {
            'sign': sign, 
            'date': date_str, 
            'type': type_, 
            'horoscope': content
        }
    }
    
    cache.set(cache_key, result, timeout=3600)
    
    # Save to CloudKit with proper structure
    try:
        cloudkit.save_horoscope({
            'id': horoscope_id,
            'userProfileId': user_id,
            'sign': sign,
            'date': dt.isoformat(),
            'type': type_,
            'content': content,
            'luckyElements': {}
        })
    except Exception as e:
        # Don't block the response path – log and continue
        from flask import current_app
        current_app.logger.exception("CloudKit save_horoscope failed")
    
    return jsonify(result)

@horoscope_bp.route('/daily', methods=['GET'])
def daily_horoscope():
    """Path-based endpoint for daily horoscope that iOS app expects"""
    # Extract sign from query parameter
    sign = request.args.get('sign', 'aries').lower()
    
    if sign not in VALID_SIGNS:
        return jsonify({'error': 'Invalid zodiac sign'}), 400
    
    # Set type to daily and delegate to main horoscope function
    from flask import g
    g.horoscope_type = 'daily'
    
    # Use the existing horoscope logic but force daily type
    date_str = request.args.get('date')
    type_ = 'daily'  # Force daily type for this endpoint

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

    # Try to get user ID safely, fallback to public user
    try:
        verify_jwt_in_request(optional=True)
        user_id = get_jwt_identity() or f"public_{sign}"
    except Exception:
        user_id = f"public_{sign}"
    
    # Try to get from CloudKit but don't fail if service is down
    try:
        stored = cloudkit.get_horoscope(user_id, sign, date_str, type_)
        if stored:
            cache.set(cache_key, stored, timeout=3600)
            return jsonify(stored)
    except Exception as e:
        logger.warning(f"CloudKit fetch failed for horoscope: {e}")

    positions = calculator.get_positions(dt)
    position_lines = [
        f"{planet.title()}: {info['sign']} {info['degree']}" for planet, info in positions.items()
    ]
    prompt = (
        f"Generate a {type_} horoscope for the sign {sign.capitalize()} on {date_str}.\n"
        "Use the following planetary positions:\n" + "\n".join(position_lines)
    )
    try:
        content = gemini.generate_content(prompt, max_tokens=300)
    except Exception as e:
        content = f"Today brings unique cosmic energies for {sign.title()}. " \
                 f"With the current planetary alignments, focus on personal growth and positive intentions. " \
                 f"The stars encourage you to embrace new opportunities while staying grounded in your values."

    # Format response to match ERD schema for Swift compatibility
    import uuid
    horoscope_id = str(uuid.uuid4())
    
    result = {
        'id': horoscope_id,
        'userProfileId': user_id,
        'sign': sign,
        'date': dt.isoformat(),
        'type': type_,
        'content': content,
        'luckyElements': {},
        # Keep legacy format for backward compatibility
        'legacy': {
            'sign': sign, 
            'date': date_str, 
            'type': type_, 
            'horoscope': content
        }
    }
    
    cache.set(cache_key, result, timeout=3600)
    
    # Save to CloudKit with proper structure
    try:
        cloudkit.save_horoscope({
            'id': horoscope_id,
            'userProfileId': user_id,
            'sign': sign,
            'date': dt.isoformat(),
            'type': type_,
            'content': content,
            'luckyElements': {}
        })
    except Exception as e:
        from flask import current_app
        current_app.logger.exception("CloudKit save_horoscope failed")
    
    return jsonify(result)
