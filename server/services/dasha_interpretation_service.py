"""
Dasha Interpretation Service - Qualitative narratives for Vimshottari Dasha periods.
Provides educational content and contextual interpretations.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

# Detailed interpretations for each planetary dasha
DASHA_INTERPRETATIONS = {
    "Sun": {
        "title": "Sun Mahadasha",
        "duration_text": "6 years",
        "overview": "A period focused on establishing authority, building confidence, and expressing your core identity. This is a time for leadership and taking center stage in your chosen domain.",
        "typical_experiences": [
            "Recognition and advancement in career or public life",
            "Increased confidence and self-expression",
            "Strong focus on personal goals and ambitions",
            "Potential for government connections or authority roles",
            "Health focus, especially vitality and heart",
        ],
        "challenges": [
            "Ego conflicts or power struggles",
            "Strained relationships with authority figures",
            "Risk of arrogance or domineering behavior",
            "Potential health issues related to heat or eyes",
        ],
        "opportunities": [
            "Building lasting reputation and status",
            "Connecting with influential people",
            "Developing leadership skills",
            "Spiritual growth through self-realization",
        ],
        "advice": "Cultivate humility while pursuing your ambitions. Use your increased visibility for positive impact. Balance authority with compassion.",
        "ruling_qualities": ["Authority", "Vitality", "Leadership", "Ego", "Father"],
    },
    "Moon": {
        "title": "Moon Mahadasha",
        "duration_text": "10 years",
        "overview": "An emotionally rich period emphasizing intuition, relationships, and inner life. This dasha brings heightened sensitivity and focus on emotional security and nurturing connections.",
        "typical_experiences": [
            "Deep emotional bonds and family focus",
            "Intuitive insights and psychic sensitivity",
            "Interest in home, property, and domestic matters",
            "Career involving public interaction or service",
            "Connection with mother or maternal figures",
        ],
        "challenges": [
            "Emotional volatility and mood swings",
            "Anxiety or excessive worry",
            "Dependency issues in relationships",
            "Digestive or water-related health concerns",
        ],
        "opportunities": [
            "Developing emotional intelligence",
            "Healing family relationships",
            "Pursuing creative or nurturing professions",
            "Spiritual practices involving devotion",
        ],
        "advice": "Practice emotional self-regulation. Trust your intuition but verify with logic. Create safe spaces for yourself and others. Nurture without losing yourself.",
        "ruling_qualities": ["Emotions", "Mind", "Intuition", "Mother", "Nurturing"],
    },
    "Mars": {
        "title": "Mars Mahadasha",
        "duration_text": "7 years",
        "overview": "A dynamic period of action, courage, and ambition. This dasha energizes your drive to achieve, compete, and overcome obstacles through determination and willpower.",
        "typical_experiences": [
            "High energy and motivation for goals",
            "Success through courageous action",
            "Property acquisition or land matters",
            "Athletic or military pursuits",
            "Sibling relationships become prominent",
        ],
        "challenges": [
            "Impulsiveness and anger issues",
            "Conflicts and aggressive confrontations",
            "Accidents or injuries, especially burns or cuts",
            "Excessive risk-taking",
        ],
        "opportunities": [
            "Breakthrough achievements through effort",
            "Developing willpower and resilience",
            "Physical fitness and strength building",
            "Entrepreneurial ventures",
        ],
        "advice": "Channel your energy constructively. Practice patience before acting. Use courage wisely, not recklessly. Balance assertion with diplomacy.",
        "ruling_qualities": ["Energy", "Courage", "Action", "Will", "Siblings"],
    },
    "Mercury": {
        "title": "Mercury Mahadasha",
        "duration_text": "17 years",
        "overview": "A period emphasizing intellect, communication, and versatility. This lengthy dasha favors learning, business, networking, and developing multiple skills and interests.",
        "typical_experiences": [
            "Success in education and intellectual pursuits",
            "Business growth and commercial ventures",
            "Enhanced communication and networking",
            "Travel and diverse experiences",
            "Writing, teaching, or media opportunities",
        ],
        "challenges": [
            "Mental restlessness and scattered focus",
            "Nervous system sensitivity",
            "Superficiality or lack of depth",
            "Deceptive communication or misunderstandings",
        ],
        "opportunities": [
            "Mastering new skills and languages",
            "Building successful businesses",
            "Developing wit and adaptability",
            "Connecting diverse groups of people",
        ],
        "advice": "Focus your mental energy on meaningful goals. Practice deep work alongside breadth. Be honest in all communications. Calm your nervous system regularly.",
        "ruling_qualities": ["Intellect", "Communication", "Commerce", "Learning", "Adaptability"],
    },
    "Jupiter": {
        "title": "Jupiter Mahadasha",
        "duration_text": "16 years",
        "overview": "A highly auspicious period of expansion, wisdom, and fortune. This dasha brings opportunities for growth, learning, teaching, and spiritual development.",
        "typical_experiences": [
            "Prosperity and financial growth",
            "Advancement in career and status",
            "Marriage or significant relationships",
            "Spiritual awakening and higher learning",
            "Children and family blessings",
        ],
        "challenges": [
            "Overexpansion or overconfidence",
            "Weight gain or health excess",
            "Complacency due to good fortune",
            "Excessive optimism without planning",
        ],
        "opportunities": [
            "Achieving major life milestones",
            "Becoming a teacher or mentor",
            "Philosophical and spiritual growth",
            "Benefiting others through generosity",
        ],
        "advice": "Use this fortunate period wisely for long-term foundation building. Share your blessings with others. Pursue wisdom, not just knowledge. Stay humble in success.",
        "ruling_qualities": ["Wisdom", "Expansion", "Fortune", "Teaching", "Faith"],
    },
    "Venus": {
        "title": "Venus Mahadasha",
        "duration_text": "20 years",
        "overview": "The longest dasha period, emphasizing love, beauty, creativity, and material comfort. This is a time for enjoying life's pleasures and cultivating harmonious relationships.",
        "typical_experiences": [
            "Romantic relationships and marriage",
            "Artistic and creative expression",
            "Luxury, comfort, and aesthetic pursuits",
            "Success in entertainment or beauty industries",
            "Financial gains through partnerships",
        ],
        "challenges": [
            "Excessive indulgence or hedonism",
            "Relationship drama or infidelity",
            "Materialism over spiritual values",
            "Reproductive or hormonal health issues",
        ],
        "opportunities": [
            "Creating beautiful works or spaces",
            "Finding true love and partnership",
            "Developing refined taste and culture",
            "Balancing material and spiritual life",
        ],
        "advice": "Enjoy beauty and pleasure without attachment. Cultivate genuine love over superficial attraction. Use your charm for positive influence. Balance indulgence with discipline.",
        "ruling_qualities": ["Love", "Beauty", "Pleasure", "Harmony", "Luxury"],
    },
    "Saturn": {
        "title": "Saturn Mahadasha",
        "duration_text": "19 years",
        "overview": "A serious period of discipline, responsibility, and karmic lessons. This challenging but transformative dasha builds character through patience, hard work, and facing limitations.",
        "typical_experiences": [
            "Major life restructuring and maturation",
            "Career advancement through persistent effort",
            "Learning through hardship and delay",
            "Spiritual deepening through renunciation",
            "Service to others and society",
        ],
        "challenges": [
            "Delays, obstacles, and frustrations",
            "Depression or pessimism",
            "Health issues, especially bones and joints",
            "Isolation or separation from loved ones",
        ],
        "opportunities": [
            "Building unshakable foundations",
            "Developing patience and wisdom",
            "Achieving mastery through discipline",
            "Transcending material attachments",
        ],
        "advice": "Accept this as a time of maturation. Work hard without attachment to immediate results. Serve others to lighten your own burden. Find wisdom in restriction.",
        "ruling_qualities": ["Discipline", "Responsibility", "Patience", "Karma", "Structure"],
    },
    "Rahu": {
        "title": "Rahu Mahadasha",
        "duration_text": "18 years",
        "overview": "An intense period of worldly ambition, unconventional experiences, and material desires. This dasha brings opportunities through foreign connections, technology, and breaking boundaries.",
        "typical_experiences": [
            "Sudden rises in status or wealth",
            "Foreign travel, residence, or connections",
            "Success through innovation or technology",
            "Unconventional career paths",
            "Intense desires and obsessions",
        ],
        "challenges": [
            "Illusions, deception, or self-deception",
            "Obsessive behavior or addictions",
            "Anxiety and mental confusion",
            "Unexpected upheavals or scandals",
        ],
        "opportunities": [
            "Achieving worldly success rapidly",
            "Exploring new territories and ideas",
            "Benefiting from global connections",
            "Spiritual growth through disillusionment",
        ],
        "advice": "Question your desires and motivations. Avoid shortcuts and deception. Ground yourself in ethical principles. Use ambition for noble purposes.",
        "ruling_qualities": ["Ambition", "Illusion", "Foreign", "Innovation", "Obsession"],
    },
    "Ketu": {
        "title": "Ketu Mahadasha",
        "duration_text": "7 years",
        "overview": "A spiritually intense period of detachment, introspection, and liberation. This dasha reduces worldly focus and heightens spiritual awareness, often through loss or letting go.",
        "typical_experiences": [
            "Spiritual awakening and seeking",
            "Detachment from material pursuits",
            "Interest in mysticism or occult",
            "Unexpected losses or endings",
            "Psychic experiences or intuition",
        ],
        "challenges": [
            "Confusion and lack of direction",
            "Depression or apathy toward life",
            "Financial instability",
            "Health issues, especially mysterious ones",
        ],
        "opportunities": [
            "Deep spiritual realization",
            "Liberation from attachments",
            "Developing psychic abilities",
            "Understanding life's deeper meaning",
        ],
        "advice": "Embrace this as a spiritual journey. Let go of what no longer serves you. Seek wisdom from authentic teachers. Find peace in simplicity and solitude.",
        "ruling_qualities": ["Detachment", "Spirituality", "Liberation", "Moksha", "Mysticism"],
    },
}


class DashaInterpretationService:
    """Service for generating qualitative interpretations of dasha periods."""

    def __init__(self):
        pass

    def get_dasha_explanation(self, lord: str, level: str = "mahadasha") -> Dict[str, Any]:
        """
        Get comprehensive explanation for a dasha period.

        Args:
            lord: Planetary lord (Sun, Moon, etc.)
            level: Level of dasha (mahadasha, antardasha, pratyantardasha)

        Returns:
            Dictionary with educational content about the dasha
        """
        base_info = DASHA_INTERPRETATIONS.get(lord, {})

        if not base_info:
            return {
                "title": f"{lord} Dasha",
                "overview": f"A period ruled by {lord}, bringing its unique planetary influences.",
                "level": level,
            }

        # Adjust narrative based on level
        if level == "antardasha":
            title_suffix = " Antardasha (Sub-Period)"
            overview_prefix = "Within the larger cycle, this sub-period brings: "
        elif level == "pratyantardasha":
            title_suffix = " Pratyantardasha (Micro-Period)"
            overview_prefix = "In this brief micro-cycle: "
        else:
            title_suffix = " Mahadasha (Major Period)"
            overview_prefix = ""

        return {
            "lord": lord,
            "level": level,
            "title": base_info.get("title", f"{lord} Dasha") + (title_suffix if level != "mahadasha" else ""),
            "duration": base_info.get("duration_text", ""),
            "overview": overview_prefix + base_info.get("overview", ""),
            "typical_experiences": base_info.get("typical_experiences", []),
            "challenges": base_info.get("challenges", []),
            "opportunities": base_info.get("opportunities", []),
            "advice": base_info.get("advice", ""),
            "keywords": base_info.get("ruling_qualities", []),
        }

    def generate_period_narrative(
        self,
        mahadasha_lord: str,
        antardasha_lord: str,
        pratyantar_lord: Optional[str] = None,
        strength_data: Optional[Dict] = None,
        impact_scores: Optional[Dict] = None,
    ) -> str:
        """
        Generate a cohesive narrative for the current dasha combination.

        Combines Mahadasha, Antardasha, and optionally Pratyantardasha influences
        into a concise, insightful summary.

        Max 3 sentences as per requirements.
        """
        maha_keywords = DASHA_INTERPRETATIONS.get(mahadasha_lord, {}).get("ruling_qualities", [mahadasha_lord])[:2]
        antar_keywords = DASHA_INTERPRETATIONS.get(antardasha_lord, {}).get("ruling_qualities", [antardasha_lord])[:2]

        # Base narrative on combination
        if mahadasha_lord == antardasha_lord:
            narrative = f"The {mahadasha_lord} period is at full strength, emphasizing {', '.join(maha_keywords).lower()}. "
        else:
            narrative = f"The {mahadasha_lord} major period focuses on {', '.join(maha_keywords).lower()}, while the {antardasha_lord} sub-period adds themes of {', '.join(antar_keywords).lower()}. "

        # Add strength-based context if available
        if impact_scores:
            top_areas = sorted(impact_scores.items(), key=lambda x: x[1], reverse=True)[:2]
            areas_text = " and ".join([area for area, _ in top_areas])
            narrative += f"Expect significant influence on {areas_text}. "
        else:
            narrative += "This combination shapes your experiences across all life areas. "

        # Add actionable advice
        if strength_data and strength_data.get("strength_label") in ["weak", "moderate"]:
            narrative += "Patience and consistent effort will yield the best results."
        else:
            narrative += "Use this favorable time to advance your long-term goals."

        return narrative

    def explain_dasha_calculation(self, moon_longitude: float, starting_lord: str, balance_years: float) -> Dict[str, Any]:
        """
        Provide educational explanation of how the dasha was calculated.

        This helps users understand the mathematical basis.
        """
        # Calculate nakshatra
        nakshatra_span = 13.333333333333334
        nakshatra_index = int((moon_longitude % 360) / nakshatra_span)
        nakshatra_names = [
            "Ashwini",
            "Bharani",
            "Krittika",
            "Rohini",
            "Mrigashira",
            "Ardra",
            "Punarvasu",
            "Pushya",
            "Ashlesha",
            "Magha",
            "Purva Phalguni",
            "Uttara Phalguni",
            "Hasta",
            "Chitra",
            "Swati",
            "Vishakha",
            "Anuradha",
            "Jyeshtha",
            "Mula",
            "Purva Ashadha",
            "Uttara Ashadha",
            "Shravana",
            "Dhanishta",
            "Shatabhisha",
            "Purva Bhadrapada",
            "Uttara Bhadrapada",
            "Revati",
        ]

        nakshatra_name = nakshatra_names[min(nakshatra_index, 26)]
        degrees_in_nakshatra = (moon_longitude % 360) - (nakshatra_index * nakshatra_span)
        fraction_complete = degrees_in_nakshatra / nakshatra_span

        return {
            "title": "How Your Dasha Was Calculated",
            "steps": [
                {
                    "step": 1,
                    "title": "Moon's Position",
                    "description": f"Your Moon is at {moon_longitude:.2f}° sidereal longitude",
                },
                {
                    "step": 2,
                    "title": "Nakshatra Identification",
                    "description": f"This places the Moon in {nakshatra_name} nakshatra (#{nakshatra_index + 1} of 27)",
                },
                {
                    "step": 3,
                    "title": "Nakshatra Ruler",
                    "description": f"{nakshatra_name} is ruled by {starting_lord}, which determines your starting dasha",
                },
                {
                    "step": 4,
                    "title": "Balance Calculation",
                    "description": f"The Moon is {fraction_complete * 100:.1f}% through this nakshatra, leaving {balance_years:.2f} years of {starting_lord} dasha at birth",
                },
                {
                    "step": 5,
                    "title": "Progression",
                    "description": "Dashas progress through the 9 planets in sequence: Ketu → Venus → Sun → Moon → Mars → Rahu → Jupiter → Saturn → Mercury",
                },
            ],
            "nakshatra": nakshatra_name,
            "nakshatra_lord": starting_lord,
            "moon_longitude": round(moon_longitude, 2),
            "balance_years": round(balance_years, 2),
        }

    def get_transition_insights(
        self, current_lord: str, next_lord: str, days_until: int, impact_comparison: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Generate insights about an upcoming dasha transition.

        Returns actionable insights about what to expect and how to prepare.
        """
        current_info = DASHA_INTERPRETATIONS.get(current_lord, {})
        next_info = DASHA_INTERPRETATIONS.get(next_lord, {})

        # Determine transition character
        current_qualities = set(current_info.get("ruling_qualities", []))
        next_qualities = set(next_info.get("ruling_qualities", []))

        time_text = f"{days_until} days"
        if days_until > 365:
            time_text = f"{days_until // 365} years and {(days_until % 365) // 30} months"
        elif days_until > 30:
            time_text = f"{days_until // 30} months"

        summary = f"In {time_text}, you'll transition from {current_lord} to {next_lord} dasha. "

        if impact_comparison and impact_comparison.get("major_shifts"):
            shifts_text = ", ".join(impact_comparison["major_shifts"][:2])
            summary += f"Major changes: {shifts_text}. "
        else:
            summary += f"This brings a shift from {list(current_qualities)[:2]} themes to {list(next_qualities)[:2]} themes. "

        return {
            "current_lord": current_lord,
            "next_lord": next_lord,
            "days_until": days_until,
            "time_remaining": time_text,
            "summary": summary,
            "current_keywords": list(current_qualities)[:3],
            "next_keywords": list(next_qualities)[:3],
            "preparation_tips": [
                f"Reflect on your {current_lord} period experiences and lessons learned",
                f"Research {next_lord} dasha to understand upcoming themes",
                f"Set intentions aligned with {next_lord}'s energy",
            ],
            "impact_comparison": impact_comparison,
        }
