import logging
import os
import requests
import json

logger = logging.getLogger(__name__)

class GeminiService:
    """Gemini API wrapper for AI-powered astrological content generation"""
    
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
            
            response = requests.post(self.base_url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            
            # Check if there are candidates
            if "candidates" not in result or not result["candidates"]:
                return {"reply": "I apologize, but I'm unable to process your request at the moment. Please try again.", "message_id": "gemini"}
            
            candidate = result["candidates"][0]
            
            # Check for finish reason indicating token limit or other issues
            finish_reason = candidate.get("finishReason", "")
            if finish_reason == "MAX_TOKENS":
                # Return the actual content if available, don't mention truncation in chat
                if "content" in candidate and "parts" in candidate["content"]:
                    reply = candidate["content"]["parts"][0]["text"]
                else:
                    reply = "I've prepared a detailed response for you about your cosmic journey and what the stars reveal."
            elif "content" in candidate and "parts" in candidate["content"]:
                reply = candidate["content"]["parts"][0]["text"]
            else:
                # Fallback for other cases
                reply = "I understand your question. Let me provide you with guidance based on your cosmic energies."
            
            return {"reply": reply, "message_id": "gemini"}
        except requests.exceptions.Timeout:
            logger.error("Gemini API request timed out")
            return {"reply": "I'm experiencing some delays. Let me provide you with guidance based on cosmic wisdom.", "message_id": "timeout"}
        except requests.exceptions.ConnectionError:
            logger.error("Failed to connect to Gemini API")
            return {"reply": "I'm temporarily unable to connect to the cosmic network. Please try again in a moment.", "message_id": "connection_error"}
        except requests.exceptions.RequestException as e:
            logger.error(f"Gemini API request error: {e}")
            return {"reply": "I'm here to help you navigate the stars. What would you like to know about your cosmic journey?", "message_id": "error"}
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            return {"reply": "The universe has many mysteries. Let me share some cosmic insights with you.", "message_id": "error"}

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
            
            response = requests.post(self.base_url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            
            # Check if there are candidates
            if "candidates" not in result or not result["candidates"]:
                return "Today's cosmic energies bring unique opportunities for growth and self-discovery. Trust your intuition and embrace the journey ahead."
            
            candidate = result["candidates"][0]
            
            # Check for finish reason indicating token limit or other issues
            finish_reason = candidate.get("finishReason", "")
            if finish_reason == "MAX_TOKENS":
                # Return actual content if available, not an error message
                if "content" in candidate and "parts" in candidate["content"]:
                    return candidate["content"]["parts"][0]["text"]
                else:
                    return "The stars align to bring you guidance and clarity. Focus on your inner wisdom and trust the cosmic flow."
            elif "content" in candidate and "parts" in candidate["content"]:
                return candidate["content"]["parts"][0]["text"]
            else:
                # Fallback content
                return "The universe speaks through subtle signs today. Pay attention to synchronicities and trust your path."
        except requests.exceptions.Timeout:
            logger.error("Gemini API request timed out in generate_content")
            return "Today's cosmic energies are powerful and transformative. Trust your intuition as you navigate this special time."
        except requests.exceptions.ConnectionError:
            logger.error("Failed to connect to Gemini API in generate_content")
            return "The stars align in your favor today. Embrace new opportunities and trust in the cosmic flow of the universe."
        except requests.exceptions.RequestException as e:
            logger.error(f"Gemini API request error in generate_content: {e}")
            return "Your celestial journey continues with promise and potential. The universe supports your growth and transformation."
        except Exception as e:
            logger.error(f"Gemini API error in generate_content: {e}")
            return "The cosmic energies surrounding you bring wisdom and clarity. Trust in your path and embrace the journey ahead."
