import logging
import os
from anthropic import Anthropic

logger = logging.getLogger(__name__)

class ClaudeService:
    """Claude API wrapper using Anthropic SDK"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get("ANTHROPIC_API_KEY")
        if self.api_key:
            self.client = Anthropic(api_key=self.api_key)
        else:
            self.client = None
            logger.warning("No Anthropic API key provided, using mock responses")
    
    def send_message(self, message, conversation_history=None, system_prompt=None):
        if not self.client:
            logger.info("Mock Claude API call - no API key")
            reply = "This is a mock reply to: " + message
            return {"reply": reply, "message_id": "mock"}
        
        try:
            response = self.client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=1000,
                messages=[{"role": "user", "content": message}]
            )
            return {"reply": response.content[0].text, "message_id": response.id}
        except Exception as e:
            logger.error(f"Claude API error: {e}")
            raise

    def generate_content(self, prompt, max_tokens=500):
        if not self.client:
            logger.info("Mock Claude content generation - no API key")
            return "Generated content based on prompt"
        
        try:
            response = self.client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=max_tokens,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.content[0].text
        except Exception as e:
            logger.error(f"Claude API error: {e}")
            raise
