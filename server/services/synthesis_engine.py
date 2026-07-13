"""
Synthesis Engine — Master composition service for the Cosmic Mirror.

Composes all analysis services (Rajayoga, Numerology, Prediction,
Dasha Interpretation, Planetary Strength) into a single unified response
for the Self tab.  This is the single backend call that turns four
separate analyses into one coherent story.

Architecture
------------
Each sub-service call is wrapped in try/except — a failure in one service
never crashes the entire response.  The synthesis narrative adapts: if a
section failed, it skips that reference rather than fabricating data.

The key intellectual work is in ``_compose_synthesis_narrative``, which
weaves archetype, dasha, constraints, and Loshu eigenvalues into a single
5–8 sentence paragraph that feels like a personalised reading, not a
machine concatenation of four reports.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from .numerology_service import NumerologyService
from .rajayoga_service import RajayogaService
from .prediction_service import PredictionService
from .dasha_interpretation_service import DashaInterpretationService
from .planetary_strength_service import PlanetaryStrengthService

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Dasha sequence (Vimshottari order, with year durations)
# ---------------------------------------------------------------------------
_DASHA_SEQUENCE: List[Tuple[str, int]] = [
    ("Ketu", 7),
    ("Venus", 20),
    ("Sun", 6),
    ("Moon", 10),
    ("Mars", 7),
    ("Rahu", 18),
    ("Jupiter", 16),
    ("Saturn", 19),
    ("Mercury", 17),
]

_DASHA_NAMES: List[str] = [name for name, _ in _DASHA_SEQUENCE]

# ---------------------------------------------------------------------------
# Dasha-planet concrete meaning snippets for narrative weaving
# ---------------------------------------------------------------------------
_DASHA_CONCRETE_MEANING: Dict[str, str] = {
    "Sun": (
        "activates your visibility engine — authority, leadership, and public "
        "identity come to the foreground"
    ),
    "Moon": (
        "pulls focus toward emotional infrastructure, intuition, and the "
        "domestic sphere — your inner world drives outer results"
    ),
    "Mars": (
        "ignites execution energy — drive, competition, and physical output "
        "accelerate; the cost of inaction rises sharply"
    ),
    "Mercury": (
        "activates your intellectual and commercial bandwidth — communication, "
        "trade, writing, and network intelligence compound"
    ),
    "Jupiter": (
        "expands whatever it touches — teaching, wisdom, fortune, and long-range "
        "bets pay off; over-extension is the shadow"
    ),
    "Venus": (
        "routes energy through relationships, aesthetics, and value creation — "
        "charm opens doors that effort alone cannot"
    ),
    "Saturn": (
        "compresses time and forces structural honesty — discipline, delay, and "
        "endurance build foundations that outlast you"
    ),
    "Rahu": (
        "amplifies ambition through unconventional channels — foreign connections, "
        "technology, and obsession drive breakthrough or burnout"
    ),
    "Ketu": (
        "dissolves attachments and strips non-essentials — clarity through loss, "
        "spiritual depth through detachment"
    ),
}

# ---------------------------------------------------------------------------
# SynthesisEngine
# ---------------------------------------------------------------------------


class SynthesisEngine:
    """Master composer that unifies all analysis services into the Cosmic Mirror."""

    def __init__(self) -> None:
        self._numerology = NumerologyService()
        self._rajayoga = RajayogaService()
        self._prediction = PredictionService()
        self._dasha_interp = DashaInterpretationService()
        self._strength = PlanetaryStrengthService()

    # =======================================================================
    # Public: compose_cosmic_mirror
    # =======================================================================

    def compose_cosmic_mirror(
        self,
        birth_data: Dict[str, Any],
        planet_data: Dict[str, Any],
        lagna: str,
        dasha_state: Dict[str, Any],
        user_priors: Optional[Dict[str, Any]] = None,
        phone_digit_sum: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Compose all services into the unified Cosmic Mirror response.

        Args:
            birth_data: ``{"date": "1999-12-24", "time": "08:02", ...}``
            planet_data: ``{"Sun": {"sign": "Sagittarius", "degree": 8.5, "house": 1}, ...}``
            lagna: Ascendant sign, e.g. ``"Sagittarius"``
            dasha_state: ``{"mahadasha_lord": "Mercury", "antardasha_lord": "Mercury", ...}``
            user_priors: Optional real-world context passed through to prediction.
            phone_digit_sum: Optional phone digit-sum passed through to numerology.

        Returns:
            Unified dict with keys archetype, matrix, constraints, loshu,
            current_month, peak_windows, dasha_pulse, synthesis_narrative,
            generated_at.
        """
        # -- Pre-processing ---------------------------------------------------
        dob_digits = self._extract_dob_digits(birth_data)
        normalized_dasha = self._normalize_dasha_state(dasha_state)
        start_date, end_date = self._compute_prediction_window()

        # -- Service calls (each isolated in try/except) ----------------------
        rajayoga_result = self._safe_call_rajayoga(planet_data, lagna)
        loshu_result = self._safe_call_numerology(dob_digits, phone_digit_sum)
        prediction_result = self._safe_call_prediction(
            birth_data, normalized_dasha, start_date, end_date, user_priors,
        )

        # -- Compose derived sections -----------------------------------------
        dasha_pulse = self._compose_dasha_pulse(dasha_state, planet_data)

        archetype_section = rajayoga_result.get("archetype", {"error": "unavailable"})
        constraints_section = rajayoga_result.get("constraints", [])
        synthesis_narrative = self._compose_synthesis_narrative(
            archetype_section,
            constraints_section,
            loshu_result,
            dasha_state,
            planet_data,
        )

        # -- Extract current_month from prediction timeline -------------------
        current_month = self._extract_current_month(prediction_result)

        # -- Extract peak_windows from prediction -----------------------------
        peak_windows = prediction_result.get("peak_windows", [])

        # -- Assemble unified response ----------------------------------------
        return {
            "archetype": rajayoga_result.get("archetype", {"error": "rajoyoga service failed"}),
            "matrix": rajayoga_result.get("optimization_matrix", {"error": "rajoyoga service failed"}),
            "constraints": rajayoga_result.get("constraints", []),
            "loshu": loshu_result,
            "current_month": current_month,
            "peak_windows": peak_windows,
            "dasha_pulse": dasha_pulse,
            "synthesis_narrative": synthesis_narrative,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    # =======================================================================
    # Safe service call wrappers
    # =======================================================================

    def _safe_call_rajayoga(
        self, planet_data: Dict[str, Any], lagna: str
    ) -> Dict[str, Any]:
        try:
            return self._rajayoga.full_rajayoga_report(planet_data, lagna)
        except Exception as exc:
            logger.error("Rajayoga service failed: %s", exc, exc_info=True)
            return {"error": str(exc)}

    def _safe_call_numerology(
        self, dob_digits: List[int], phone_digit_sum: Optional[int]
    ) -> Dict[str, Any]:
        try:
            return self._numerology.full_numerology_report(dob_digits, phone_digit_sum)
        except Exception as exc:
            logger.error("Numerology service failed: %s", exc, exc_info=True)
            return {"error": str(exc)}

    def _safe_call_prediction(
        self,
        birth_data: Dict[str, Any],
        dasha_state: Dict[str, Any],
        start_date: str,
        end_date: str,
        user_priors: Optional[Dict[str, Any]],
    ) -> Dict[str, Any]:
        try:
            return self._prediction.full_prediction_report(
                birth_data, dasha_state, start_date, end_date, user_priors,
            )
        except Exception as exc:
            logger.error("Prediction service failed: %s", exc, exc_info=True)
            return {"error": str(exc)}

    # =======================================================================
    # Pre-processing helpers (static)
    # =======================================================================

    @staticmethod
    def _extract_dob_digits(birth_data: Dict[str, Any]) -> List[int]:
        """Extract individual digits from the birth date string.

        "1999-12-24" → [1, 9, 9, 9, 1, 2, 2, 4]
        """
        date_str = birth_data.get("date", "")
        return [int(c) for c in date_str if c.isdigit()]

    @staticmethod
    def _normalize_dasha_state(dasha_state: Dict[str, Any]) -> Dict[str, Any]:
        """Convert flat-key dasha_state into the nested form the PredictionService expects.

        Input:  {"mahadasha_lord": "Mercury", "antardasha_lord": "Mercury", ...}
        Output: {"mahadasha": {"lord": "Mercury"}, "antardasha": {"lord": "Mercury"}}
        """
        return {
            "mahadasha": {"lord": dasha_state.get("mahadasha_lord", "")},
            "antardasha": {"lord": dasha_state.get("antardasha_lord", "")},
        }

    @staticmethod
    def _compute_prediction_window() -> Tuple[str, str]:
        """Return (start_date, end_date) covering today through 6 months out."""
        now = datetime.now(timezone.utc)
        start = now.strftime("%Y-%m-%d")
        # First of the month, 6 months ahead
        end_month = now.month + 6
        end_year = now.year + (end_month - 1) // 12
        end_month = ((end_month - 1) % 12) + 1
        end = f"{end_year:04d}-{end_month:02d}-01"
        return start, end

    @staticmethod
    def _extract_current_month(prediction_result: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Extract the first month's hypothesis from the prediction timeline."""
        timeline = prediction_result.get("monthly_timeline", [])
        if isinstance(timeline, list) and timeline:
            return timeline[0]
        return None

    # =======================================================================
    # Dasha pulse composition
    # =======================================================================

    def _compose_dasha_pulse(
        self,
        dasha_state: Dict[str, Any],
        planet_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Compose a concise dasha pulse summary.

        Returns:
            Dict with current_lord, antardasha_lord, narrative_one_liner,
            next_transition_date, days_remaining, transition_hint, impact.
        """
        maha_lord = dasha_state.get("mahadasha_lord", "")
        antar_lord = dasha_state.get("antardasha_lord", "")
        maha_end = dasha_state.get("mahadasha_end", "")

        # -- Narrative one-liner from DashaInterpretationService ----------
        try:
            narrative = self._dasha_interp.generate_period_narrative(
                mahadasha_lord=maha_lord,
                antardasha_lord=antar_lord,
            )
            # Trim to a single crisp sentence.
            sentences = [s.strip() for s in narrative.split(". ") if s.strip()]
            narrative_one_liner = sentences[0] if sentences else narrative
        except Exception:
            narrative_one_liner = (
                f"{maha_lord} Mahadasha with {antar_lord} Antardasha."
            )

        # -- Dasha impact from PlanetaryStrengthService -------------------
        impact: Dict[str, Any] = {}
        try:
            impact = self._strength.calculate_dasha_impact(maha_lord, planet_data)
        except Exception as exc:
            logger.warning("Dasha impact calculation failed: %s", exc)
            impact = {"tone": "unknown", "impact_scores": {}}

        # -- Next transition -----------------------------------------------
        next_lord = self._find_next_dasha_lord(maha_lord)
        next_date = maha_end or "unknown"
        days_remaining = self._days_until(maha_end) if maha_end else None

        # -- Transition hint from DashaInterpretationService ---------------
        transition_hint: Dict[str, Any] = {}
        if next_lord and days_remaining is not None:
            try:
                transition_hint = self._dasha_interp.get_transition_insights(
                    current_lord=maha_lord,
                    next_lord=next_lord,
                    days_until=days_remaining,
                )
            except Exception as exc:
                logger.warning("Transition insights failed: %s", exc)
                transition_hint = {}

        return {
            "current_lord": maha_lord,
            "antardasha_lord": antar_lord,
            "narrative_one_liner": narrative_one_liner,
            "next_transition_date": next_date,
            "days_remaining": days_remaining,
            "transition_hint": (
                transition_hint.get("summary", "")
                if transition_hint
                else f"Transition from {maha_lord} to {next_lord}."
            ),
            "impact": impact.get("impact_scores", {}),
            "tone": impact.get("tone", "unknown"),
        }

    # =======================================================================
    # Synthesis narrative — THE key method
    # =======================================================================

    def _compose_synthesis_narrative(
        self,
        archetype: Dict[str, Any],
        constraints: List[Dict[str, Any]],
        loshu: Dict[str, Any],
        dasha_state: Dict[str, Any],
        planet_data: Dict[str, Any],
    ) -> str:
        """Weave archetype, dasha, constraints, and Loshu into a single paragraph.

        The narrative is 5–8 sentences that read like a personalised reading,
        not a concatenation of four separate reports.  Each sentence builds on
        the previous one to form a coherent story arc.

        If any upstream service failed (key == "error"), that section is
        silently skipped rather than generating a broken sentence.
        """
        parts: List[str] = []

        # --- Sentence 1: Archetype identity ---------------------------------
        primary = archetype.get("primary", "")
        secondary = archetype.get("secondary", "")
        if primary and "error" not in archetype:
            if secondary and secondary != primary:
                parts.append(f"You are a {primary} with a {secondary} influence.")
            else:
                parts.append(f"You are a {primary}.")
        else:
            parts.append("Your chart architecture is complex and multi-layered.")

        # --- Sentence 2–3: Dasha meaning + concrete house placement ---------
        maha_lord = dasha_state.get("mahadasha_lord", "")
        if maha_lord:
            parts.append(self._build_dasha_sentence(maha_lord, planet_data))
            antar_lord = dasha_state.get("antardasha_lord", "")
            if antar_lord and antar_lord != maha_lord:
                parts.append(
                    f"The {antar_lord} Antardasha sub-period layers "
                    f"{self._get_dasha_keywords(antar_lord)} onto this arc."
                )

        # --- Sentence 4: Top constraint -------------------------------------
        if constraints and isinstance(constraints, list):
            top = constraints[0]
            title = top.get("title", "")
            guardrail = top.get("guardrail", "")
            if title:
                constraint_sentence = (
                    f"Your top constraint: {title}. "
                )
                if guardrail:
                    # Take the first sentence of the guardrail for punch.
                    first_guard = guardrail.split(". ")[0].rstrip(".")
                    constraint_sentence += f"{first_guard}."
                parts.append(constraint_sentence)

        # --- Sentence 5–6: Loshu eigenvalue + missing numbers ---------------
        if "error" not in loshu:
            parts.append(self._build_loshu_sentence(loshu))

        # --- Sentence 7–8: Forward-looking actionable -----------------------
        parts.append(self._build_actionable_close(constraints, loshu, maha_lord))

        return " ".join(parts)

    # ------------------------------------------------------------------
    # Narrative sub-builders
    # ------------------------------------------------------------------

    def _build_dasha_sentence(
        self, maha_lord: str, planet_data: Dict[str, Any]
    ) -> str:
        """Build the dasha meaning sentence, referencing the lord's house placement."""
        meaning = _DASHA_CONCRETE_MEANING.get(maha_lord, f"drives your current life chapter")
        house_info = ""
        lord_data = planet_data.get(maha_lord)
        if isinstance(lord_data, dict):
            house = lord_data.get("house")
            sign = lord_data.get("sign", "")
            if house is not None:
                house_info = f" from your {self._ordinal(house)} house"
                if sign:
                    house_info += f" in {sign}"
        return (
            f"Your {maha_lord} Mahadasha {meaning}{house_info} — "
            f"this is the karmic weather for the years ahead."
        )

    def _build_loshu_sentence(self, loshu: Dict[str, Any]) -> str:
        """Build the Loshu grid reference sentence(s)."""
        ev = loshu.get("eigenvalues", {})
        dom = ev.get("dominant_eigenvalue", 0)
        zeros = ev.get("zero_eigenvalues", 0)
        missing = loshu.get("grid", {}).get("missing", [])
        missing_str = ", ".join(str(d) for d in missing) if missing else "none"

        # Dominant eigenvalue characterisation
        if dom > 3.0:
            dom_plane = "Thought Plane"
            dom_desc = "you compile mental models at elite speed"
        elif dom > 1.5:
            dom_plane = "balanced structural profile"
            dom_desc = "no single dimension overwhelms, but none is fully optimised"
        else:
            dom_plane = "Material Plane"
            dom_desc = "practical action drives your system"

        loshu_text = (
            f"Your Loshu grid confirms this: dominant eigenvalue λ₁={dom:.1f} "
            f"on the {dom_plane} means {dom_desc}."
        )

        if zeros > 0:
            zero_desc = {
                0: "",
                1: " One collapsed axis creates a structural gap that manifests as repeated friction until filled.",
                2: " Two collapsed axes demand external scaffolding — automated systems or accountability partners.",
                3: " All three axes collapsed — rebuild from the cell closest to your conductor number.",
            }.get(zeros, f" {zeros} zero eigenvalues signal structural instability.")
            loshu_text += zero_desc

        if missing:
            loshu_text += (
                f" Missing digits {missing_str} confirm where deliberate "
                f"compensation is needed — these are not personality flaws, "
                f"they are unfilled structural cells."
            )
        else:
            loshu_text += " Your full grid is rare — all nine digits present."

        return loshu_text

    def _build_actionable_close(
        self,
        constraints: List[Dict[str, Any]],
        loshu: Dict[str, Any],
        maha_lord: str,
    ) -> str:
        """Build the forward-looking actionable closing sentence(s)."""
        closers: List[str] = []

        # Pull a concrete action from the top constraint's guardrail.
        if constraints:
            guardrail = constraints[0].get("guardrail", "")
            if guardrail:
                sentences = [s.strip() for s in guardrail.split(". ") if s.strip()]
                # Take the most concrete, imperative sentence.
                for s in sentences:
                    if any(
                        s.lower().startswith(w)
                        for w in ("build", "never", "always", "track", "ship", "cut", "audit")
                    ):
                        closers.append(s + ".")
                        break
                if not closers and sentences:
                    closers.append(sentences[0] + ".")

        # If Loshu has missing digits, add a gap-filling action.
        missing = loshu.get("grid", {}).get("missing", [])
        if missing and "error" not in loshu:
            conductor = loshu.get("driver_conductor", {}).get("conductor", 0)
            closers.append(
                f"Start by filling the cell closest to your conductor number "
                f"({conductor}) — one filled cell shifts the eigenvalue structure."
            )

        # Dasha-anchored forward momentum.
        if maha_lord:
            dasha_actions: Dict[str, str] = {
                "Mercury": "Write, ship, and publish on a fixed cadence. Communication compounds.",
                "Jupiter": "Teach what you know. Expansion follows generous knowledge-sharing.",
                "Saturn": "Build the thing that will outlast you. Discipline is your compound interest.",
                "Venus": "Strengthen key relationships. Terms negotiated now pay for years.",
                "Mars": "Execute relentlessly on the backlog. Action beats planning this cycle.",
                "Sun": "Be visible. Post, speak, present. Authority is built in public.",
                "Moon": "Tend your emotional infrastructure. Inner stability drives outer results.",
                "Rahu": "Experiment outside your sector. Cross-pollination creates breakthroughs.",
                "Ketu": "Cut what is not working. Subtraction is the strategy now.",
            }
            closers.append(dasha_actions.get(maha_lord, "Align your actions with the current dasha energy."))

        return " ".join(closers) if closers else "Build deliberately. The architecture is clear."

    # =======================================================================
    # Utility helpers
    # =======================================================================

    @staticmethod
    def _find_next_dasha_lord(current_lord: str) -> str:
        """Return the next mahadasha lord in the Vimshottari sequence."""
        try:
            idx = _DASHA_NAMES.index(current_lord)
            return _DASHA_NAMES[(idx + 1) % len(_DASHA_NAMES)]
        except ValueError:
            return ""

    @staticmethod
    def _days_until(date_str: str) -> Optional[int]:
        """Return days from now until *date_str* (ISO-8601)."""
        try:
            target = datetime.fromisoformat(date_str)
            now = datetime.now(timezone.utc).replace(tzinfo=None)
            return (target - now).days
        except (ValueError, TypeError):
            return None

    @staticmethod
    def _get_dasha_keywords(lord: str) -> str:
        """Return a short keyword phrase for a dasha lord."""
        keywords: Dict[str, str] = {
            "Sun": "authority and visibility",
            "Moon": "emotional depth and intuition",
            "Mars": "courage and executive drive",
            "Mercury": "intellect and commerce",
            "Jupiter": "wisdom and expansion",
            "Venus": "harmony and value creation",
            "Saturn": "discipline and endurance",
            "Rahu": "ambition and disruption",
            "Ketu": "detachment and clarity",
        }
        return keywords.get(lord, "unique planetary energy")

    @staticmethod
    def _ordinal(n: int) -> str:
        """Return '1st', '2nd', '3rd' etc. for the given integer."""
        if 11 <= (n % 100) <= 13:
            return f"{n}th"
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
        return f"{n}{suffix}"
