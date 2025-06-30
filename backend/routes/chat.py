from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.schemas import ChatRequest
from utils.validators import validate_request
from services.claude_ai import ClaudeService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

chat_bp = Blueprint('chat', __name__)
claude = ClaudeService()
cloudkit = CloudKitService()

@chat_bp.route('/send', methods=['POST'])
@jwt_required(optional=True)
@validate_request(ChatRequest)
def send_message(data: ChatRequest):
    user_id = get_jwt_identity()
    conv_id = data.conversationId

    history = []
    if user_id and conv_id:
        history = cloudkit.get_conversation_history(user_id, conv_id, limit=10)

    birth_chart = None
    transits = None
    if data.context:
        birth_chart = data.context.get("birthChart")
        transits = data.context.get("transits")

    if user_id:
        cached_chart = cache.get(f"birth_chart:{user_id}")
        if not cached_chart and birth_chart:
            cache.set(f"birth_chart:{user_id}", birth_chart)
        else:
            birth_chart = birth_chart or cached_chart

    if user_id:
        try:
            cloudkit.save_chat_message({
                "userProfileId": user_id,
                "conversationId": conv_id,
                "content": data.message,
                "isUser": True,
            })
        except Exception:
            # Don't block the response path – log and continue
            from flask import current_app
            current_app.logger.exception("CloudKit save_chat_message (user) failed")

    resp = claude.send_message(
        data.message,
        conversation_history=history,
        system_prompt={"birthChart": birth_chart, "transits": transits},
    )

    if user_id:
        try:
            cloudkit.save_chat_message({
                "userProfileId": user_id,
                "conversationId": conv_id,
                "content": resp.get("reply"),
                "isUser": False,
            })
        except Exception:
            # Don't block the response path – log and continue
            from flask import current_app
            current_app.logger.exception("CloudKit save_chat_message (AI) failed")

    return jsonify({
        "reply": resp.get("reply"),
        "messageId": resp.get("message_id"),
        "suggestedFollowUps": [
            "What's my love forecast? \ud83d\udc96",
            "Career guidance? \u2b50",
            "Today's energy? \u2600\ufe0f",
            "Mercury retrograde effects? \u263f",
            "Best time for decisions? \ud83c\udf19",
        ],
    })
