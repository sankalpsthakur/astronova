import logging
import os
import requests
import json

logger = logging.getLogger(__name__)

class ClaudeService:
    """Gemini API wrapper (formerly Claude)"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY")
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
        if not self.api_key:
            logger.warning("No Gemini API key provided, using mock responses")
    
    def send_message(self, message, conversation_history=None, system_prompt=None):
        if not self.api_key:
            logger.info("Mock Gemini API call - no API key")
            reply = "This is a mock reply to: " + message
            return {"reply": reply, "message_id": "mock"}
        
        try:
            # Use correct Gemini API format
            headers = {
                "x-goog-api-key": self.api_key,
                "Content-Type": "application/json"
            }
            
            # Prepare the request body for Gemini (correct format)
            contents = []
            if system_prompt:
                # Add system prompt as first user message
                full_message = f"System: {system_prompt}\n\nUser: {message}"
            else:
                full_message = message
                
            contents.append({
                "parts": [{"text": full_message}]
            })
            
            payload = {
                "contents": contents,
                "generationConfig": {
                    "maxOutputTokens": 1000,
                    "temperature": 0.7
                }
            }
            
            response = requests.post(self.base_url, headers=headers, json=payload)
            response.raise_for_status()
            
            result = response.json()
            candidate = result["candidates"][0]
            
            # Handle the response structure properly
            if "content" in candidate and "parts" in candidate["content"]:
                reply = candidate["content"]["parts"][0]["text"]
            else:
                # Fallback if structure is different
                reply = f"Gemini response received but content structure unexpected. Status: {candidate.get('finishReason', 'unknown')}"
            
            return {"reply": reply, "message_id": "gemini"}
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise

    def generate_content(self, prompt, max_tokens=500):
        if not self.api_key:
            logger.info("Mock Gemini content generation - no API key")
            return "Generated content based on prompt"
        
        try:
            # Use correct Gemini API format with headers
            headers = {
                "x-goog-api-key": self.api_key,
                "Content-Type": "application/json"
            }
            
            payload = {
                "contents": [
                    {"parts": [{"text": prompt}]}
                ],
                "generationConfig": {
                    "maxOutputTokens": max_tokens,
                    "temperature": 0.7
                }
            }
            
            response = requests.post(self.base_url, headers=headers, json=payload)
            response.raise_for_status()
            
            result = response.json()
            candidate = result["candidates"][0]
            
            # Handle the response structure properly
            if "content" in candidate and "parts" in candidate["content"]:
                return candidate["content"]["parts"][0]["text"]
            else:
                # Fallback if structure is different
                return f"Gemini response received but content structure unexpected. Status: {candidate.get('finishReason', 'unknown')}"
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise
