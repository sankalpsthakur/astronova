from __future__ import annotations

from dataclasses import dataclass

from .canvas import RGB


@dataclass(frozen=True)
class ReportTheme:
    key: str
    label: str
    accent: RGB
    accent_soft: RGB
    focus: str
    prompts: tuple[str, ...]
    actions: tuple[str, ...]
    watch_fors: tuple[str, ...]


THEMES: dict[str, ReportTheme] = {
    "general": ReportTheme(
        "general",
        "General",
        accent=RGB(0.68, 0.43, 0.94),
        accent_soft=RGB(0.28, 0.20, 0.48),
        focus="Big three placements + current timing.",
        prompts=(
            "What theme keeps repeating this month?",
            "What one habit would strengthen your foundation?",
            "What decision becomes easier with more patience?",
        ),
        actions=(
            "Choose one priority and protect it with a simple schedule.",
            "Track energy (sleep, mood, focus) for 7 days and adjust one lever.",
            "Write a 3-sentence intention for the next 30 days.",
        ),
        watch_fors=(
            "Overcommitting because you feel behind.",
            "Confusing urgency with importance.",
            "Ignoring rest until burnout forces it.",
        ),
    ),
    "love": ReportTheme(
        "love",
        "Love",
        accent=RGB(0.96, 0.36, 0.56),
        accent_soft=RGB(0.40, 0.14, 0.22),
        focus="Venus, Moon, and relationship dynamics.",
        prompts=(
            "Where can you ask for what you need more directly?",
            "What boundary protects your tenderness?",
            'What does "secure love" look like this week?',
        ),
        actions=(
            "Name one need and make a clear, kind request.",
            "Plan a low-pressure moment for connection (walk, tea, shared task).",
            "Notice triggers; pause 10 seconds before responding.",
        ),
        watch_fors=(
            "Mind-reading instead of asking.",
            "Overgiving to earn closeness.",
            "Escalating small friction into a story.",
        ),
    ),
    "career": ReportTheme(
        "career",
        "Career",
        accent=RGB(0.25, 0.58, 0.96),
        accent_soft=RGB(0.10, 0.22, 0.38),
        focus="Saturn structure + Jupiter growth cycles.",
        prompts=(
            "What skill would compound over 90 days?",
            "Where do you need better systems, not more effort?",
            "What’s the next smallest credible step?",
        ),
        actions=(
            "Pick one metric that matters and review it weekly.",
            "Ship one visible artifact (doc, demo, portfolio update).",
            "Ask for feedback from one high-signal person.",
        ),
        watch_fors=(
            "Perfectionism delaying output.",
            "Saying yes to work that dilutes your path.",
            "Skipping recovery and losing consistency.",
        ),
    ),
    "money": ReportTheme(
        "money",
        "Money",
        accent=RGB(0.24, 0.84, 0.62),
        accent_soft=RGB(0.08, 0.28, 0.22),
        focus="Values alignment, stability, and long-term planning.",
        prompts=(
            "What expense could you remove without loss of joy?",
            "What investment of time yields future freedom?",
            'What does "enough" mean for you right now?',
        ),
        actions=(
            "Set one rule that automates savings (even small).",
            "Audit subscriptions and cancel one misaligned expense.",
            'Define a single "money goal" for 30 days.',
        ),
        watch_fors=(
            "Impulse spending when stressed.",
            "All-or-nothing budgeting that doesn’t last.",
            "Avoiding the numbers and losing agency.",
        ),
    ),
    "health": ReportTheme(
        "health",
        "Health",
        accent=RGB(0.42, 0.90, 0.34),
        accent_soft=RGB(0.14, 0.30, 0.12),
        focus="Energy, recovery, and sustainable routines.",
        prompts=(
            "What would a 10% healthier day look like?",
            "Where are you ignoring a small signal?",
            "What helps your nervous system feel safe?",
        ),
        actions=(
            'Build a "minimum viable" routine you can keep on bad days.',
            "Hydrate + move lightly for 15 minutes daily.",
            "Prioritize sleep consistency for 7 nights.",
        ),
        watch_fors=(
            "Pushing through fatigue as a default.",
            "Over-optimizing and quitting.",
            "Using screens to numb instead of recover.",
        ),
    ),
    "family": ReportTheme(
        "family",
        "Family",
        accent=RGB(0.98, 0.76, 0.22),
        accent_soft=RGB(0.34, 0.26, 0.08),
        focus="Home, belonging, and emotional patterns.",
        prompts=(
            "What tradition do you want to continue or end?",
            "What conversation would bring relief?",
            "Where can you offer warmth without overgiving?",
        ),
        actions=(
            "Initiate one repairing conversation (short, specific).",
            "Create a small home ritual: tidy + light + music.",
            "Ask for help directly instead of hinting.",
        ),
        watch_fors=(
            "Carrying responsibilities alone.",
            "Replaying old roles automatically.",
            "Avoiding conflict and building resentment.",
        ),
    ),
    "spiritual": ReportTheme(
        "spiritual",
        "Spiritual",
        accent=RGB(0.42, 0.90, 0.86),
        accent_soft=RGB(0.14, 0.30, 0.28),
        focus="Meaning, intuition, and inner alignment.",
        prompts=(
            "What truth are you ready to admit to yourself?",
            "What practice returns you to center quickly?",
            "What are you releasing to make space?",
        ),
        actions=(
            "Spend 10 minutes in stillness (breath, prayer, meditation).",
            "Journal one page: what you’re learning, what you’re letting go of.",
            "Choose one act of service without seeking credit.",
        ),
        watch_fors=(
            "Spiritual bypassing of practical needs.",
            "Chasing certainty instead of presence.",
            "Isolation when support would help.",
        ),
    ),
}


def theme_for_report(report_type: str | None, domain: str | None = None) -> ReportTheme:
    """Choose a theme based on report type and optional domain."""
    if domain and domain in THEMES:
        return THEMES[domain]

    rt = (report_type or "").strip().lower()
    if rt in ("love_forecast",):
        return THEMES["love"]
    if rt in ("career_forecast",):
        return THEMES["career"]
    if rt in ("transit_report",):
        return THEMES["spiritual"]
    if rt in ("year_ahead",):
        return THEMES["family"]
    return THEMES["general"]
