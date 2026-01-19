"""Unit tests for TransitService."""

import pytest
from datetime import datetime
from unittest.mock import MagicMock

from services.transit_service import (
    TransitService,
    _angular_distance,
    _check_aspect,
)

try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False


class TestAngularDistance:
    """Tests for the _angular_distance helper function."""

    def test_zero_distance(self):
        """Two identical longitudes should have zero distance."""
        assert _angular_distance(120.0, 120.0) == 0.0

    def test_simple_distance(self):
        """Simple angular distance within same hemisphere."""
        assert _angular_distance(30.0, 60.0) == 30.0
        assert _angular_distance(60.0, 30.0) == 30.0

    def test_wraparound_distance(self):
        """Distance should handle 360-degree wraparound correctly."""
        # 350 to 10 should be 20 degrees, not 340
        assert _angular_distance(350.0, 10.0) == 20.0
        assert _angular_distance(10.0, 350.0) == 20.0

    def test_opposition_distance(self):
        """180 degrees should be the maximum distance."""
        assert _angular_distance(0.0, 180.0) == 180.0
        assert _angular_distance(90.0, 270.0) == 180.0


class TestCheckAspect:
    """Tests for the _check_aspect helper function."""

    def test_exact_conjunction(self):
        """Exact conjunction should return strength 1.0."""
        result = _check_aspect(120.0, 120.0)
        assert result is not None
        aspect_type, orb_diff, strength = result
        assert aspect_type == "conjunction"
        assert orb_diff == 0.0
        assert strength == 1.0

    def test_exact_trine(self):
        """Exact trine (120 degrees apart) should be detected."""
        result = _check_aspect(0.0, 120.0)
        assert result is not None
        aspect_type, orb_diff, strength = result
        assert aspect_type == "trine"
        assert orb_diff == 0.0
        assert strength == 1.0

    def test_exact_square(self):
        """Exact square (90 degrees apart) should be detected."""
        result = _check_aspect(0.0, 90.0)
        assert result is not None
        aspect_type, orb_diff, strength = result
        assert aspect_type == "square"
        assert orb_diff == 0.0
        assert strength == 1.0

    def test_exact_opposition(self):
        """Exact opposition (180 degrees apart) should be detected."""
        result = _check_aspect(0.0, 180.0)
        assert result is not None
        aspect_type, orb_diff, strength = result
        assert aspect_type == "opposition"
        assert orb_diff == 0.0
        assert strength == 1.0

    def test_aspect_within_orb(self):
        """Aspect within orb should still be detected but with reduced strength."""
        # Conjunction with 4 degree orb (max orb is 8)
        result = _check_aspect(120.0, 124.0)
        assert result is not None
        aspect_type, orb_diff, strength = result
        assert aspect_type == "conjunction"
        assert orb_diff == 4.0
        assert strength == 0.5  # 1.0 - (4/8)

    def test_no_aspect(self):
        """No aspect should be detected when planets are not in aspect."""
        # 45 degrees is not a major aspect
        result = _check_aspect(0.0, 45.0)
        assert result is None

        # Just outside conjunction orb
        result = _check_aspect(0.0, 10.0)
        assert result is None


