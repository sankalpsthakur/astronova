"""
Chat Response Service - Generates personalized astrological responses using OpenAI.

This service creates context-aware chat responses based on:
- User's birth data (anonymized planetary positions)
- Current planetary transits
- Question content and category
- Astrological context as system prompt
"""

import os
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

try:
    from openai import OpenAI  # type: ignore
except Exception:  # pragma: no cover
    OpenAI = None  # type: ignore

from services.ephemeris_service import EphemerisService


class ChatResponseService:
    def __init__(self):
        self.ephem = EphemerisService()
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) if OpenAI else None
        self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    def _get_current_transits(self) -> Dict[str, Any]:
        """Get current planetary positions."""
        dt = datetime.utcnow()
        positions = self.ephem.get_positions_for_date(dt)
        return positions.get("planets", {})

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

        # Get current transits
        transits = self._get_current_transits()

        # Get natal positions if birth data available
        natal = self._get_natal_positions(birth_data) if birth_data else None
        has_birth_data = natal is not None

        # Build system prompt with astrological context
        system_prompt = self._build_system_prompt(transits, natal, category)

        if not self.client:
            reply = self._fallback_response(transits, category)
            follow_ups = self._generate_follow_ups(category, has_birth_data)
            return reply, follow_ups

        try:
            # Call OpenAI
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

        except Exception as e:
            # Fallback to template-based response if OpenAI fails
            reply = self._fallback_response(transits, category)
            print(f"[ChatService] OpenAI error, using fallback: {e}")

        # Generate follow-ups
        follow_ups = self._generate_follow_ups(category, has_birth_data)

        return reply, follow_ups

    def _fallback_response(self, transits: Dict[str, Any], category: str) -> str:
        """Fallback template response if OpenAI is unavailable."""
        sun_sign = transits.get("sun", {}).get("sign", "the cosmos")
        moon_sign = transits.get("moon", {}).get("sign", "the stars")

        fallbacks = {
            "love": f"With the Moon in {moon_sign}, emotional connections are highlighted. Trust your heart's wisdom today.",
            "career": f"The Sun in {sun_sign} illuminates your professional path. Focus on what truly matters to you.",
            "health": f"Current planetary energies support mindful self-care. Listen to what your body needs.",
            "spiritual": f"The cosmos invites deeper reflection. Take time for stillness and inner listening.",
            "current": f"With the Moon in {moon_sign}, today favors intuitive action and emotional awareness.",
            "future": f"The planetary alignments suggest positive momentum ahead. Stay open to opportunities.",
            "general": f"The Sun in {sun_sign} and Moon in {moon_sign} create a unique blend of energies. Trust your journey.",
        }

        return fallbacks.get(category, fallbacks["general"])
