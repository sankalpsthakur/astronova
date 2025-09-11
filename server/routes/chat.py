from __future__ import annotations

from flask import Blueprint, jsonify, request
import uuid
from db import init_db, ensure_conversation, add_chat_message

chat_bp = Blueprint('chat', __name__)


@chat_bp.route('', methods=['POST'])
def chat():
    data = request.get_json(silent=True) or {}
    init_db()
    message = data.get('message', '')
    user_id = data.get('userId') or request.headers.get('X-User-Id')
    conversation_id = data.get('conversationId')
    # Ensure conversation exists (or create one)
    conversation_id = ensure_conversation(conversation_id, user_id)
    # Persist user message
    _ = add_chat_message(conversation_id, 'user', message, user_id)

    reply = f"I hear you: '{message}'. Here's a friendly cosmic nudge to stay curious."
    # Persist assistant reply
    message_id = add_chat_message(conversation_id, 'assistant', reply, user_id)
    return jsonify({
        'reply': reply,
        'messageId': message_id,
        'conversationId': conversation_id,
        'suggestedFollowUps': [
            'What are today\'s influences?',
            'Any focus areas for this week?',
            'How do current transits affect me?'
        ]
    })
