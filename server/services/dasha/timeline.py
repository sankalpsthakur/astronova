"""Timeline helpers for Vimshottari dasha periods."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from .constants import NAKSHATRA_RULERS, TOTAL_CYCLE_YEARS, VIMSHOTTARI_SEQUENCE


@dataclass
class TimelineCalculator:
    """Calculates Mahadasha, Antardasha, and Pratyantardasha timelines."""

    lord_order: List[str] = None
    duration_map: Dict[str, float] = None

    def __post_init__(self) -> None:
        if self.lord_order is None:
            self.lord_order = [lord for lord, _ in VIMSHOTTARI_SEQUENCE]
        if self.duration_map is None:
            self.duration_map = {lord: years for lord, years in VIMSHOTTARI_SEQUENCE}

    # --- Moon and starting dasha helpers -------------------------------------------------

    def calculate_starting_dasha(self, moon_longitude: float) -> Tuple[str, float]:
        """Return the starting Mahadasha lord and remaining balance in years."""
        nakshatra_span = 13.333333333333334  # 13°20'
        normalized_lon = moon_longitude % 360.0
        nakshatra_index = min(int(normalized_lon / nakshatra_span), 26)
        starting_lord = NAKSHATRA_RULERS[nakshatra_index]

        degrees_into_nakshatra = normalized_lon - (nakshatra_span * nakshatra_index)
        fraction_elapsed = degrees_into_nakshatra / nakshatra_span
        total_duration = self.duration_map[starting_lord]
        balance_years = total_duration * (1.0 - fraction_elapsed)
        return starting_lord, balance_years

    # --- Mahadasha timeline -------------------------------------------------------------

    def generate_mahadasha_timeline(
        self,
        birth_date: datetime,
        starting_lord: str,
        balance_years: float,
        num_periods: int = 10,
    ) -> List[Dict[str, Any]]:
        timeline: List[Dict[str, Any]] = []
        idx = self.lord_order.index(starting_lord)
        current_date = birth_date
        first = True

        for _ in range(num_periods):
            lord = self.lord_order[idx % len(self.lord_order)]
            duration_years = balance_years if first else self.duration_map[lord]
            whole_years = int(duration_years)
            remaining_fraction = duration_years - whole_years
            months = int(remaining_fraction * 12)
            days_fraction = (remaining_fraction * 12 - months) * 30.4375
            days = int(days_fraction)

            end_date = self._add_years_months(current_date, whole_years, months, days)
            timeline.append(
                {
                    "lord": lord,
                    "start": current_date,
                    "end": end_date,
                    "duration_years": duration_years,
                }
            )

            current_date = end_date
            idx += 1
            first = False

        return timeline

    def find_active_mahadasha(self, timeline: List[Dict[str, Any]], target_date: datetime) -> Optional[Dict[str, Any]]:
        return self.find_active_period(timeline, target_date)

    # --- Nested dasha helpers -----------------------------------------------------------

    def calculate_antardasha(
        self,
        mahadasha_lord: str,
        maha_start: datetime,
        maha_end: datetime,
    ) -> List[Dict[str, Any]]:
        total_seconds = int((maha_end - maha_start).total_seconds())
        total_seconds = max(total_seconds, 1)

        start_idx = self.lord_order.index(mahadasha_lord)
        antar_sequence = self.lord_order[start_idx:] + self.lord_order[:start_idx]

        raw_seconds = [self.duration_map[lord] / TOTAL_CYCLE_YEARS * total_seconds for lord in antar_sequence]
        seconds_alloc = self._distribute_via_largest_remainder(raw_seconds, total_seconds)

        antardashas: List[Dict[str, Any]] = []
        current = maha_start
        for lord, seconds in zip(antar_sequence, seconds_alloc):
            next_date = current + timedelta(seconds=seconds)
            antardashas.append(
                {
                    "lord": lord,
                    "start": current,
                    "end": next_date,
                    "duration_months": round(seconds / 86400 / 30.4375, 4),
                }
            )
            current = next_date

        if antardashas:
            antardashas[-1]["end"] = maha_end
            last_seconds = max(int((maha_end - antardashas[-1]["start"]).total_seconds()), 0)
            antardashas[-1]["duration_months"] = round(last_seconds / 86400 / 30.4375, 4)
        return antardashas

    def calculate_pratyantardasha(
        self,
        antardasha_lord: str,
        antar_start: datetime,
        antar_end: datetime,
    ) -> List[Dict[str, Any]]:
        total_days = max((antar_end - antar_start).days, 1)
        start_idx = self.lord_order.index(antardasha_lord)
        pratyantar_sequence = self.lord_order[start_idx:] + self.lord_order[:start_idx]

        raw_days = [self.duration_map[lord] / TOTAL_CYCLE_YEARS * total_days for lord in pratyantar_sequence]
        days_alloc = self._distribute_via_largest_remainder(raw_days, total_days)

        pratyantardashas: List[Dict[str, Any]] = []
        current = antar_start
        for lord, days in zip(pratyantar_sequence, days_alloc):
            next_date = current + timedelta(days=days)
            pratyantardashas.append(
                {
                    "lord": lord,
                    "start": current,
                    "end": next_date,
                    "duration_days": days,
                }
            )
            current = next_date

        if pratyantardashas:
            pratyantardashas[-1]["end"] = antar_end
        return pratyantardashas

    # --- Generic helpers ----------------------------------------------------------------

    def find_active_period(self, periods: List[Dict[str, Any]], target_date: datetime) -> Optional[Dict[str, Any]]:
        for period in periods:
            if period["start"] <= target_date < period["end"]:
                return period
        if periods and target_date == periods[-1]["end"]:
            return periods[-1]
        return None

    def _distribute_via_largest_remainder(self, raw_values: List[float], total: int) -> List[int]:
        floor_values = [int(value) for value in raw_values]
        allocated = sum(floor_values)
        remainder = total - allocated

        fractions = sorted(
            enumerate([value - floor for value, floor in zip(raw_values, floor_values)]),
            key=lambda item: item[1],
            reverse=True,
        )

        allocation = floor_values[:]
        if remainder > 0:
            for index, _ in fractions[: min(remainder, len(fractions))]:
                allocation[index] += 1
        return allocation

    def _add_years_months(self, dt: datetime, years: int = 0, months: int = 0, days: int = 0) -> datetime:
        import calendar

        target_year = dt.year + years
        target_month = dt.month + months

        while target_month > 12:
            target_month -= 12
            target_year += 1
        while target_month < 1:
            target_month += 12
            target_year -= 1

        max_day = calendar.monthrange(target_year, target_month)[1]
        target_day = min(dt.day, max_day)
        result = dt.replace(year=target_year, month=target_month, day=target_day)

        if days:
            result += timedelta(days=days)
        return result
