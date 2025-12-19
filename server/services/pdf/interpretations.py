from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .themes import ReportTheme


# Domain-specific context for interpretations
# Each domain has a prefix that frames the interpretation
DOMAIN_CONTEXT: dict[str, dict[str, str]] = {
    "love": {
        "sun_prefix": "In matters of love and relationships, ",
        "moon_prefix": "Your emotional needs in partnership show through ",
        "asc_prefix": "Partners first perceive you as ",
        "suffix": " This shapes how you give and receive affection.",
    },
    "career": {
        "sun_prefix": "In your professional life, ",
        "moon_prefix": "Your work satisfaction depends on ",
        "asc_prefix": "Colleagues and clients see you as ",
        "suffix": " Use this awareness for career alignment.",
    },
    "money": {
        "sun_prefix": "Your relationship with wealth reflects ",
        "moon_prefix": "Your spending patterns are influenced by ",
        "asc_prefix": "In financial dealings, you present as ",
        "suffix": " This affects your money mindset.",
    },
    "health": {
        "sun_prefix": "Your vitality and energy stem from ",
        "moon_prefix": "Your emotional wellness requires ",
        "asc_prefix": "Your body type and constitution show ",
        "suffix": " Honor this in your wellness routine.",
    },
    "family": {
        "sun_prefix": "In family dynamics, your role is shaped by ",
        "moon_prefix": "Your sense of home and belonging needs ",
        "asc_prefix": "Family members experience you as ",
        "suffix": " This influences your home life.",
    },
    "spiritual": {
        "sun_prefix": "Your soul purpose is expressed through ",
        "moon_prefix": "Your inner sanctuary is nurtured by ",
        "asc_prefix": "Your spiritual presence radiates as ",
        "suffix": " This guides your path of meaning.",
    },
    "general": {
        "sun_prefix": "",
        "moon_prefix": "",
        "asc_prefix": "",
        "suffix": "",
    },
}


@dataclass(frozen=True)
class SignTraits:
    name: str
    element: str
    modality: str
    keywords: tuple[str, ...]
    gift: str
    growth_edge: str
    practice: str


