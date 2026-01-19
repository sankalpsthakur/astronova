"""Nakshatra helpers."""

from __future__ import annotations

from dataclasses import dataclass

from .constants import NAKSHATRA_LORDS, NAKSHATRA_NAMES, NAKSHATRA_PADA_SPAN_DEG, NAKSHATRA_SPAN_DEG


@dataclass(frozen=True)
class NakshatraInfo:
    index: int  # 1..27
    name: str
    lord: str
    pada: int  # 1..4
    degrees_into_nakshatra: float
    percent_complete: float


def nakshatra_from_longitude(longitude: float) -> NakshatraInfo:
    normalized = float(longitude) % 360.0
    idx0 = min(int(normalized / NAKSHATRA_SPAN_DEG), 26)
    name = NAKSHATRA_NAMES[idx0]
    lord = NAKSHATRA_LORDS[idx0]
    degrees_in = normalized - (idx0 * NAKSHATRA_SPAN_DEG)
    pada = min(int(degrees_in / NAKSHATRA_PADA_SPAN_DEG) + 1, 4)
    percent = (degrees_in / NAKSHATRA_SPAN_DEG) * 100.0
    return NakshatraInfo(
        index=idx0 + 1,
        name=name,
        lord=lord,
        pada=pada,
        degrees_into_nakshatra=round(degrees_in, 4),
        percent_complete=round(percent, 2),
    )