class TestTransitService:
    """Tests for the TransitService class."""

    @pytest.fixture
    def mock_ephemeris(self):
        """Create a mock ephemeris service."""
        mock = MagicMock()
        return mock

    @pytest.fixture
    def transit_service(self, mock_ephemeris):
        """Create a TransitService with mocked ephemeris."""
        return TransitService(mock_ephemeris)

    @pytest.fixture
    def sample_natal_a(self):
        """Sample natal positions for person A."""
        return {
            "planets": {
                "sun": {"longitude": 267.0, "sign": "Sagittarius"},
                "moon": {"longitude": 239.0, "sign": "Scorpio"},
                "venus": {"longitude": 273.0, "sign": "Capricorn"},
                "mars": {"longitude": 60.0, "sign": "Taurus"},
                "mercury": {"longitude": 280.0, "sign": "Capricorn"},
            }
        }

    @pytest.fixture
    def sample_natal_b(self):
        """Sample natal positions for person B."""
        return {
            "planets": {
                "sun": {"longitude": 354.0, "sign": "Pisces"},
                "moon": {"longitude": 148.0, "sign": "Leo"},
                "venus": {"longitude": 314.0, "sign": "Aquarius"},
                "mars": {"longitude": 134.0, "sign": "Leo"},
                "mercury": {"longitude": 330.0, "sign": "Pisces"},
            }
        }

    @pytest.fixture
    def sample_aspects(self):
        """Sample synastry aspects."""
        return [
            {
                "planet1": "Sun",
                "planet2": "Moon",
                "aspect": "trine",
                "compatibility": 1.0,
            },
            {
                "planet1": "Venus",
                "planet2": "Mars",
                "aspect": "sextile",
                "compatibility": 0.8,
            },
            {
                "planet1": "Moon",
                "planet2": "Moon",
                "aspect": "square",
                "compatibility": -0.5,
            },
        ]

    def test_is_aspect_activated_now_with_triggering_transit(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b
    ):
        """Test that aspects are detected as activated when transits trigger them."""
        # Set up mock ephemeris to return a transit Venus at a position
        # that trines natal Sun A (at 267 degrees)
        # Venus at 27 degrees would be trine to 267 (27 + 120 = 147, 267 - 120 = 147...
        # Actually 267 - 240 = 27, so Venus at 27 would be ~240 apart. Let's use 147.)
        # Actually, let's use 147 degrees which is trine to 267 (267 - 120 = 147)
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 268.0},
                "moon": {"longitude": 147.0},  # Trine to natal Sun A at 267
                "venus": {"longitude": 100.0},
                "mars": {"longitude": 200.0},
                "mercury": {"longitude": 250.0},
            }
        }

        aspect = {"planet1": "Sun", "planet2": "Moon", "aspect": "trine", "compatibility": 1.0}
        is_active, strength = transit_service.is_aspect_activated_now(
            aspect, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert is_active is True
        assert strength > 0.0

    def test_is_aspect_activated_now_no_trigger(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b
    ):
        """Test that aspects are not activated when no transits trigger them."""
        # Set up transits that don't aspect any natal planets involved
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 45.0},  # Not aspecting anything in our test
                "moon": {"longitude": 45.0},
                "venus": {"longitude": 45.0},
                "mars": {"longitude": 45.0},
                "mercury": {"longitude": 45.0},
            }
        }

        aspect = {"planet1": "Sun", "planet2": "Moon", "aspect": "trine", "compatibility": 1.0}
        is_active, strength = transit_service.is_aspect_activated_now(
            aspect, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert is_active is False
        assert strength == 0.0

    def test_calculate_pulse_from_transits_flowing(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b, sample_aspects
    ):
        """Test pulse calculation returns 'flowing' state with harmonious activations."""
        # Set up transits that activate harmonious aspects
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 267.0},  # Conjunct natal Sun A
                "moon": {"longitude": 147.0},  # Trine natal Sun A
                "venus": {"longitude": 60.0},  # Conjunct natal Mars A
                "mars": {"longitude": 200.0},
                "mercury": {"longitude": 250.0},
            }
        }

        pulse = transit_service.calculate_pulse_from_transits(
            sample_aspects, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert "state" in pulse
        assert "score" in pulse
        assert "label" in pulse
        assert "topActivations" in pulse
        assert isinstance(pulse["topActivations"], list)

    def test_calculate_pulse_from_transits_grounded(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b, sample_aspects
    ):
        """Test pulse returns 'grounded' state when no transits activate aspects."""
        # Set up transits that don't activate anything
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 45.0},
                "moon": {"longitude": 45.0},
                "venus": {"longitude": 45.0},
                "mars": {"longitude": 45.0},
                "mercury": {"longitude": 45.0},
            }
        }

        pulse = transit_service.calculate_pulse_from_transits(
            sample_aspects, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert pulse["state"] == "grounded"
        assert pulse["score"] == 55

    def test_find_next_significant_transit(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b, sample_aspects
    ):
        """Test finding the next significant transit activation."""
        # Mock ephemeris to return different positions for different dates
        def mock_get_positions(dt, *args, **kwargs):
            # Simulate a transit activation happening on day 3
            days_from_start = (dt - datetime.now()).days
            if days_from_start >= 3:
                return {
                    "planets": {
                        "sun": {"longitude": 267.0},  # Triggers activation
                        "moon": {"longitude": 147.0},
                        "venus": {"longitude": 273.0},
                        "mars": {"longitude": 200.0},
                        "mercury": {"longitude": 250.0},
                    }
                }
            return {
                "planets": {
                    "sun": {"longitude": 45.0},
                    "moon": {"longitude": 45.0},
                    "venus": {"longitude": 45.0},
                    "mars": {"longitude": 45.0},
                    "mercury": {"longitude": 45.0},
                }
            }

        mock_ephemeris.get_positions_for_date.side_effect = mock_get_positions

        result = transit_service.find_next_significant_transit(
            sample_aspects, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert "date" in result
        assert "days_away" in result
        assert "description" in result
        assert "predicted_state" in result
        assert "suggestion" in result

    def test_build_journey_forecast(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b, sample_aspects
    ):
        """Test building a 30-day journey forecast."""
        # Simple mock that returns consistent transits
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 267.0},
                "moon": {"longitude": 147.0},
                "venus": {"longitude": 100.0},
                "mars": {"longitude": 200.0},
                "mercury": {"longitude": 250.0},
            }
        }

        forecast = transit_service.build_journey_forecast(
            sample_aspects, datetime.now(), sample_natal_a, sample_natal_b, days=10
        )

        assert "dailyMarkers" in forecast
        assert "peakWindows" in forecast
        assert len(forecast["dailyMarkers"]) == 10

        # Each daily marker should have required fields
        for marker in forecast["dailyMarkers"]:
            assert "date" in marker
            assert "intensity" in marker
            assert marker["intensity"] in ["peak", "elevated", "neutral", "challenging", "quiet"]

    def test_get_day_activations(
        self, transit_service, mock_ephemeris, sample_natal_a, sample_natal_b, sample_aspects
    ):
        """Test getting activations for a specific day."""
        mock_ephemeris.get_positions_for_date.return_value = {
            "planets": {
                "sun": {"longitude": 267.0},  # Conjunct natal Sun A
                "moon": {"longitude": 147.0},
                "venus": {"longitude": 100.0},
                "mars": {"longitude": 200.0},
                "mercury": {"longitude": 250.0},
            }
        }

        activations = transit_service.get_day_activations(
            sample_aspects, datetime.now(), sample_natal_a, sample_natal_b
        )

        assert isinstance(activations, list)
        # Activations should be sorted by strength
        if len(activations) > 1:
            assert activations[0]["strength"] >= activations[1]["strength"]


