"""
Loshu Grid Numerology Analysis Service.

Computes Loshu Grid construction from date-of-birth digits, eigenvalue
decomposition of the 3x3 matrix, plane-completion detection, driver/conductor
numbers, and phone-number integration.  Pure Python — no external dependencies.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Loshu Grid (standard 3x3 Magic Square):
#   [4] [9] [2]   Thought / Planning Plane
#   [3] [5] [7]   Will / Expression Plane
#   [8] [1] [6]   Action / Material Plane
# ---------------------------------------------------------------------------

_LOSHU_POSITIONS: Dict[int, Tuple[int, int]] = {
    4: (0, 0), 9: (0, 1), 2: (0, 2),
    3: (1, 0), 5: (1, 1), 7: (1, 2),
    8: (2, 0), 1: (2, 1), 6: (2, 2),
}

RULERS: Dict[int, str] = {
    1: "Sun", 2: "Moon", 3: "Jupiter",
    4: "Rahu/Uranus", 5: "Mercury", 6: "Venus",
    7: "Ketu/Neptune", 8: "Saturn", 9: "Mars",
}

# Each plane: name -> cells (r,c), digits, label
_PLANES: Dict[str, Dict[str, Any]] = {
    "thought":       {"label": "Thought / Planning",    "cells": [(0,0),(0,1),(0,2)], "digits": [4,9,2]},
    "will":          {"label": "Will / Expression",      "cells": [(1,0),(1,1),(1,2)], "digits": [3,5,7]},
    "action":        {"label": "Action / Material",      "cells": [(2,0),(2,1),(2,2)], "digits": [8,1,6]},
    "organization":  {"label": "Organization",           "cells": [(0,0),(1,0),(2,0)], "digits": [4,3,8]},
    "determination": {"label": "Determination",          "cells": [(0,1),(1,1),(2,1)], "digits": [9,5,1]},
    "relationship":  {"label": "Relationship",           "cells": [(0,2),(1,2),(2,2)], "digits": [2,7,6]},
    "spiritual":     {"label": "Spiritual (diagonal)",   "cells": [(0,0),(1,1),(2,2)], "digits": [4,5,6]},
    "wisdom":        {"label": "Wisdom (anti-diagonal)", "cells": [(0,2),(1,1),(2,0)], "digits": [2,5,8]},
}

_MASTER_NUMBERS = {11, 22, 33}


def _reduce(n: int) -> int:
    """Digit-sum reduce, preserving 11/22/33 master numbers."""
    while n > 9 and n not in _MASTER_NUMBERS:
        n = sum(int(d) for d in str(n))
    return n


def _real_cuberoot(n: float) -> float:
    """Return the real cube root without producing Python complex values."""
    if abs(n) < 1e-12:
        return 0.0
    return math.copysign(abs(n) ** (1.0 / 3.0), n)


# ---------------------------------------------------------------------------
# Cubic solver for 3x3 eigenvalue computation (Cardano's method, no numpy)
# ---------------------------------------------------------------------------

def _solve_cubic(a: float, b: float, c: float, d: float) -> List[float]:
    """Solve ax^3 + bx^2 + cx + d = 0 for real roots, sorted descending."""
    if abs(a) < 1e-12:
        if abs(b) < 1e-12:
            return [] if abs(c) < 1e-12 else [-d / c]
        disc = c * c - 4 * b * d
        if disc < 0:
            return []
        sd = math.sqrt(disc)
        return sorted([(-c + sd) / (2 * b), (-c - sd) / (2 * b)], reverse=True)

    p = b / a
    q = c / a
    r = d / a
    p_d = q - p * p / 3.0
    q_d = r - p * q / 3.0 + 2 * p * p * p / 27.0
    disc = (q_d / 2.0) ** 2 + (p_d / 3.0) ** 3

    roots: List[float] = []
    if disc > 1e-12:                      # one real root
        sd = math.sqrt(disc)
        u = _real_cuberoot(-q_d / 2.0 + sd)
        v = _real_cuberoot(-q_d / 2.0 - sd)
        roots = [u + v - p / 3.0]
    elif disc < -1e-12:                   # three real roots
        r_mag = math.sqrt(-(p_d / 3.0) ** 3)
        theta = math.acos(-q_d / (2.0 * r_mag)) if r_mag > 1e-12 else 0.0
        sf = 2.0 * math.sqrt(-p_d / 3.0)
        roots = [sf * math.cos((theta + 2.0 * math.pi * k) / 3.0) - p / 3.0 for k in range(3)]
    else:                                  # discriminant ~= 0: multiple roots
        if abs(q_d) < 1e-12 and abs(p_d) < 1e-12:
            rt = -p / 3.0
            roots = [rt, rt, rt]
        else:
            u = _real_cuberoot(-q_d / 2.0)
            roots = [2.0 * u - p / 3.0, -u - p / 3.0, -u - p / 3.0]

    # Clean up floating noise and normalize -0.0 → 0.0
    cleaned = [0.0 if abs(x) < 1e-10 else round(x, 10) for x in roots]
    # Preserve multiplicities (dedup only when truly within 1e-6)
    result: List[float] = []
    for x in sorted(cleaned, reverse=True):
        if not result or abs(x - result[-1]) > 1e-6:
            result.append(x)
        else:
            result.append(x)
    return result


def _eigenvalues_3x3(m: List[List[int]]) -> List[float]:
    """Eigenvalues via characteristic polynomial det(A - λI) = 0."""
    a11, a12, a13 = m[0][0], m[0][1], m[0][2]
    a21, a22, a23 = m[1][0], m[1][1], m[1][2]
    a31, a32, a33 = m[2][0], m[2][1], m[2][2]

    trace = a11 + a22 + a33
    pm_sum = (a22*a33 - a23*a32) + (a11*a33 - a13*a31) + (a11*a22 - a12*a21)
    det = (
        a11 * (a22*a33 - a23*a32)
        - a12 * (a21*a33 - a23*a31)
        + a13 * (a21*a32 - a22*a31)
    )
    # λ^3 - trace*λ^2 + pm_sum*λ - det = 0
    return _solve_cubic(1.0, -trace, pm_sum, -det)


# ---------------------------------------------------------------------------
# Actionable interpretation helpers
# ---------------------------------------------------------------------------

def _actionable_eigen_interpretation(eigenvalues: List[float]) -> Dict[str, str]:
    """Translate eigenvalue profile into concrete, actionable guidance."""
    dom = eigenvalues[0] if eigenvalues else 0.0
    zeros = sum(1 for v in eigenvalues if abs(v) < 1e-8)

    # Dominant eigenvalue → which plane drives the system
    if dom > 3.0:
        dominant = (
            "Thought Plane dominant — you over-index on planning and mental models. "
            "Ideas compound but without grounded execution channels, overthinking blocks action. "
            "Actionable: pair every idea with a 24-hour physical execution step (e.g., "
            "write the first line of code, send the email, book the call)."
        )
    elif dom > 1.5:
        dominant = (
            "Balanced eigenvalue profile — moderate structural integrity across planes. "
            "No single dimension overwhelms the others, but also no dimension is fully "
            "optimized. Actionable: identify your single strongest completed plane and "
            "build routines that funnel its energy into your weakest missing plane."
        )
    else:
        dominant = (
            "Material Plane dominant — practicality and action-orientation drive your grid. "
            "You get things done but may lack strategic altitude. Actionable: schedule "
            "one weekly 'thought plane' session (journaling, planning, reflection) to "
            "ensure your action has direction."
        )

    # Zero eigenvalues → structural gaps with concrete guardrails
    if zeros == 0:
        zero_msg = (
            "Full structural integrity — all three principal axes carry energy. "
            "Guardrail: maintain this by ensuring no plane stays empty for extended periods. "
            "Track your Loshu grid after major life changes."
        )
    elif zeros == 1:
        zero_msg = (
            "One collapsed axis — the grid has a null space where energy cannot flow. "
            "This is a concrete structural gap, not a personality trait. "
            "Guardrail: the missing plane dimension WILL manifest as repeated friction "
            "in that life area until filled by external input (phone number, name change, "
            "or conscious habit-building). Do not rely on willpower alone."
        )
    elif zeros == 2:
        zero_msg = (
            "Two collapsed axes — severe structural instability. The grid operates "
            "in a near-singular subspace. This is the numerology equivalent of trying "
            "to run a business on a single revenue stream. Guardrail: you need external "
            "scaffolding (automated systems, accountability partners, environmental design) "
            "to compensate. Building one automated routine that fills a missing cell "
            "will have disproportionate impact."
        )
    else:
        zero_msg = (
            "Complete null space — all three eigenvalues are zero (nilpotent grid). "
            "This extreme profile means every plane must be rebuilt. Guardrail: start "
            "with the single cell closest to your conductor number and build outward. "
            "One filled cell breaks the zero pattern."
        )

    return {"dominant": dominant, "zero_count": zero_msg}


def _plane_gap_guidance(incomplete_planes: List[str], missing_digits: List[int]) -> str:
    """Generate actionable gap-closing guidance for incomplete planes."""
    if not incomplete_planes:
        return "All planes complete — maintain through consistent routines."

    # Map the first incomplete plane to a concrete action
    plane_actions = {
        "thought":       "daily 10-minute planning ritual before checking any device",
        "will":          "voice-note your intentions each morning to externalize willpower",
        "action":        "set a non-negotiable 2-hour execution block every weekday",
        "organization":  "use a single project-management tool and review it weekly",
        "determination": "define one quarterly goal with public accountability",
        "relationship":  "schedule one intentional check-in with a key person each week",
        "spiritual":     "start a 5-minute daily stillness practice (no phone, no input)",
        "wisdom":        "keep a 'lessons learned' log and review it monthly",
    }

    primary = incomplete_planes[0]
    action = plane_actions.get(primary, "identify and fill the missing digit through habit design")

    return (
        f"Primary gap: {primary.replace('_', ' ')} plane incomplete. "
        f"Missing digits: {missing_digits}. "
        f"Actionable: {action}. Filling even one of these cells will shift the "
        f"structural balance more than optimizing an already-complete plane."
    )


# ===================================================================
# Service
# ===================================================================

class NumerologyService:
    """Loshu Grid numerology — grid, eigenvalues, planes, driver/conductor, phone."""

    def __init__(self) -> None:
        pass

    # ------------------------------------------------------------------
    # 1. Grid construction
    # ------------------------------------------------------------------

    def build_loshu_grid(self, dob_digits: List[int]) -> Dict[str, Any]:
        """Build 3x3 Loshu grid from DOB digit occurrences.

        Example: DOB 24/12/1999 → [2,4,1,2,1,9,9,9].
        """
        counts: Dict[int, int] = {d: 0 for d in range(1, 10)}
        for d in dob_digits:
            if 1 <= d <= 9:
                counts[d] += 1

        grid = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
        for digit, (r, c) in _LOSHU_POSITIONS.items():
            grid[r][c] = counts[digit]

        return {
            "grid": grid,
            "counts": {str(k): v for k, v in counts.items()},
            "missing": sorted(d for d in range(1, 10) if counts[d] == 0),
            "present": sorted(d for d in range(1, 10) if counts[d] > 0),
            "triple_numbers": sorted(d for d in range(1, 10) if counts[d] >= 3),
            "double_numbers": sorted(d for d in range(1, 10) if counts[d] == 2),
            "single_numbers": sorted(d for d in range(1, 10) if counts[d] == 1),
        }

    # ------------------------------------------------------------------
    # 2. Eigenvalue analysis
    # ------------------------------------------------------------------

    def compute_eigenvalues(self, grid: List[List[int]]) -> Dict[str, Any]:
        """Compute eigenvalues of the 3x3 Loshu matrix (hand-coded, no numpy)."""
        evals = _eigenvalues_3x3(grid)
        dominant = evals[0] if evals else 0.0
        zero_count = sum(1 for v in evals if abs(v) < 1e-8)

        return {
            "eigenvalues": evals,
            "dominant_eigenvalue": round(dominant, 4),
            "zero_eigenvalues": zero_count,
            "interpretation": _actionable_eigen_interpretation(evals),
        }

    # ------------------------------------------------------------------
    # 3. Plane analysis
    # ------------------------------------------------------------------

    def analyze_planes(self, grid: List[List[int]]) -> Dict[str, Any]:
        """Detect completed planes (rows, columns, diagonals).

        A plane is complete when every cell in it is non-zero.
        """
        planes_result: Dict[str, Dict[str, Any]] = {}
        for key, pd in _PLANES.items():
            values = [grid[r][c] for r, c in pd["cells"]]
            planes_result[key] = {
                "label": pd["label"],
                "digits": pd["digits"],
                "values": values,
                "completed": all(v > 0 for v in values),
                "filled_count": sum(1 for v in values if v > 0),
                "total_count": len(values),
            }

        completed = [k for k, v in planes_result.items() if v["completed"]]
        incomplete = [k for k, v in planes_result.items() if not v["completed"]]

        return {
            "planes": planes_result,
            "completed_planes": completed,
            "incomplete_planes": incomplete,
            "total_planes": len(_PLANES),
            "completed_count": len(completed),
        }

    # ------------------------------------------------------------------
    # 4. Driver / Conductor
    # ------------------------------------------------------------------

    def get_driver_conductor(self, dob_digits: List[int]) -> Dict[str, Any]:
        """Driver (Psychic) = sum of day digits, reduced. Preserves 11/22/33.
        Conductor (Destiny) = sum of all DOB digits, reduced.

        For DD/MM/YYYY format, the first 2 digits are assumed to be the day.
        """
        day_digits = dob_digits[:2] if len(dob_digits) >= 2 else (dob_digits[:1] if dob_digits else [0])
        driver_raw = sum(day_digits)
        conductor_raw = sum(dob_digits)
        driver = _reduce(driver_raw)
        conductor = _reduce(conductor_raw)

        return {
            "driver": driver,
            "conductor": conductor,
            "driver_raw": driver_raw,
            "conductor_raw": conductor_raw,
            "driver_ruler": RULERS.get(driver, "Unknown"),
            "conductor_ruler": RULERS.get(conductor, "Unknown"),
            "driver_is_master": driver in _MASTER_NUMBERS,
            "conductor_is_master": conductor in _MASTER_NUMBERS,
        }

    # ------------------------------------------------------------------
    # 5. Phone digit integration
    # ------------------------------------------------------------------

    def integrate_phone_digit(self, dob_digits: List[int], phone_digit_sum: int) -> Dict[str, Any]:
        """Check if a phone number's digit sum fills a missing Loshu cell."""
        phone_digit = _reduce(phone_digit_sum)
        grid_data = self.build_loshu_grid(dob_digits)
        missing = grid_data["missing"]

        fills = phone_digit in missing

        # Actionable impact per digit
        _impacts = {
            1: "Restores Sun/leadership cell — without this, self-expression defaults to others' expectations. Actionable: take one solo decision daily without seeking validation.",
            2: "Restores Moon/intuition cell — without this, emotional decisions are outsourced. Actionable: journal gut feelings before soliciting advice.",
            3: "Restores Jupiter/expansion cell — without this, growth stays incremental. Actionable: say yes to one uncomfortable opportunity this month.",
            4: "Restores Rahu/innovation cell — without this, unconventional ideas stay trapped. Actionable: ship one unconventional project without waiting for permission.",
            5: "Restores Mercury/grounding cell — this is the center of the grid. Without it, the entire system lacks balance. Actionable: build one automated daily routine (same wake time, same first action).",
            6: "Restores Venus/harmony cell — without this, relationships feel transactional. Actionable: one unsolicited act of generosity per week.",
            7: "Restores Ketu/detachment cell — without this, spiritual insight gets crowded out by noise. Actionable: 10 minutes of silence before bed, no input.",
            8: "Restores Saturn/structure cell — without this, discipline collapses under pressure. Actionable: pick one non-negotiable constraint and defend it for 30 days.",
            9: "Restores Mars/drive cell — without this, initiative stalls. Actionable: start your hardest task within 10 minutes of waking, before resistance builds.",
        }

        return {
            "phone_digit": phone_digit,
            "phone_digit_ruler": RULERS.get(phone_digit, "Unknown"),
            "fills_missing": fills,
            "fills_cell": phone_digit if fills else None,
            "missing_cells": missing,
            "impact": _impacts.get(phone_digit, f"Digit {phone_digit} — {'fills a structural gap' if fills else 'reinforces existing energy, not a gap-fill'}"),
        }

    # ------------------------------------------------------------------
    # 6. Full report
    # ------------------------------------------------------------------

    def full_numerology_report(
        self, dob_digits: List[int], phone_digit_sum: Optional[int] = None
    ) -> Dict[str, Any]:
        """Combine all analyses into a single comprehensive report."""
        gd = self.build_loshu_grid(dob_digits)
        ev = self.compute_eigenvalues(gd["grid"])
        pl = self.analyze_planes(gd["grid"])
        dc = self.get_driver_conductor(dob_digits)

        report: Dict[str, Any] = {
            "grid": gd,
            "eigenvalues": ev,
            "planes": pl,
            "driver_conductor": dc,
            "summary": self._build_summary(gd, pl, ev, dc),
        }
        if phone_digit_sum is not None:
            report["phone_integration"] = self.integrate_phone_digit(dob_digits, phone_digit_sum)
        return report

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------

    @staticmethod
    def _build_summary(
        gd: Dict[str, Any], pl: Dict[str, Any], ev: Dict[str, Any], dc: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Compose high-level summary with actionable takeaways."""
        missing = gd["missing"]
        driver = dc["driver"]
        conductor = dc["conductor"]
        triple = gd["triple_numbers"]

        # Structural health label
        zeros = ev["zero_eigenvalues"]
        completed = pl["completed_count"]
        total = pl["total_planes"]

        if zeros == 0 and completed == total:
            health = "Exceptional — all planes active, full eigenvalue spectrum"
        elif zeros == 0:
            health = f"Strong — stable eigenvalues but only {completed}/{total} planes complete"
        elif zeros == 1:
            health = f"Moderate — one collapsed axis, {completed}/{total} planes complete"
        else:
            health = f"Weak — {zeros} zero eigenvalues, {completed}/{total} planes complete"

        # Actionable gap guidance
        gap_guidance = _plane_gap_guidance(pl["incomplete_planes"], missing)

        # Triple-number warning (3+ occurrences = over-activation)
        triple_warning = ""
        if triple:
            triple_names = [f"{d} ({RULERS.get(d, '?')})" for d in triple]
            triple_warning = (
                f"Over-activated digits: {', '.join(triple_names)}. "
                f"A digit appearing 3+ times becomes hyper-expressed — its energy dominates "
                f"at the expense of missing digits. Actionable: consciously under-index on "
                f"these traits and redirect attention to filling the missing cells."
            )

        # Takeaway
        if not missing:
            takeaway = "Full grid — rare and potent. Your job is channeling this completeness into focused output."
        elif len(missing) <= 2:
            takeaway = f"Nearly complete grid — missing only {missing}. Fill these via phone/number alignment and the remaining gaps close naturally."
        elif len(missing) <= 4:
            takeaway = f"Moderately sparse — {len(missing)} missing digits. Prioritize filling the center (5/Mercury) if missing; it is the grounding bridge for the entire grid."
        else:
            takeaway = f"Sparse grid — {len(missing)} missing digits. Do not try to fill all at once. Start with the digit closest to your conductor ({conductor}) and build one habit. One filled cell changes the eigenvalue structure."

        return {
            "structural_health": health,
            "missing_digits": missing,
            "missing_count": len(missing),
            "planes_completed": f"{completed}/{total}",
            "driver": f"{driver} ({dc['driver_ruler']})",
            "conductor": f"{conductor} ({dc['conductor_ruler']})",
            "dominant_eigenvalue": ev["dominant_eigenvalue"],
            "triple_number_warning": triple_warning,
            "gap_guidance": gap_guidance,
            "takeaway": takeaway,
        }
