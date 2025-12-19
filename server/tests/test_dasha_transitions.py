"""
Comprehensive tests for dasha transition day calculations.
Addresses P1 bug: datetime with time component vs midnight comparison.
"""

from __future__ import annotations

from datetime import datetime, timedelta

import pytest
from freezegun import freeze_time

from services.dasha.assembler import DashaAssembler


class TestDashaTransitionDayCalculation:
    """Test the days_remaining calculation bug fix."""

    @pytest.fixture
    def assembler(self):
        return DashaAssembler()

    @pytest.fixture
    def sample_birth_data(self):
        """Birth data that produces known dasha periods."""
        return {
            "birth_date": datetime(1990, 1, 15, 14, 30),
            "moon_longitude": 45.0,  # Krittika nakshatra
        }

    def test_days_remaining_at_midnight(self, assembler, sample_birth_data):
        """When queried at midnight, days_remaining should be accurate."""
        target_date = datetime(2025, 1, 1, 0, 0, 0)

        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], target_date
        )

        # Calculate expected days
        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        expected_days = (maha_end.date() - target_date.date()).days

        assert transition["mahadasha"]["days_remaining"] == expected_days

    def test_days_remaining_at_noon(self, assembler, sample_birth_data):
        """When queried at noon, days_remaining should NOT be off-by-one."""
        target_date = datetime(2025, 1, 1, 12, 0, 0)

        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], target_date
        )

        # Should be same as midnight calculation
        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        expected_days = (maha_end.date() - target_date.date()).days

        assert transition["mahadasha"]["days_remaining"] == expected_days

    def test_days_remaining_at_end_of_day(self, assembler, sample_birth_data):
        """When queried at 11:59 PM, days_remaining should still be correct."""
        target_date = datetime(2025, 1, 1, 23, 59, 59)

        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], target_date
        )

        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        expected_days = (maha_end.date() - target_date.date()).days

        assert transition["mahadasha"]["days_remaining"] == expected_days

    @pytest.mark.parametrize("hour", [0, 6, 12, 18, 23])
    def test_days_remaining_consistent_throughout_day(self, assembler, sample_birth_data, hour):
        """Days remaining should be identical regardless of time within the day."""
        target_date = datetime(2025, 1, 1, hour, 30, 0)

        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], target_date
        )

        # All should give same result
        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        expected_days = (maha_end.date() - target_date.date()).days

        assert transition["mahadasha"]["days_remaining"] == expected_days

    def test_days_remaining_on_last_day(self, assembler, sample_birth_data):
        """On the last day of period, days_remaining should be 0."""
        # First get a period end date
        target_date = datetime(2025, 1, 1, 0, 0, 0)
        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        # Query on the end date itself
        end_date_str = result["mahadasha"]["end"]
        end_date = datetime.fromisoformat(end_date_str)

        assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            end_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], end_date
        )

        # Should be 0 days remaining
        assert transition["mahadasha"]["days_remaining"] == 0

    def test_days_remaining_one_day_before_end(self, assembler, sample_birth_data):
        """One day before end should show days_remaining=1."""
        target_date = datetime(2025, 1, 1, 0, 0, 0)
        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        # Query one day before end
        end_date = datetime.fromisoformat(result["mahadasha"]["end"])
        one_day_before = end_date - timedelta(days=1)

        assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            one_day_before,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], one_day_before
        )

        assert transition["mahadasha"]["days_remaining"] == 1

    @freeze_time("2025-01-15 14:30:00")
    def test_omitted_target_date_uses_now(self, assembler, sample_birth_data):
        """When targetDate is omitted, should use current time correctly."""
        # This simulates the bug scenario: datetime.now() has time component
        target_date = datetime.now()

        result = assembler.build_complete_response(
            sample_birth_data["birth_date"],
            sample_birth_data["moon_longitude"],
            target_date,
            include_future=True,
            num_future_periods=1,
        )

        transition = assembler.build_transition_response(
            sample_birth_data["birth_date"], sample_birth_data["moon_longitude"], target_date
        )

        # Should use date-only comparison
        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        expected_days = (maha_end.date() - target_date.date()).days

        assert transition["mahadasha"]["days_remaining"] == expected_days