class TestTransitServiceIntegration:
    """Integration tests using real ephemeris calculations."""

    @pytest.mark.skipif(not _SWE_OK, reason="pyswisseph not installed")
    def test_real_ephemeris_calculation(self):
        """Test with real ephemeris service (no mocking)."""
        from services.ephemeris_service import EphemerisService

        ephem = EphemerisService()
        transit = TransitService(ephem)

        # Real natal positions for test
        natal_a = {
            "planets": {
                "sun": {"longitude": 267.0},
                "moon": {"longitude": 239.0},
                "venus": {"longitude": 273.0},
                "mars": {"longitude": 60.0},
            }
        }
        natal_b = {
            "planets": {
                "sun": {"longitude": 354.0},
                "moon": {"longitude": 148.0},
                "venus": {"longitude": 314.0},
                "mars": {"longitude": 134.0},
            }
        }

        aspects = [
            {"planet1": "Sun", "planet2": "Moon", "aspect": "trine", "compatibility": 1.0},
            {"planet1": "Venus", "planet2": "Mars", "aspect": "sextile", "compatibility": 0.8},
        ]

        # Should not raise any exceptions
        pulse = transit.calculate_pulse_from_transits(
            aspects, datetime.now(), natal_a, natal_b
        )

        assert "state" in pulse
        assert "score" in pulse
        assert isinstance(pulse["score"], int)
        assert 0 <= pulse["score"] <= 100
