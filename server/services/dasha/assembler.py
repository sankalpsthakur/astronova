"""Assembles structured responses for Vimshottari dasha timelines."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from .timeline import TimelineCalculator

logger = logging.getLogger(__name__)


class DashaAssembler:
    """Builds normalized dictionaries describing current and future dasha periods."""

    def __init__(self, timeline_calculator: Optional[TimelineCalculator] = None) -> None:
        self.timeline = timeline_calculator or TimelineCalculator()

    def build_complete_response(
        self,
        birth_date: datetime,
        moon_longitude: float,
        target_date: datetime,
        include_future: bool = True,
        num_future_periods: int = 3,
    ) -> Dict[str, Any]:
        starting_lord, balance_years = self.timeline.calculate_starting_dasha(moon_longitude)

        mahadasha_timeline = self.timeline.generate_mahadasha_timeline(
            birth_date,
            starting_lord,
            balance_years,
            num_periods=20,
        )

        active_maha = self.timeline.find_active_mahadasha(mahadasha_timeline, target_date)
        if not active_maha:
            logger.warning("No active Mahadasha found for date %s", target_date)
            # Return error info instead of empty dict for better error handling
            return {
                "error": "no_active_mahadasha",
                "message": f"No active Mahadasha found for target date {target_date.date().isoformat()}. "
                           f"Timeline starts from birth date {birth_date.date().isoformat()}.",
                "birth_date": birth_date.date().isoformat(),
                "target_date": target_date.date().isoformat(),
            }

        antardashas = self.timeline.calculate_antardasha(
            active_maha["lord"],
            active_maha["start"],
            active_maha["end"],
        )
        active_antar = self.timeline.find_active_period(antardashas, target_date)
        if not active_antar and antardashas:
            logger.warning("No active Antardasha found for date %s", target_date)
            active_antar = antardashas[0]

        pratyantardashas: List[Dict[str, Any]] = []
        active_pratyantar: Optional[Dict[str, Any]] = None
        if active_antar:
            pratyantardashas = self.timeline.calculate_pratyantardasha(
                active_antar["lord"],
                active_antar["start"],
                active_antar["end"],
            )
            active_pratyantar = self.timeline.find_active_period(pratyantardashas, target_date)

        response: Dict[str, Any] = {
            "birth_date": birth_date.date().isoformat(),
            "target_date": target_date.date().isoformat(),
            "starting_dasha": {
                "lord": starting_lord,
                "balance_years": round(balance_years, 4),
            },
            "mahadasha": self._period_payload(active_maha, "duration_years"),
            "antardasha": self._optional_period_payload(active_antar, "duration_months"),
            "pratyantardasha": self._optional_period_payload(active_pratyantar, "duration_days"),
            "all_antardashas": [self._period_payload(antar, "duration_months") for antar in antardashas],
            "all_pratyantardashas": (
                [self._period_payload(pratyantar, "duration_days") for pratyantar in pratyantardashas]
                if pratyantardashas
                else []
            ),
        }

        if include_future:
            response["upcoming_mahadashas"] = self._future_mahadashas(
                mahadasha_timeline,
                active_maha,
                num_future_periods,
            )

        return response

    def build_transition_response(
        self,
        birth_date: datetime,
        moon_longitude: float,
        target_date: datetime,
    ) -> Dict[str, Any]:
        base = self.build_complete_response(
            birth_date,
            moon_longitude,
            target_date,
            include_future=True,
            num_future_periods=3,
        )
        if not base:
            return {}

        def days_until(date_string: str) -> int:
            end_date = datetime.fromisoformat(date_string)
            # Use date-only comparison to avoid off-by-one errors
            return (end_date.date() - target_date.date()).days

        transitions: Dict[str, Any] = {}

        if base.get("mahadasha"):
            maha = base["mahadasha"]
            days_left = days_until(maha["end"])
            transitions["mahadasha"] = {
                "current_lord": maha["lord"],
                "days_remaining": days_left,
                "years_remaining": round(days_left / 365.25, 2),
                "months_remaining": round(days_left / 30.4375, 1),
                "ends_on": maha["end"],
                "next_lord": base.get("upcoming_mahadashas", [{}])[0].get("lord") if base.get("upcoming_mahadashas") else None,
            }

        if base.get("antardasha"):
            antar = base["antardasha"]
            days_left = days_until(antar["end"])
            next_antar = self._next_period(base.get("all_antardashas", []), antar)
            transitions["antardasha"] = {
                "current_lord": antar["lord"],
                "days_remaining": days_left,
                "months_remaining": round(days_left / 30.4375, 1),
                "ends_on": antar["end"],
                "next_lord": next_antar.get("lord") if next_antar else None,
            }

        if base.get("pratyantardasha"):
            pratyantar = base["pratyantardasha"]
            days_left = days_until(pratyantar["end"])
            next_pratyantar = self._next_period(base.get("all_pratyantardashas", []), pratyantar)
            transitions["pratyantardasha"] = {
                "current_lord": pratyantar["lord"],
                "days_remaining": days_left,
                "ends_on": pratyantar["end"],
                "next_lord": next_pratyantar.get("lord") if next_pratyantar else None,
            }

        return transitions

    # --- Internal helpers ----------------------------------------------------------------

    def _period_payload(self, period: Dict[str, Any], duration_key: str) -> Dict[str, Any]:
        duration_value = period.get(duration_key)
        if duration_value is not None and duration_key == "duration_years":
            duration_value = round(float(duration_value), 2)
        return {
            "lord": period["lord"],
            "start": period["start"].date().isoformat(),
            "end": period["end"].date().isoformat(),
            duration_key: duration_value,
        }

    def _optional_period_payload(self, period: Optional[Dict[str, Any]], duration_key: str) -> Optional[Dict[str, Any]]:
        if not period:
            return None
        payload = self._period_payload(period, duration_key)
        return payload

    def _future_mahadashas(
        self,
        timeline: List[Dict[str, Any]],
        active_maha: Dict[str, Any],
        count: int,
    ) -> List[Dict[str, Any]]:
        try:
            current_index = timeline.index(active_maha)
        except ValueError:
            return []

        future = timeline[current_index + 1 : current_index + 1 + count]
        return [self._period_payload(period, "duration_years") for period in future]

    def _next_period(self, periods: List[Dict[str, Any]], current: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        for index, period in enumerate(periods):
            if period["lord"] == current["lord"] and period["start"] == current["start"]:
                return periods[index + 1] if index < len(periods) - 1 else None
        return None
