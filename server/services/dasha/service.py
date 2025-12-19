"""Public-facing DashaService orchestrating timeline + response assembly."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Optional

from .assembler import DashaAssembler


class DashaService:
    """High-level service used by Flask routes to compute Vimshottari dashas."""

    def __init__(self, assembler: Optional[DashaAssembler] = None) -> None:
        self._assembler = assembler or DashaAssembler()

    def calculate_complete_dasha(
        self,
        birth_date: datetime,
        moon_longitude: float,
        target_date: datetime,
        include_future: bool = True,
        num_future_periods: int = 3,
    ) -> Dict[str, Any]:
        return self._assembler.build_complete_response(
            birth_date,
            moon_longitude,
            target_date,
            include_future=include_future,
            num_future_periods=num_future_periods,
        )

    def get_dasha_transition_info(
        self,
        birth_date: datetime,
        moon_longitude: float,
        target_date: datetime,
    ) -> Dict[str, Any]:
        return self._assembler.build_transition_response(
            birth_date,
            moon_longitude,
            target_date,
        )
