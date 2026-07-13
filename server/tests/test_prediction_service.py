"""
Unit tests for PredictionService — transit-trigger computation, monthly hypothesis
generation, Bayesian prior adjustment, peak-window identification, and full reports.
"""

from __future__ import annotations

import pytest

from services.prediction_service import PredictionService


class TestPredictionService:
    """Test PredictionService core calculations."""

    @pytest.fixture
    def service(self):
        return PredictionService()

    @pytest.fixture
    def sample_birth_data(self):
        """Standard birth data for prediction tests — Mumbai, Jan 15 1990, 2:30 PM IST."""
        return {
            "date": "1990-01-15",
            "time": "14:30:00",
            "timezone": "Asia/Kolkata",
            "latitude": 19.0760,
            "longitude": 72.8777,
            "location_name": "Mumbai, India",
        }

    @pytest.fixture
    def sample_dasha_state(self):
        """Sample dasha state for use in hypothesis generation."""
        return {
            "mahadasha": {
                "lord": "Jupiter",
                "start": "2023-01-01",
                "end": "2039-01-01",
            },
            "antardasha": {
                "lord": "Mercury",
                "start": "2025-06-01",
                "end": "2027-12-01",
            },
        }

    @pytest.fixture
    def two_year_range(self):
        """2-year window producing a healthy number of transit triggers."""
        return "2025-01-01", "2027-01-01"

    @pytest.fixture
    def one_year_range(self):
        """Exactly 12 months — Jan through Dec of a single year."""
        return "2025-01-01", "2025-12-31"

    # ------------------------------------------------------------------
    # Trigger computation
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_trigger_computation(self, service, sample_birth_data, two_year_range):
        """Known birth data + 2-year date range -> returns list of transit triggers."""
        start_date, end_date = two_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )

        assert isinstance(triggers, list)
        # With 3 slow planets x 9 natal planets x 4 aspect types over 2 years,
        # we expect a meaningful number of triggers
        assert len(triggers) > 0, "Expected at least some transit triggers"

        # Verify each trigger has required keys
        for t in triggers:
            for key in [
                "date",
                "transiting_planet",
                "natal_planet",
                "aspect_type",
                "orb",
                "house_activated",
                "event_class",
                "interpretation",
            ]:
                assert key in t, f"Missing trigger key: {key}"

        # Triggers should be sorted by date
        dates = [t["date"] for t in triggers]
        assert dates == sorted(dates), "Triggers should be sorted by date"

        # Verify transiting planet is one of the slow planets
        valid_transiting = {"Jupiter", "Saturn", "Rahu", "Ketu"}
        for t in triggers:
            assert t["transiting_planet"] in valid_transiting, (
                f"Unexpected transiting planet: {t['transiting_planet']}"
            )

        # Verify aspect types are valid
        valid_aspects = {"conjunction", "opposition", "trine", "square"}
        for t in triggers:
            assert t["aspect_type"] in valid_aspects, (
                f"Unexpected aspect type: {t['aspect_type']}"
            )

    # ------------------------------------------------------------------
    # Monthly hypotheses
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_monthly_hypotheses_generated(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """12-month range -> returns exactly 12 monthly entries."""
        start_date, end_date = one_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )
        hypotheses = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, start_date, end_date
        )

        assert isinstance(hypotheses, list)
        assert len(hypotheses) == 12, (
            f"Expected 12 monthly hypotheses, got {len(hypotheses)}"
        )

        # Months should be sequential Jan through Dec 2025
        expected_months = [f"2025-{m:02d}" for m in range(1, 13)]
        actual_months = [h["month"] for h in hypotheses]
        assert actual_months == expected_months, (
            f"Expected {expected_months}, got {actual_months}"
        )

    @pytest.mark.unit
    def test_monthly_hypotheses_structure(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """Each monthly hypothesis has the expected structure."""
        start_date, end_date = one_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )
        hypotheses = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, start_date, end_date
        )

        required_keys = [
            "month",
            "primary_theme",
            "secondary_theme",
            "headline",
            "trigger_summary",
            "action_guidance",
            "caution",
            "probability_band",
            "trigger_count",
            "dasha_context",
        ]

        for h in hypotheses:
            for key in required_keys:
                assert key in h, f"Missing hypothesis key: {key}"

            # Dasha context should carry the lords
            assert h["dasha_context"]["mahadasha_lord"] == "Jupiter"
            assert h["dasha_context"]["antardasha_lord"] == "Mercury"

            # Probability band must be a valid value
            valid_bands = {"low", "medium-low", "medium", "medium-high", "high"}
            assert h["probability_band"] in valid_bands, (
                f"Invalid probability band: {h['probability_band']}"
            )

    # ------------------------------------------------------------------
    # Bayesian priors
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_bayesian_priors_modify_probability(
        self, service, sample_birth_data, sample_dasha_state, two_year_range
    ):
        """Same chart with/without user priors -> probability bands differ."""
        start_date, end_date = two_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )
        hypotheses_no_priors = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, start_date, end_date
        )

        # Apply priors that strongly align with 'career' theme
        user_priors = {
            "projects": [
                {"name": "Astro Launch", "domain": "career", "stage": "launch"},
                {"name": "Revenue Engine", "domain": "capital", "stage": "active"},
            ],
            "career_target": "VP of Engineering",
            "current_focus": "career transition",
        }
        hypotheses_with_priors = service.apply_bayesian_priors(
            hypotheses_no_priors, user_priors
        )

        assert len(hypotheses_with_priors) == len(hypotheses_no_priors)

        # At least some months should have had their band adjusted upward
        adjustments_found = 0
        for i, (before, after) in enumerate(
            zip(hypotheses_no_priors, hypotheses_with_priors)
        ):
            if before["probability_band"] != after["probability_band"]:
                adjustments_found += 1
                # Should only boost, never reduce
                from services.prediction_service import PROBABILITY_BANDS
                before_idx = PROBABILITY_BANDS.index(before["probability_band"])
                after_idx = PROBABILITY_BANDS.index(after["probability_band"])
                assert after_idx >= before_idx, (
                    f"Month {after['month']}: band reduced from "
                    f"{before['probability_band']} to {after['probability_band']}"
                )

            # Prior context should be present
            assert "prior_context" in after
            assert len(after["prior_context"]) > 0

        assert adjustments_found > 0, (
            "Expected at least some months to have adjusted probability bands"
        )

    @pytest.mark.unit
    def test_bayesian_priors_no_user_priors(self, service, sample_birth_data, sample_dasha_state, one_year_range):
        """Empty priors should leave bands unchanged."""
        start_date, end_date = one_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )
        hypotheses = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, start_date, end_date
        )

        # Apply empty priors
        updated = service.apply_bayesian_priors(hypotheses, {})
        assert len(updated) == len(hypotheses)

        # No adjustments should occur
        for before, after in zip(hypotheses, updated):
            assert before["probability_band"] == after["probability_band"]
            assert after["prior_alignment_score"] == 0.0

    # ------------------------------------------------------------------
    # Peak windows
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_peak_windows_identified(
        self, service, sample_birth_data, sample_dasha_state, two_year_range
    ):
        """Multi-year range -> peak windows are detected in full report."""
        start_date, end_date = two_year_range
        report = service.full_prediction_report(
            sample_birth_data, sample_dasha_state, start_date, end_date
        )

        assert "peak_windows" in report
        peaks = report["peak_windows"]
        assert isinstance(peaks, list)
        assert len(peaks) > 0, "Expected at least one peak window"

        for peak in peaks:
            assert "date_range" in peak
            assert "theme" in peak
            assert "probability" in peak

    # ------------------------------------------------------------------
    # DO / AVOID
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_each_month_has_do_avoid(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """Every monthly hypothesis has non-empty action_guidance and caution."""
        start_date, end_date = one_year_range
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date, end_date
        )
        hypotheses = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, start_date, end_date
        )

        for h in hypotheses:
            assert "action_guidance" in h
            assert "caution" in h
            assert isinstance(h["action_guidance"], str)
            assert isinstance(h["caution"], str)
            assert len(h["action_guidance"]) > 0, (
                f"Month {h['month']}: action_guidance is empty"
            )
            assert len(h["caution"]) > 0, (
                f"Month {h['month']}: caution is empty"
            )

    # ------------------------------------------------------------------
    # Edge cases
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_invalid_date_range_handled(self, service, sample_birth_data):
        """Start date after end date -> graceful handling (empty triggers or handled)."""
        triggers = service.compute_transit_triggers(
            sample_birth_data, start_date="2026-01-01", end_date="2025-01-01"
        )

        # Should return an empty list or handle gracefully without crashing
        assert isinstance(triggers, list)
        # With a reversed date range, no valid triggers should be found
        assert len(triggers) == 0, (
            f"Expected 0 triggers for reversed date range, got {len(triggers)}"
        )

    @pytest.mark.unit
    def test_monthly_hypotheses_with_empty_triggers(
        self, service, sample_dasha_state
    ):
        """Generating hypotheses with no triggers should still produce monthly entries."""
        empty_triggers: list = []
        hypotheses = service.generate_monthly_hypotheses(
            empty_triggers, sample_dasha_state, "2025-03-01", "2025-06-30"
        )

        # Should produce exactly 4 months (March, April, May, June 2025)
        assert len(hypotheses) == 4
        expected_months = ["2025-03", "2025-04", "2025-05", "2025-06"]
        assert [h["month"] for h in hypotheses] == expected_months

        # All should have dasha-only guidance
        for h in hypotheses:
            assert h["trigger_count"] == 0
            assert len(h["action_guidance"]) > 0
            assert len(h["caution"]) > 0

    # ------------------------------------------------------------------
    # Full report
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_full_report_structure(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """Verify all expected keys in full prediction report."""
        start_date, end_date = one_year_range
        report = service.full_prediction_report(
            sample_birth_data, sample_dasha_state, start_date, end_date
        )

        top_level_keys = [
            "triggers",
            "monthly_timeline",
            "summary",
            "peak_windows",
            "geographic_hint",
            "metadata",
        ]
        for key in top_level_keys:
            assert key in report, f"Missing report key: {key}"

        # Metadata sub-keys
        meta = report["metadata"]
        for key in ["start_date", "end_date", "trigger_count", "months_covered", "has_user_priors"]:
            assert key in meta, f"Missing metadata key: {key}"
        assert meta["start_date"] == start_date
        assert meta["end_date"] == end_date
        assert meta["months_covered"] == 12

        # Summary should be a non-trivial string
        assert isinstance(report["summary"], str)
        assert len(report["summary"]) > 50

        # Geographic hint should be non-empty
        assert isinstance(report["geographic_hint"], str)
        assert len(report["geographic_hint"]) > 10

    @pytest.mark.unit
    def test_full_report_with_priors(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """Full report with user priors includes prior-augmented hypotheses."""
        start_date, end_date = one_year_range
        user_priors = {
            "projects": [{"name": "Product Launch", "domain": "career", "stage": "active"}],
            "career_target": "CTO",
            "current_focus": "leadership",
        }

        report = service.full_prediction_report(
            sample_birth_data, sample_dasha_state, start_date, end_date,
            user_priors=user_priors,
        )

        assert report["metadata"]["has_user_priors"] is True
        assert isinstance(report["monthly_timeline"], list)
        assert len(report["monthly_timeline"]) == 12

        # Monthly timeline entries should include prior_context when priors applied
        for h in report["monthly_timeline"]:
            assert "prior_context" in h

    @pytest.mark.unit
    def test_full_report_accepts_swift_client_string_projects(
        self, service, sample_birth_data, sample_dasha_state, one_year_range
    ):
        """Swift sends projects as [String]; launch API must not 500 on that shape."""
        start_date, end_date = one_year_range
        user_priors = {
            "projects": ["Astronova launch", "Revenue engine"],
            "current_focus": "launch career capital",
        }

        report = service.full_prediction_report(
            sample_birth_data, sample_dasha_state, start_date, end_date,
            user_priors=user_priors,
        )

        assert report["metadata"]["has_user_priors"] is True
        assert isinstance(report["monthly_timeline"], list)
        assert len(report["monthly_timeline"]) == 12
        assert "Astronova launch" in report["summary"]
        assert all("prior_context" in h for h in report["monthly_timeline"])

    @pytest.mark.unit
    def test_single_month_range(self, service, sample_birth_data, sample_dasha_state):
        """Single-month range should produce exactly 1 monthly hypothesis."""
        triggers = service.compute_transit_triggers(
            sample_birth_data, "2025-06-01", "2025-06-30"
        )
        hypotheses = service.generate_monthly_hypotheses(
            triggers, sample_dasha_state, "2025-06-01", "2025-06-30"
        )

        assert len(hypotheses) == 1
        assert hypotheses[0]["month"] == "2025-06"

    @pytest.mark.unit
    def test_geographic_hint_produced(self, service, sample_birth_data, sample_dasha_state, two_year_range):
        """Geographic hint references a cardinal direction."""
        start_date, end_date = two_year_range
        report = service.full_prediction_report(
            sample_birth_data, sample_dasha_state, start_date, end_date
        )

        hint = report["geographic_hint"]
        cardinal_directions = [
            "East", "West", "North", "South",
            "Northeast", "Northwest", "Southeast", "Southwest",
        ]
        has_direction = any(d in hint for d in cardinal_directions)
        assert has_direction or "current base" in hint.lower(), (
            f"Geographic hint should reference a direction; got: {hint}"
        )
