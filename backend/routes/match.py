from flask import Blueprint, jsonify
from utils.validators import validate_request
from models.schemas import MatchRequest

match_bp = Blueprint('match', __name__)

@match_bp.route('', methods=['POST'])
@validate_request(MatchRequest)
def match(data: MatchRequest):
    return jsonify({'overallScore': 80, 'summary': 'Great match!'})
