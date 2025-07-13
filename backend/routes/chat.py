from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.schemas import ChatRequest
from utils.validators import validate_request
from services.gemini_ai import GeminiService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache
import uuid
from datetime import datetime

chat_bp = Blueprint('chat', __name__)
gemini = GeminiService()
cloudkit = CloudKitService()

@chat_bp.route('', methods=['GET'])
def chat_info():
    """Get chat service information"""
    return jsonify({
        'service': 'chat',
        'status': 'available',
        'endpoints': {
            'POST /send': 'Send a chat message'
        }
    })

@chat_bp.route('/history', methods=['GET'])
@jwt_required()
def get_chat_history():
    """Get chat history for authenticated user"""
    try:
        user_id = get_jwt_identity()
        conversation_id = request.args.get('conversationId')
        limit = int(request.args.get('limit', 50))
        
        # Get chat history from CloudKit
        history = cloudkit.get_conversation_history(user_id, conversation_id, limit=limit)
        
        return jsonify({
            'messages': history,
            'conversationId': conversation_id,
            'userId': user_id
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to get chat history: {str(e)}'}), 500

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

    resp = gemini.send_message(
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

    # Format response to match ERD schema for Swift compatibility
    import uuid
    from datetime import datetime
    
    message_id = str(uuid.uuid4())
    
    response = {
        'id': message_id,
        'userProfileId': user_id or 'anonymous',
        'conversationId': conv_id,
        'content': resp.get("reply"),
        'isUser': 0,  # 0 for AI response, 1 for user message
        'messageType': 'text',
        'timestamp': datetime.utcnow().isoformat(),
        # Keep legacy format for backward compatibility
        'legacy': {
            "reply": resp.get("reply"),
            "messageId": resp.get("message_id"),
            "suggestedFollowUps": [
                "What's my love forecast? \ud83d\udc96",
                "Career guidance? \u2b50",
                "Today's energy? \u2600\ufe0f",
                "Mercury retrograde effects? \u263f",
                "Best time for decisions? \ud83c\udf19",
            ]
        }
    }
    
    return jsonify(response)

@chat_bp.route('', methods=['POST'])
@jwt_required(optional=True)
def chat_message():
    """Chat endpoint that iOS app expects - handles raw JSON without strict validation"""
    try:
        # Get raw JSON data
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        user_id = get_jwt_identity()
        message = data.get('message', '')
        conv_id = data.get('conversationId', str(uuid.uuid4()))
        birth_data = data.get('birth_data', {})
        context = data.get('context', {})
        
        if not message:
            return jsonify({'error': 'Message is required'}), 400
        
        # Get conversation history if available
        history = []
        if user_id and conv_id:
            try:
                history = cloudkit.get_conversation_history(user_id, conv_id, limit=10)
            except Exception:
                pass  # Continue without history
        
        # Handle birth data context
        birth_chart = context.get("birthChart") or birth_data
        transits = context.get("transits")
        
        # Cache birth chart if we have user ID
        if user_id and birth_chart:
            try:
                cached_chart = cache.get(f"birth_chart:{user_id}")
                if not cached_chart:
                    cache.set(f"birth_chart:{user_id}", birth_chart)
                else:
                    birth_chart = birth_chart or cached_chart
            except Exception:
                pass  # Continue without caching
        
        # Save user message to CloudKit if authenticated
        if user_id:
            try:
                cloudkit.save_chat_message({
                    "userProfileId": user_id,
                    "conversationId": conv_id,
                    "content": message,
                    "isUser": True,
                })
            except Exception:
                pass  # Continue without saving
        
        # Generate AI response
        try:
            resp = gemini.send_message(
                message,
                conversation_history=history,
                system_prompt={"birthChart": birth_chart, "transits": transits},
            )
            ai_reply = resp.get("reply", "I'm sorry, I couldn't generate a response at this time.")
        except Exception:
            ai_reply = "I'm experiencing some technical difficulties. Please try again later."
        
        # Save AI response to CloudKit if authenticated
        if user_id:
            try:
                cloudkit.save_chat_message({
                    "userProfileId": user_id,
                    "conversationId": conv_id,
                    "content": ai_reply,
                    "isUser": False,
                })
            except Exception:
                pass  # Continue without saving
        
        # Format response to match what iOS app expects        
        message_id = str(uuid.uuid4())
        
        response = {
            'id': message_id,
            'userProfileId': user_id or 'anonymous',
            'conversationId': conv_id,
            'content': ai_reply,
            'response': ai_reply,  # iOS app might expect this key
            'isUser': 0,
            'messageType': 'text',
            'timestamp': datetime.utcnow().isoformat(),
            'suggestedFollowUps': [
                "What's my love forecast? 💖",
                "Career guidance? ⭐",
                "Today's energy? ☀️",
                "Mercury retrograde effects? ☿",
                "Best time for decisions? 🌙",
            ]
        }
        
        return jsonify(response)
        
    except Exception as e:
        from flask import current_app
        current_app.logger.exception("Chat endpoint error")
        return jsonify({'error': 'Internal server error'}), 500
