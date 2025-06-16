from flask import Blueprint, jsonify
from utils.validators import validate_request
from models.schemas import MatchRequest
from models.responses import MatchResult
from spec import spec
from flask_pydantic_spec import Request, Response
from services.astro_calculator import AstroCalculator, BirthData
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

match_bp = Blueprint('match', __name__)
cloudkit = CloudKitService()

@match_bp.route('', methods=['POST'])
@spec.validate(
    body=Request(MatchRequest),
    resp=Response(HTTP_200=MatchResult),
    tags=["Match"]
)
@validate_request(MatchRequest)
def match(data: MatchRequest):
    cache_key = (
        f"match:{data.user.birth_date}:{data.user.birth_time}:"
        f"{data.partner.birth_date}:{data.partner.birth_time}"
    )
    cached = cache.get(cache_key)
    if cached:
        return jsonify(cached)

    user_bd = BirthData(
        date=data.user.birth_date,
        time=data.user.birth_time,
        timezone=data.user.timezone,
        latitude=data.user.latitude,
        longitude=data.user.longitude,
    )

    partner_bd = BirthData(
        date=data.partner.birth_date,
        time=data.partner.birth_time,
        timezone=data.partner.timezone,
        latitude=data.partner.latitude,
        longitude=data.partner.longitude,
    )

    user_chart = AstroCalculator.calculate_birth_chart(user_bd)
    partner_chart = AstroCalculator.calculate_birth_chart(partner_bd)

    aspects = AstroCalculator.synastry_aspects(user_chart, partner_chart)

    year1 = int(data.user.birth_date.split("-")[0])
    year2 = int(data.partner.birth_date.split("-")[0])
    vedic_score = AstroCalculator.vedic_compatibility(year1, year2)
    chinese_score = AstroCalculator.chinese_compatibility(year1, year2)

    overall_score = int(
        (vedic_score / 36 * 50)
        + (chinese_score / 100 * 30)
        + min(len(aspects), 10) * 2
    )

    result = {
        "overallScore": overall_score,
        "vedicScore": vedic_score,
        "chineseScore": chinese_score,
        "synastryAspects": aspects,
        "userChart": user_chart,
        "partnerChart": partner_chart,
    }

    try:
        cloudkit.save_match(result)
    except Exception:
        pass

    cache.set(cache_key, result, timeout=60 * 60 * 24)
    return jsonify(result)
