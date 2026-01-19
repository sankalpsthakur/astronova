"""Sade Sati analysis (Saturn relative to natal Moon sign)."""

from __future__ import annotations

from dataclasses import dataclass

from .constants import VEDIC_SIGN_INDEX, VEDIC_SIGNS


@dataclass(frozen=True)
class SadeSatiInfo:
    active: bool
    phase: str | None
    saturn_sign: str | None
    moon_sign: str | None
    explainLikeImFive: str


def sade_sati_status(*, natal_moon_sign: str, current_saturn_sign: str) -> dict[str, object]:
    moon_idx = VEDIC_SIGN_INDEX.get(natal_moon_sign)
    sat_idx = VEDIC_SIGN_INDEX.get(current_saturn_sign)
    if moon_idx is None or sat_idx is None:
        return SadeSatiInfo(
            active=False,
            phase=None,
            saturn_sign=current_saturn_sign,
            moon_sign=natal_moon_sign,
            explainLikeImFive="Sade Sati depends on Saturn’s position relative to your Moon sign.",
        ).__dict__

    prev_sign = (moon_idx - 1) % 12
    next_sign = (moon_idx + 1) % 12

    phase = None
    if sat_idx == prev_sign:
        phase = "Rising (Phase 1)"
    elif sat_idx == moon_idx:
        phase = "Peak (Phase 2)"
    elif sat_idx == next_sign:
        phase = "Setting (Phase 3)"

    active = phase is not None
    return SadeSatiInfo(
        active=active,
        phase=phase,
        saturn_sign=VEDIC_SIGNS[sat_idx],
        moon_sign=VEDIC_SIGNS[moon_idx],
        explainLikeImFive=(
            "Sade Sati is a long Saturn transit window (about 7.5 years) that covers the sign before your Moon sign, "
            "your Moon sign, and the sign after it. It’s often described as a period of maturity and responsibility."
        ),
    ).__dict__

