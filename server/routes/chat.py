from __future__ import annotations

from flask import Blueprint, jsonify, request

from db import add_chat_message, ensure_conversation, get_user_birth_data, init_db, upsert_user_birth_data
from services.chat_response_service import ChatResponseService

chat_bp = Blueprint("chat", __name__)
_chat_service = ChatResponseService()


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
def chat():
    data = request.get_json(silent=True) or {}
    init_db()
    message = data.get("message", "")
    user_id = data.get("userId") or request.headers.get("X-User-Id")
    conversation_id = data.get("conversationId")

    # Support optional birth data in request for immediate personalization
    birth_data = data.get("birthData")

    # If no birth data in request, try to get from database
    if not birth_data and user_id:
        birth_data = get_user_birth_data(user_id)

    # Ensure conversation exists (or create one)
    conversation_id = ensure_conversation(conversation_id, user_id)
    # Persist user message
    _ = add_chat_message(conversation_id, "user", message, user_id)

    # Generate personalized response using chat service
    reply, suggested_follow_ups = _chat_service.generate_response(message=message, user_id=user_id, birth_data=birth_data)

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
def save_birth_data():
    """
    Save user's birth data for personalized chat responses.
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

    user_id = data.get("userId") or request.headers.get("X-User-Id")
    if not user_id:
        return jsonify({"error": "userId required"}), 400

    birth_data = data.get("birthData")
    if not birth_data:
        return jsonify({"error": "birthData required"}), 400

    birth_date = birth_data.get("date")
    if not birth_date:
        return jsonify({"error": "birth date required in birthData"}), 400

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
        {"status": "success", "message": "Birth data saved successfully. Your chat responses will now be personalized!"}
    )


@chat_bp.route("/birth-data", methods=["GET"])
def get_birth_data():
    """Get user's saved birth data."""
    init_db()
    user_id = request.args.get("userId") or request.headers.get("X-User-Id")

    if not user_id:
        return jsonify({"error": "userId required"}), 400

    birth_data = get_user_birth_data(user_id)

    if not birth_data:
        return jsonify({"hasBirthData": False, "birthData": None})

    return jsonify({"hasBirthData": True, "birthData": birth_data})
