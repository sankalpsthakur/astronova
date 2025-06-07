import logging

logger = logging.getLogger(__name__)

class ClaudeService:
    """Simplified Claude API wrapper"""
    def send_message(self, message, conversation_history=None, system_prompt=None):
        logger.info("Mock Claude API call")
        reply = "This is a mock reply to: " + message
        return {"reply": reply, "message_id": "mock"}

    def generate_content(self, prompt, max_tokens=500):
        logger.info("Mock Claude content generation")
        return "Generated content based on prompt"
