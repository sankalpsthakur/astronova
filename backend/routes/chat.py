from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.schemas import ChatRequest
from utils.validators import validate_request
from services.claude_ai import ClaudeService

chat_bp = Blueprint('chat', __name__)
claude = ClaudeService()

@chat_bp.route('/send', methods=['POST'])
@jwt_required(optional=True)
@validate_request(ChatRequest)
def send_message(data: ChatRequest):
    resp = claude.send_message(data.message)
    return jsonify(resp)
