from __future__ import annotations

from flask import Blueprint, g, jsonify, request
from flask_babel import gettext as _

from db import (
    add_chat_message,
    ensure_conversation,
    get_premium_entitlement,
    get_user_birth_data,
    init_db,
    upsert_user_birth_data,
)
from middleware import require_auth
from services.chat_response_service import ChatResponseService, ChatServiceError

chat_bp = Blueprint("chat", __name__)
_chat_service = ChatResponseService()


_FREE_CHAT_DEPTHS = {"quick", "daily", "free", ""}


def _requested_chat_depth(data: dict) -> str:
    for key in ("depth", "oracleDepth", "readingDepth"):
        value = data.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip().lower()

    context = data.get("context")
    if isinstance(context, str):
        for item in context.replace("&", ";").split(";"):
            key, separator, value = item.partition("=")
            if separator and key.strip().lower() == "depth":
                return value.strip().lower()

    return "quick"


def _truthy_flag(value) -> bool:
    if value is True:
        return True
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes"}
    return False


def _is_paid_chat_request(data: dict) -> bool:
    if any(_truthy_flag(data.get(key)) for key in ("requiresPremium", "premium", "isPremium")):
        return True
    return _requested_chat_depth(data) not in _FREE_CHAT_DEPTHS


def _payment_required_response(feature: str, entitlement: dict):
    return jsonify(
        {
            "error": "payment_required",
            "code": "PAYMENT_REQUIRED",
            "feature": feature,
            "message": "Astronova Pro is required for this feature.",
            "entitlement": entitlement,
        }
    ), 402


@chat_bp.route("", methods=["GET"])
def chat_info():
    return jsonify(
        {
            "service": "chat",
            "status": "available",
            "endpoints": {
                "POST /": "Send a chat message",
                "POST /send": "Alias for POST /",
                "POST /birth-data": "Save birth data for personalization",
                "GET /birth-data": "Retrieve saved birth data",
            },
        }
    )


@chat_bp.route("", methods=["POST"])
@require_auth
def chat():
    data = request.get_json(silent=True) or {}
    init_db()
    message = data.get("message", "")
    user_id = g.user_id  # Use authenticated user ID from decorator
    conversation_id = data.get("conversationId")

    if _is_paid_chat_request(data):
        entitlement = get_premium_entitlement(user_id)
        if not entitlement["hasPremium"]:
            return _payment_required_response("oracle_chat_deep", entitlement)

    # Support optional birth data in request for immediate personalization
    birth_data = data.get("birthData")

    # If no birth data in request, try to get from database
    if not birth_data and user_id:
        birth_data = get_user_birth_data(user_id)

    # Ensure conversation exists (or create one)
    conversation_id = ensure_conversation(conversation_id, user_id)
    # Persist user message
    user_message_id = add_chat_message(conversation_id, "user", message, user_id)

    # Generate personalized response using chat service
    try:
        reply, suggested_follow_ups = _chat_service.generate_response(
            message=message, user_id=user_id, birth_data=birth_data
        )
    except ChatServiceError as exc:
        return jsonify({"error": "oracle_unavailable", "detail": str(exc)}), 503

    # Persist assistant reply
    message_id = add_chat_message(conversation_id, "assistant", reply, user_id)
    return jsonify(
        {
            "reply": reply,
            "messageId": message_id,
            "conversationId": conversation_id,
            "suggestedFollowUps": suggested_follow_ups,
        }
    )


@chat_bp.route("/send", methods=["POST"])
def chat_send():
    # Backward-compatibility alias for OpenAPI spec
    return chat()


@chat_bp.route("/birth-data", methods=["POST"])
@require_auth
def save_birth_data():
    """
    Save user's birth data for personalized chat responses.

    SECURITY: Requires Bearer token authentication.

    POST body:
    {
        "userId": "user-id",
        "birthData": {
            "date": "1990-08-15",
            "time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "locationName": "New York, NY"
        }
    }
    """
    data = request.get_json(silent=True) or {}
    init_db()

    user_id = g.user_id  # Use authenticated user ID from decorator

    birth_data = data.get("birthData")
    if not birth_data:
        return jsonify({"error": _("birthData required")}), 400

    birth_date = birth_data.get("date")
    if not birth_date:
        return jsonify({"error": _("birth date required in birthData")}), 400

    # Save birth data
    upsert_user_birth_data(
        user_id=user_id,
        birth_date=birth_date,
        birth_time=birth_data.get("time"),
        timezone=birth_data.get("timezone"),
        latitude=birth_data.get("latitude"),
        longitude=birth_data.get("longitude"),
        location_name=birth_data.get("locationName"),
    )

    return jsonify(
        {
            "status": "success",
            "message": _("Birth data saved successfully. Your chat responses will now be personalized!"),
        }
    )


@chat_bp.route("/birth-data", methods=["GET"])
@require_auth
def get_birth_data():
    """
    Get user's saved birth data.

    SECURITY: Requires Bearer token authentication.
    """
    init_db()
    user_id = g.user_id  # Use authenticated user ID from decorator

    birth_data = get_user_birth_data(user_id)

    if not birth_data:
        return jsonify({"hasBirthData": False, "birthData": None})

    return jsonify({"hasBirthData": True, "birthData": birth_data})
