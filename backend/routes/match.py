from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity
from utils.validators import validate_request
from models.schemas import MatchRequest, SimpleMatchRequest
from services.astro_calculator import AstroCalculator, BirthData
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

match_bp = Blueprint('match', __name__)
cloudkit = CloudKitService()

@match_bp.route('', methods=['GET'])
def match_info():
    """Get match service information"""
    return jsonify({
        'service': 'match',
        'status': 'available',
        'endpoints': {
            'POST /': 'Calculate compatibility between two people'
        }
    })

@match_bp.route('', methods=['POST'])
@validate_request(SimpleMatchRequest)
def match(data: SimpleMatchRequest):
    person1 = data.person1
    person2 = data.person2
    
    cache_key = (
        f"match:{person1['birth_date']}:{person1['birth_time']}:"
        f"{person2['birth_date']}:{person2['birth_time']}"
    )
    cached = cache.get(cache_key)
    if cached:
        return jsonify(cached)

    user_bd = BirthData(
        date=person1['birth_date'],
        time=person1['birth_time'],
        timezone=person1['timezone'],
        latitude=person1['latitude'],
        longitude=person1['longitude'],
    )

    partner_bd = BirthData(
        date=person2['birth_date'],
        time=person2['birth_time'],
        timezone=person2['timezone'],
        latitude=person2['latitude'],
        longitude=person2['longitude'],
    )

    user_chart = AstroCalculator.calculate_birth_chart(user_bd)
    partner_chart = AstroCalculator.calculate_birth_chart(partner_bd)

    aspects = AstroCalculator.synastry_aspects(user_chart, partner_chart)

    year1 = int(person1['birth_date'].split("-")[0])
    year2 = int(person2['birth_date'].split("-")[0])
    vedic_score = AstroCalculator.vedic_compatibility(year1, year2)
    chinese_score = AstroCalculator.chinese_compatibility(year1, year2)

    overall_score = int(
        (vedic_score / 36 * 50)
        + (chinese_score / 100 * 30)
        + min(len(aspects), 10) * 2
    )

    # Format response to match ERD schema for Swift compatibility
    import uuid
    from datetime import datetime
    
    match_id = str(uuid.uuid4())
    user_id = get_jwt_identity()
    
    result = {
        'id': match_id,
        'userProfileId': user_id or 'anonymous',
        'partnerName': person2.get('name', 'Partner'),
        'partnerBirthDate': f"{person2['birth_date']}T{person2['birth_time']}:00",
        'partnerLocation': f"{person2['latitude']}, {person2['longitude']}",
        'compatibilityScore': int(overall_score),
        'detailedAnalysis': {
            'vedicScore': vedic_score,
            'chineseScore': chinese_score,
            'synastryAspects': aspects,
            'userChart': user_chart,
            'partnerChart': partner_chart
        },
        # Keep legacy format for backward compatibility
        'legacy': {
            "overallScore": overall_score,
            "vedicScore": vedic_score,
            "chineseScore": chinese_score,
            "synastryAspects": aspects,
            "userChart": user_chart,
            "partnerChart": partner_chart,
        }
    }

    try:
        if user_id:
            cloudkit.save_match({
                'id': match_id,
                'userProfileId': user_id,
                'partnerName': person2.get('name', 'Partner'),
                'partnerBirthDate': f"{person2['birth_date']}T{person2['birth_time']}:00",
                'partnerLocation': f"{person2['latitude']}, {person2['longitude']}",
                'compatibilityScore': int(overall_score),
                'detailedAnalysis': result['detailedAnalysis']
            })
    except Exception:
        pass

    cache.set(cache_key, result, timeout=60 * 60 * 24)
    return jsonify(result)
