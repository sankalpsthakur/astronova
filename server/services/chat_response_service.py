"""
Chat Response Service - Generates personalized astrological responses using Gemini or OpenAI.

This service creates context-aware chat responses based on:
- User's birth data (anonymized planetary positions)
- Current planetary transits
- Question content and category
- Astrological context as system prompt
"""

import logging
import os
import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

# Try to import Gemini first, then fall back to OpenAI
try:
    import google.generativeai as genai  # type: ignore
except Exception:  # pragma: no cover
    genai = None  # type: ignore

try:
    from openai import OpenAI  # type: ignore
except Exception:  # pragma: no cover
    OpenAI = None  # type: ignore

from services.ephemeris_service import EphemerisService

logger = logging.getLogger(__name__)


class ChatServiceError(RuntimeError):
    """Raised when the chat pipeline cannot reach the AI provider."""


class ChatResponseService:
    def __init__(self):
        self.ephem = EphemerisService()

        # Prefer Gemini, fall back to OpenAI
        gemini_key = os.getenv("GEMINI_API_KEY")
        openai_key = os.getenv("OPENAI_API_KEY")

        if gemini_key and genai:
            genai.configure(api_key=gemini_key)
            self.client_type = "gemini"
            self.client = genai.GenerativeModel(os.getenv("GEMINI_MODEL", "gemini-1.5-flash"))
            self.model = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
        elif openai_key and OpenAI:
            self.client_type = "openai"
            self.client = OpenAI(api_key=openai_key)
            self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        else:
            self.client_type = None
            self.client = None
            self.model = None

        if self.client_type:
            logger.info("ChatResponseService initialized provider=%s model=%s", self.client_type, self.model)
        else:
            logger.warning("ChatResponseService initialized without AI provider configured")

        self._transit_cache: Optional[tuple[Dict[str, Any], datetime]] = None

    def _get_current_transits(self) -> Dict[str, Any]:
        """Get current planetary positions."""
        now = datetime.utcnow()
        if self._transit_cache and self._transit_cache[1] > now:
            logger.debug("Transit cache hit")
            return self._transit_cache[0]

        logger.debug("Transit cache miss; computing current transits")
        positions = self.ephem.get_positions_for_date(now)
        transits = positions.get("planets", {})
        self._transit_cache = (transits, now + timedelta(seconds=60))
        return transits

    def _get_natal_positions(self, birth_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Get natal chart positions from birth data."""
        if not birth_data or not birth_data.get("birth_date"):
            return None

        try:
            birth_date = birth_data["birth_date"]
            birth_time = birth_data.get("birth_time", "12:00")

            # Parse date and time
            if "T" in birth_date:
                dt = datetime.fromisoformat(birth_date.replace("Z", ""))
            else:
                dt = datetime.strptime(f"{birth_date} {birth_time}", "%Y-%m-%d %H:%M")

            positions = self.ephem.get_positions_for_date(dt)
            return positions.get("planets", {})
        except Exception:
            logger.exception("Failed to compute natal positions from birth data")
            return None

    def _build_system_prompt(
        self,
        transits: Dict[str, Any],
        natal: Optional[Dict[str, Any]] = None,
        category: str = "general"
    ) -> str:
        """Build astrological context as system prompt."""

        # Format current transits
        transit_lines = []
        for planet, data in transits.items():
            if isinstance(data, dict):
                sign = data.get("sign", "Unknown")
                degree = data.get("longitude", 0) % 30
                retrograde = " (Retrograde)" if data.get("speed", 1) < 0 else ""
                transit_lines.append(f"  - {planet.capitalize()}: {sign} {degree:.1f}°{retrograde}")

        transit_text = "\n".join(transit_lines) if transit_lines else "  - Transits unavailable"

        # Format natal positions if available
        natal_text = ""
        if natal:
            natal_lines = []
            for planet, data in natal.items():
                if isinstance(data, dict):
                    sign = data.get("sign", "Unknown")
                    degree = data.get("longitude", 0) % 30
                    natal_lines.append(f"  - {planet.capitalize()}: {sign} {degree:.1f}°")

            if natal_lines:
                natal_text = f"""
USER'S NATAL CHART (Birth Positions):
{chr(10).join(natal_lines)}
"""

        # Category-specific focus
        category_focus = {
            "love": "Focus on Venus, Moon, and 7th house matters. Discuss relationship dynamics, emotional connections, and compatibility.",
            "career": "Focus on Saturn, Jupiter, and 10th house matters. Discuss professional growth, ambition, and career timing.",
            "health": "Focus on Mars, Sun, and 6th house matters. Discuss vitality, energy levels, and wellness practices.",
            "spiritual": "Focus on Jupiter, Neptune, and 12th house matters. Discuss soul growth, intuition, and higher purpose.",
            "current": "Focus on Moon transits and daily influences. Discuss present energies and immediate guidance.",
            "future": "Focus on outer planet transits and upcoming shifts. Discuss timing and preparation.",
            "general": "Provide balanced guidance across all life areas based on the overall planetary picture."
        }

        focus = category_focus.get(category, category_focus["general"])

        system_prompt = f"""You are a wise, compassionate Vedic astrologer oracle. You provide personalized astrological guidance based on planetary positions and transits.

CURRENT PLANETARY TRANSITS (Today's Sky):
{transit_text}
{natal_text}
GUIDANCE FOCUS: {focus}

RESPONSE STYLE:
- Be warm, insightful, and empowering
- Reference specific planetary positions naturally (e.g., "With Venus in Sagittarius...")
- If natal chart is available, relate transits to their birth positions
- Keep responses concise but meaningful (2-4 sentences)
- Avoid generic platitudes - be specific to the cosmic weather
- End with an actionable insight or reflection prompt
- Do NOT mention that you're an AI or that this is generated

Remember: You're interpreting the cosmic patterns, not predicting fate. Empower the user with awareness."""

        return system_prompt

    def _classify_question(self, message: str) -> str:
        """Classify the user's question into a category."""
        message_lower = message.lower()

        if any(word in message_lower for word in ["love", "relationship", "partner", "romantic", "dating", "marriage", "heart"]):
            return "love"
        elif any(word in message_lower for word in ["career", "job", "work", "professional", "business", "money", "financial"]):
            return "career"
        elif any(word in message_lower for word in ["health", "wellness", "energy", "vitality", "physical", "mental", "body"]):
            return "health"
        elif any(word in message_lower for word in ["spiritual", "meditation", "soul", "purpose", "meaning", "growth", "dharma"]):
            return "spiritual"
        elif any(word in message_lower for word in ["today", "now", "current", "this moment"]):
            return "current"
        elif any(word in message_lower for word in ["future", "upcoming", "next", "will", "going to", "when"]):
            return "future"
        else:
            return "general"

    def _generate_follow_ups(self, category: str, has_birth_data: bool) -> List[str]:
        """Generate contextual follow-up questions."""
        base_follow_ups = {
            "love": [
                "What do my Venus placements say about my love style?",
                "How can I attract more meaningful connections?",
                "What's the best timing for relationship conversations?",
            ],
            "career": [
                "What career path aligns with my chart?",
                "When is the best time for a job change?",
                "How can I maximize my professional potential?",
            ],
            "health": [
                "What wellness practices suit my chart?",
                "How can I boost my energy levels?",
                "What should I focus on for better health?",
            ],
            "spiritual": [
                "What's my soul's purpose?",
                "How can I deepen my spiritual practice?",
                "What lessons am I here to learn?",
            ],
            "current": [
                "What should I focus on this week?",
                "How do current transits affect me?",
                "What opportunities are coming soon?",
            ],
            "future": [
                "What does the next month hold?",
                "When is the best time to start new projects?",
                "What should I prepare for?",
            ],
            "general": [
                "What are my biggest strengths?",
                "What's the overall energy right now?",
                "How can I make the most of today?",
            ],
        }

        follow_ups = base_follow_ups.get(category, base_follow_ups["general"])

        if not has_birth_data:
            follow_ups = follow_ups[:2] + ["Share my birth details for personalized insights"]

        return follow_ups

    def generate_response(
        self, message: str, user_id: Optional[str] = None, birth_data: Optional[Dict[str, Any]] = None
    ) -> Tuple[str, List[str]]:
        """
        Generate a personalized astrological response.

        Args:
            message: The user's question/message
            user_id: Optional user ID
            birth_data: Optional birth data dict

        Returns:
            Tuple of (response_text, suggested_follow_ups)
        """
        # Classify the question
        category = self._classify_question(message)
        message_len = len(message or "")

        logger.info(
            "Chat request provider=%s category=%s message_len=%d has_birth_data=%s",
            self.client_type,
            category,
            message_len,
            bool(birth_data),
        )

        # Get current transits
        transits = self._get_current_transits()

        # Get natal positions if birth data available
        natal = self._get_natal_positions(birth_data) if birth_data else None
        has_birth_data = natal is not None

        # Build system prompt with astrological context
        system_prompt = self._build_system_prompt(transits, natal, category)

        if not self.client:
            logger.error("Chat request rejected: AI client not configured")
            raise ChatServiceError("AI client not configured - set GEMINI_API_KEY or OPENAI_API_KEY")

        try:
            start = time.perf_counter()
            if self.client_type == "gemini":
                # Call Gemini API
                full_prompt = f"{system_prompt}\n\nUser Question: {message}\n\nOracle Response:"
                response = self.client.generate_content(
                    full_prompt,
                    generation_config=genai.GenerationConfig(
                        max_output_tokens=300,
                        temperature=0.8,
                    )
                )
                reply = response.text.strip()

            elif self.client_type == "openai":
                # Call OpenAI API
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": message}
                    ],
                    max_tokens=300,
                    temperature=0.8,
                )
                reply = response.choices[0].message.content.strip()

            else:
                raise ChatServiceError("No AI provider configured")

            elapsed_ms = (time.perf_counter() - start) * 1000
            logger.info(
                "Chat response generated provider=%s category=%s duration_ms=%.2f",
                self.client_type,
                category,
                elapsed_ms,
            )

        except Exception as e:
            logger.exception(
                "AI request failed provider=%s category=%s message_len=%d",
                self.client_type,
                category,
                message_len,
            )
            raise ChatServiceError(f"AI request failed ({self.client_type})") from e

        # Generate follow-ups
        follow_ups = self._generate_follow_ups(category, has_birth_data)

        return reply, follow_ups
