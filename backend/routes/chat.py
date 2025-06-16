from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.security import HTTPBearer
from slowapi import Limiter
from slowapi.util import get_remote_address

from models.schemas import ChatRequest
from services.claude_ai import ClaudeService
from services.cloudkit_service import CloudKitService
from services.cache_service import cache

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
security = HTTPBearer(auto_error=False)
claude = ClaudeService()
cloudkit = CloudKitService()

def get_current_user(token = Depends(security)):
    """Extract user ID from JWT token if present"""
    if token:
        # TODO: Implement JWT validation
        # For now, return None for optional authentication
        pass
    return None

@router.post('/send')
@limiter.limit("30/minute")
async def send_message(request: Request, data: ChatRequest, user_id = Depends(get_current_user)):
    try:
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
            cloudkit.save_chat_message({
                "user_id": user_id,
                "conversation_id": conv_id,
                "content": data.message,
                "is_user": True,
            })

        resp = claude.send_message(
            data.message,
            conversation_history=history,
            system_prompt={"birthChart": birth_chart, "transits": transits},
        )

        if user_id:
            cloudkit.save_chat_message({
                "user_id": user_id,
                "conversation_id": conv_id,
                "content": resp.get("reply"),
                "is_user": False,
            })

        return {
            "reply": resp.get("reply"),
            "messageId": resp.get("message_id"),
            "suggestedFollowUps": [
                "What's my love forecast? 💖",
                "Career guidance? ⭐",
                "Today's energy? ☀️",
                "Mercury retrograde effects? ☿",
                "Best time for decisions? 🌙",
            ],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))