SIGN_TRAITS: tuple[SignTraits, ...] = (
    SignTraits(
        name="Aries",
        element="Fire",
        modality="Cardinal",
        keywords=("initiative", "courage", "directness"),
        gift="You lead with honesty and momentum. Starting is natural for you.",
        growth_edge="Impulsiveness can outrun strategy; patience is the lesson.",
        practice="Pause, pick the right battle, then commit to follow-through.",
    ),
    SignTraits(
        name="Taurus",
        element="Earth",
        modality="Fixed",
        keywords=("stability", "sensuality", "endurance"),
        gift="You build steadily and value what lasts. Consistency is your power.",
        growth_edge="Comfort can become inertia; change feels harder than it is.",
        practice="Stay flexible: make small upgrades instead of resisting shifts.",
    ),
    SignTraits(
        name="Gemini",
        element="Air",
        modality="Mutable",
        keywords=("curiosity", "communication", "adaptability"),
        gift="You learn fast and connect ideas and people with ease.",
        growth_edge="Too many threads can dilute impact; focus is the key.",
        practice="Choose one theme to go deep on, then share what you learn.",
    ),
    SignTraits(
        name="Cancer",
        element="Water",
        modality="Cardinal",
        keywords=("care", "protection", "memory"),
        gift="You sense needs quickly and create belonging through warmth.",
        growth_edge="Mood and defensiveness can close you off when you need support.",
        practice="Name your needs early and set boundaries that protect tenderness.",
    ),
    SignTraits(
        name="Leo",
        element="Fire",
        modality="Fixed",
        keywords=("creativity", "pride", "warmth"),
        gift="You inspire through presence and heart. You are built to shine.",
        growth_edge="Ego sensitivity can turn feedback into threat; stay open.",
        practice="Lead with generosity: share credit, create space, stay playful.",
    ),
    SignTraits(
        name="Virgo",
        element="Earth",
        modality="Mutable",
        keywords=("discernment", "service", "craft"),
        gift="You improve systems and notice what others miss. Precision is a gift.",
        growth_edge="Over-analysis can block action; perfection is a trap.",
        practice="Aim for progress: ship the first version, then refine.",
    ),
    SignTraits(
        name="Libra",
        element="Air",
        modality="Cardinal",
        keywords=("balance", "partnership", "aesthetics"),
        gift="You harmonize people and create fairness through perspective.",
        growth_edge="Indecision can appear when you try to please everyone.",
        practice="Choose by values: decide what matters, then negotiate the rest.",
    ),
    SignTraits(
        name="Scorpio",
        element="Water",
        modality="Fixed",
        keywords=("depth", "intensity", "transformation"),
        gift="You go to the root and regenerate after endings. Truth matters to you.",
        growth_edge="Control and suspicion can replace trust when you feel exposed.",
        practice="Practice honest vulnerability and release what you cannot control.",
    ),
    SignTraits(
        name="Sagittarius",
        element="Fire",
        modality="Mutable",
        keywords=("growth", "meaning", "adventure"),
        gift="You expand horizons and lift morale through optimism and vision.",
        growth_edge="Restlessness can skip the boring steps that make dreams real.",
        practice="Ground big ideas in habits: one plan, one schedule, repeat.",
    ),
    SignTraits(
        name="Capricorn",
        element="Earth",
        modality="Cardinal",
        keywords=("ambition", "structure", "mastery"),
        gift="You build long-term and earn trust through responsibility.",
        growth_edge="Overwork can harden you; success needs recovery too.",
        practice="Make rest strategic: design systems that sustain your pace.",
    ),
    SignTraits(
        name="Aquarius",
        element="Air",
        modality="Fixed",
        keywords=("innovation", "community", "independence"),
        gift="You think ahead and improve the collective through originality.",
        growth_edge="Detachment can read as distance; connection still matters.",
        practice="Stay human: share feelings, not just ideas, and keep collaboration alive.",
    ),
    SignTraits(
        name="Pisces",
        element="Water",
        modality="Mutable",
        keywords=("empathy", "imagination", "spirituality"),
        gift="You feel deeply and create meaning through intuition and art.",
        growth_edge="Escapism can blur boundaries; clarity is compassion.",
        practice="Use simple limits to protect your sensitivity and energy.",
    ),
)


def traits_for_sign(sign: str | None, *, sign_names: list[str]) -> SignTraits | None:
    if not isinstance(sign, str):
        return None
    try:
        idx = sign_names.index(sign)
    except ValueError:
        return None
    if idx < 0 or idx >= len(SIGN_TRAITS):
        return None
    return SIGN_TRAITS[idx]


def placement_bullets(
    placement: str,
    traits: SignTraits,
    *,
    theme: ReportTheme,
    domain: Optional[str] = None,
) -> tuple[str, str, str]:
    """Generate domain-aware interpretation bullets for a placement."""
    placement_key = (placement or "").strip().lower()
    ctx = DOMAIN_CONTEXT.get(domain or "general", DOMAIN_CONTEXT["general"])

    if placement_key in {"moon"}:
        prefix = ctx.get("moon_prefix", "")
        base_gift = traits.gift.lower() if prefix else traits.gift
        return (
            f"Emotional gift: {prefix}{base_gift}",
            f"Stress pattern: {traits.growth_edge}",
            f"Nourishment: {traits.practice}",
        )
    if placement_key in {"ascendant", "lagna", "rising"}:
        prefix = ctx.get("asc_prefix", "")
        keywords_str = ", ".join(traits.keywords)
        base_approach = f"{traits.element} + {traits.modality} ({keywords_str})"
        return (
            f"First impression: {prefix}{base_approach.lower() if prefix else base_approach}",
            f"Blind spot: {traits.growth_edge}",
            f"Aligned approach: {traits.practice}",
        )
    # Default: Sun / core identity.
    prefix = ctx.get("sun_prefix", "")
    base_gift = traits.gift.lower() if prefix else traits.gift
    return (
        f"Core gift: {prefix}{base_gift}",
        f"Growth edge: {traits.growth_edge}",
        f"Alignment: {traits.practice}",
    )