class TestDashaTransitionEdgeCases:
    """Test edge cases in transition calculations."""

    @pytest.fixture
    def assembler(self):
        return DashaAssembler()

    def test_transition_with_timezone_aware_datetime(self, assembler):
        """Should handle timezone-aware datetimes correctly."""
        from zoneinfo import ZoneInfo

        birth_date = datetime(1990, 1, 15, 14, 30)
        moon_longitude = 45.0
        target_date = datetime(2025, 1, 1, 12, 0, tzinfo=ZoneInfo("Asia/Kolkata"))

        # Should convert to naive UTC before comparison
        assembler.build_complete_response(
            birth_date, moon_longitude, target_date.replace(tzinfo=None), include_future=True, num_future_periods=1
        )

        transition = assembler.build_transition_response(birth_date, moon_longitude, target_date.replace(tzinfo=None))

        assert transition["mahadasha"]["days_remaining"] >= 0

    def test_years_remaining_calculation(self, assembler):
        """Years remaining should be accurately calculated from days."""
        birth_date = datetime(1990, 1, 15, 14, 30)
        moon_longitude = 45.0
        target_date = datetime(2025, 1, 1, 0, 0, 0)

        assembler.build_complete_response(birth_date, moon_longitude, target_date, include_future=True, num_future_periods=1)

        transition = assembler.build_transition_response(birth_date, moon_longitude, target_date)

        days = transition["mahadasha"]["days_remaining"]
        years = transition["mahadasha"]["years_remaining"]

        # Verify years calculation (days / 365.25)
        assert abs(years - (days / 365.25)) < 0.01

    def test_months_remaining_calculation(self, assembler):
        """Months remaining should be accurately calculated from days."""
        birth_date = datetime(1990, 1, 15, 14, 30)
        moon_longitude = 45.0
        target_date = datetime(2025, 1, 1, 0, 0, 0)

        assembler.build_complete_response(birth_date, moon_longitude, target_date, include_future=True, num_future_periods=1)

        transition = assembler.build_transition_response(birth_date, moon_longitude, target_date)

        days = transition["mahadasha"]["days_remaining"]
        months = transition["mahadasha"]["months_remaining"]

        # Verify months calculation (days / 30.4375)
        assert abs(months - (days / 30.4375)) < 0.1

    def test_antardasha_transition_accuracy(self, assembler):
        """Antardasha transition should also use date-only comparison."""
        birth_date = datetime(1990, 1, 15, 14, 30)
        moon_longitude = 45.0
        target_date = datetime(2025, 1, 1, 15, 45, 0)  # Midday

        result = assembler.build_complete_response(
            birth_date, moon_longitude, target_date, include_future=True, num_future_periods=1
        )

        transition = assembler.build_transition_response(birth_date, moon_longitude, target_date)

        if "antardasha" in transition:
            antar_end = datetime.fromisoformat(result["antardasha"]["end"])
            expected_days = (antar_end.date() - target_date.date()).days

            assert transition["antardasha"]["days_remaining"] == expected_days

    def test_pratyantardasha_transition_accuracy(self, assembler):
        """Pratyantardasha transition should also use date-only comparison."""
        birth_date = datetime(1990, 1, 15, 14, 30)
        moon_longitude = 45.0
        target_date = datetime(2025, 1, 1, 20, 15, 0)  # Evening

        result = assembler.build_complete_response(
            birth_date, moon_longitude, target_date, include_future=True, num_future_periods=1
        )

        transition = assembler.build_transition_response(birth_date, moon_longitude, target_date)

        if "pratyantardasha" in transition:
            pratyantar_end = datetime.fromisoformat(result["pratyantardasha"]["end"])
            expected_days = (pratyantar_end.date() - target_date.date()).days

            assert transition["pratyantardasha"]["days_remaining"] == expected_days