def synthesis_line(sun: SignTraits | None, moon: SignTraits | None, *, theme: ReportTheme) -> str:
    if not sun or not moon:
        return f"Domain lens: {theme.focus}"

    pair = tuple(sorted((sun.element, moon.element)))
    combos: dict[tuple[str, str], str] = {
        ("Air", "Air"): "Air + Air emphasizes thought, conversation, and perspective. Move from ideas to decisions.",
        ("Earth", "Earth"): "Earth + Earth builds steadily. Momentum grows when you choose consistency over intensity.",
        ("Fire", "Fire"): "Fire + Fire amplifies drive and confidence. Aim your energy so it does not scatter.",
        ("Water", "Water"): "Water + Water deepens intuition and empathy. Protect boundaries to avoid emotional overwhelm.",
        ("Air", "Earth"): "Air + Earth blends ideas with execution. Write the plan, then do the next concrete step.",
        ("Air", "Fire"): "Air + Fire thrives on movement and inspiration. Let curiosity turn into action.",
        ("Air", "Water"): "Air + Water mixes mind and sensitivity. Name feelings clearly to avoid mixed signals.",
        ("Earth", "Fire"): "Earth + Fire combines ambition with stamina. Pace yourself and keep the long view.",
        ("Earth", "Water"): "Earth + Water is steady and caring. Build safe routines that support your heart.",
        ("Fire", "Water"): "Fire + Water brings passion and depth. Honor both desire and sensitivity.",
    }
    combo = combos.get(pair, "Your Sun and Moon create a unique blend of drive and needs.")
    return f"{combo} Domain lens: {theme.focus}"


DASHA_THEMES: dict[str, tuple[str, str, str]] = {
    "sun": (
        "Theme: visibility, leadership, confidence.",
        "Best use: take responsibility and clarify direction.",
        "Watch for: pride or rushing when tired.",
    ),
    "moon": (
        "Theme: home, emotions, belonging.",
        "Best use: stabilize routines and protect mental health.",
        "Watch for: mood-led decisions or withdrawal.",
    ),
    "mars": (
        "Theme: action, drive, courage.",
        "Best use: train skills, compete, and cut what drains you.",
        "Watch for: conflict, impatience, or burnout.",
    ),
    "mercury": (
        "Theme: learning, communication, trade.",
        "Best use: study, write, negotiate, build networks.",
        "Watch for: anxiety from overthinking or scattered priorities.",
    ),
    "jupiter": (
        "Theme: growth, opportunity, mentors.",
        "Best use: expand through education, travel, and big-picture planning.",
        "Watch for: excess, promises without follow-through.",
    ),
    "venus": (
        "Theme: love, values, aesthetics.",
        "Best use: improve relationships and align choices with what you truly value.",
        "Watch for: people-pleasing or overspending.",
    ),
    "saturn": (
        "Theme: discipline, structure, mastery.",
        "Best use: build systems, set boundaries, and commit to long-term work.",
        "Watch for: pessimism or carrying everything alone.",
    ),
    "rahu": (
        "Theme: ambition, novelty, worldly pull.",
        "Best use: take bold bets and learn fast, while staying ethical.",
        "Watch for: obsession, shortcuts, or unstable desire.",
    ),
    "ketu": (
        "Theme: release, detachment, spiritual clarity.",
        "Best use: simplify, let go, and deepen intuition.",
        "Watch for: avoidance of practical responsibilities.",
    ),
}


def dasha_bullets(lord: str | None) -> tuple[str, str, str] | None:
    if not isinstance(lord, str) or not lord.strip():
        return None
    key = lord.strip().lower()
    return DASHA_THEMES.get(key)

