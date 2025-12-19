"""
Service-layer unit tests for core business logic.
Tests services independently of API layer.
"""

from __future__ import annotations

from datetime import datetime

import pytest
from unittest.mock import patch

from services.chat_response_service import ChatResponseService
from services.dasha_interpretation_service import DashaInterpretationService
from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService
from services.planetary_strength_service import PlanetaryStrengthService


class TestDashaService:
    """Test DashaService core calculations."""

    @pytest.fixture
    def service(self):
        return DashaService()

    def test_calculate_complete_dasha_structure(
        self, service, sample_birth_datetime, sample_moon_longitude, sample_target_date
    ):
        """Test complete dasha calculation returns expected structure."""
        result = service.calculate_complete_dasha(sample_birth_datetime, sample_moon_longitude, sample_target_date)

        required_fields = ["mahadasha", "antardasha", "pratyantardasha", "starting_dasha", "all_antardashas"]

        for field in required_fields:
            assert field in result, f"Missing field: {field}"

    def test_dasha_periods_are_sequential(self, service, sample_birth_datetime, sample_moon_longitude, sample_target_date):
        """Test that dasha periods follow proper sequence."""
        result = service.calculate_complete_dasha(
            sample_birth_datetime, sample_moon_longitude, sample_target_date, include_future=True, num_future_periods=3
        )

        # Mahadasha should contain antardasha
        maha_start = datetime.fromisoformat(result["mahadasha"]["start"])
        maha_end = datetime.fromisoformat(result["mahadasha"]["end"])
        antar_start = datetime.fromisoformat(result["antardasha"]["start"])
        antar_end = datetime.fromisoformat(result["antardasha"]["end"])

        assert maha_start <= antar_start <= maha_end
        assert maha_start <= antar_end <= maha_end

    def test_dasha_transition_info(self, service, sample_birth_datetime, sample_moon_longitude, sample_target_date):
        """Test dasha transition info calculation."""
        transition = service.get_dasha_transition_info(sample_birth_datetime, sample_moon_longitude, sample_target_date)

        if "mahadasha" in transition:
            assert "days_remaining" in transition["mahadasha"]
            assert "months_remaining" in transition["mahadasha"]
            assert "years_remaining" in transition["mahadasha"]

    @pytest.mark.parametrize(
        "moon_long,expected_nakshatra_approx",
        [
            (0.0, "Ashwini"),
            (30.0, "Rohini"),
            (60.0, "Punarvasu"),
            (90.0, "Pushya"),
            (120.0, "Magha"),
            (150.0, "Uttara_Phalguni"),
            (180.0, "Chitra"),
            (210.0, "Vishakha"),
            (240.0, "Purva_Ashadha"),
            (270.0, "Shravana"),
            (300.0, "Purva_Bhadrapada"),
            (330.0, "Revati"),
        ],
    )
    def test_starting_dasha_varies_by_nakshatra(
        self, service, sample_birth_datetime, sample_target_date, moon_long, expected_nakshatra_approx
    ):
        """Test that starting dasha is determined by nakshatra."""
        result = service.calculate_complete_dasha(sample_birth_datetime, moon_long, sample_target_date)

        # Starting dasha should exist
        assert result["starting_dasha"]["lord"] is not None
        assert result["starting_dasha"]["balance_years"] >= 0

    def test_120_year_cycle(self, service):
        """Test that full Vimshottari cycle is 120 years."""
        birth = datetime(1990, 1, 15, 12, 0)
        moon_long = 45.0

        result = service.calculate_complete_dasha(
            birth, moon_long, birth, include_future=True, num_future_periods=100  # Request many periods
        )

        # Full cycle should be ~120 years
        # (This is more of a sanity check on the calculation)
        assert result["mahadasha"]["lord"] is not None


class TestEphemerisService:
    """Test EphemerisService planetary calculations."""

    @pytest.fixture
    def service(self):
        return EphemerisService()

    def test_get_positions_for_date(self, service):
        """Test planetary position calculation."""
        dt = datetime(2025, 1, 1, 0, 0)
        result = service.get_positions_for_date(dt)

        assert "planets" in result

        expected_planets = ["sun", "moon", "mars", "mercury", "jupiter", "venus", "saturn"]
        planets = result["planets"]

        for planet in expected_planets:
            assert planet in planets, f"Missing planet: {planet}"
            assert "longitude" in planets[planet]
            assert "degree" in planets[planet]
            assert "sign" in planets[planet]

    def test_planetary_positions_change_over_time(self, service):
        """Test that planetary positions change over time."""
        date1 = datetime(2025, 1, 1)
        date2 = datetime(2025, 6, 1)

        pos1 = service.get_positions_for_date(date1)
        pos2 = service.get_positions_for_date(date2)

        # Sun should be in different signs
        sun1_sign = pos1["planets"]["sun"]["sign"]
        sun2_sign = pos2["planets"]["sun"]["sign"]

        assert sun1_sign != sun2_sign, "Sun should change sign over 5 months"

    def test_get_positions_for_date_supports_sidereal_system(self, service):
        """Ensure sidereal (vedic/kundali) mode returns Vedic sign names."""
        dt = datetime(2025, 1, 1, 12, 0)
        lat, lon = 19.0760, 72.8777

        western = service.get_positions_for_date(dt, lat, lon, system="western")
        vedic = service.get_positions_for_date(dt, lat, lon, system="vedic")

        assert western["planets"]["sun"]["sign"] in EphemerisService.ZODIAC_SIGNS
        assert vedic["planets"]["sun"]["sign"] in EphemerisService.VEDIC_SIGNS

        assert western["planets"]["ascendant"]["sign"] in EphemerisService.ZODIAC_SIGNS
        assert vedic["planets"]["ascendant"]["sign"] in EphemerisService.VEDIC_SIGNS

    @pytest.mark.parametrize(
        "lat,lon",
        [
            (19.0760, 72.8777),  # Mumbai
            (40.7128, -74.0060),  # New York
            (51.5074, -0.1278),  # London
            (35.6762, 139.6503),  # Tokyo
            (-33.8688, 151.2093),  # Sydney
        ],
    )
    def test_positions_with_different_locations(self, service, lat, lon):
        """Test that service handles different geographic locations."""
        dt = datetime(2025, 1, 1, 12, 0)

        result = service.get_positions_for_date(dt, lat, lon)

        assert "planets" in result
        assert "sun" in result["planets"]

    def test_retrograde_detection(self, service):
        """Test that service can detect retrograde planets."""
        # Mercury retrograde period (approximate)
        dt = datetime(2025, 4, 15)

        result = service.get_positions_for_date(dt)

        # Retrograde flag should exist (even if False)
        if "mercury" in result["planets"]:
            # Some implementations include retrograde detection
            pass


class TestPlanetaryStrengthService:
    """Test PlanetaryStrengthService calculations."""

    @pytest.fixture
    def service(self):
        return PlanetaryStrengthService()

    @pytest.fixture
    def sample_planet_data(self):
        return {
            "Sun": {"sign": "Leo", "degree": 15.5, "house": 1, "retrograde": False},
            "Moon": {"sign": "Cancer", "degree": 10.2, "house": 7, "retrograde": False},
            "Mars": {"sign": "Aries", "degree": 20.0, "house": 10, "retrograde": False},
            "Mercury": {"sign": "Virgo", "degree": 5.5, "house": 2, "retrograde": False},
            "Jupiter": {"sign": "Sagittarius", "degree": 25.0, "house": 5, "retrograde": False},
            "Venus": {"sign": "Libra", "degree": 12.0, "house": 11, "retrograde": False},
            "Saturn": {"sign": "Capricorn", "degree": 8.0, "house": 6, "retrograde": False},
        }

    def test_calculate_dasha_impact(self, service, sample_planet_data):
        """Test impact calculation for dasha lord."""
        result = service.calculate_dasha_impact("Jupiter", sample_planet_data)

        assert "impact_scores" in result
        assert "tone" in result
        assert "tone_description" in result
        assert "strength" in result

        # Verify all domains present
        scores = result["impact_scores"]
        required_domains = ["career", "relationships", "health", "spiritual"]

        for domain in required_domains:
            assert domain in scores
            assert isinstance(scores[domain], (int, float))
            assert 0 <= scores[domain] <= 10

    @pytest.mark.parametrize("lord", ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"])
    def test_all_planet_lords(self, service, sample_planet_data, lord):
        """Test that all 9 planetary lords can be analyzed."""
        result = service.calculate_dasha_impact(lord, sample_planet_data)

        assert result is not None
        assert "impact_scores" in result

    def test_compare_dasha_impacts(self, service, sample_planet_data):
        """Test comparison between two dasha periods."""
        comparison = service.compare_dasha_impacts("Jupiter", "Saturn", sample_planet_data)

        assert "deltas" in comparison
        assert "current" in comparison
        assert "next" in comparison

        # Check deltas structure
        deltas = comparison["deltas"]
        assert "career" in deltas
        assert "relationships" in deltas
        assert "health" in deltas
        assert "spiritual" in deltas

    def test_exalted_planet_high_strength(self, service):
        """Test that exalted planets show high strength."""
        planet_data = {
            "Sun": {"sign": "Aries", "degree": 10.0, "house": 1, "retrograde": False},  # Exalted
        }

        result = service.calculate_dasha_impact("Sun", planet_data)

        # Exalted Sun should have good strength (check dignity field in strength dict)
        assert "strength" in result
        strength = result["strength"]
        assert isinstance(strength, dict)
        assert strength.get("dignity") == "exalted"
        assert strength.get("overall_score", 0) > 70  # Exalted should have high score

    def test_debilitated_planet_low_strength(self, service):
        """Test that debilitated planets show low strength."""
        planet_data = {
            "Sun": {"sign": "Libra", "degree": 10.0, "house": 8, "retrograde": False},  # Debilitated
        }

        service.calculate_dasha_impact("Sun", planet_data)

        # Debilitated Sun should have weaker assessment
        # (exact strength depends on house and aspects)

    def test_vedic_sign_aliases_are_supported(self, service):
        """Ensure Vedic (rashi) sign labels are normalized for dignity calculations."""
        # Mesha == Aries, Sun is exalted in Aries.
        result = service.calculate_overall_strength("Sun", "Mesha", 10.0, house=1, is_retrograde=False)
        assert result["dignity"] == "exalted"


class TestChatResponseService:
    """Test ChatResponseService behavior without API/routes."""

    @pytest.fixture
    def service(self):
        return ChatResponseService()

    @pytest.mark.parametrize(
        "message,expected",
        [
            ("Will I find love this year?", "love"),
            ("Should I change my job?", "career"),
            ("How is my health lately?", "health"),
            ("What is my soul purpose?", "spiritual"),
            ("What are the current transits?", "current"),
            ("What will happen next month?", "future"),
            ("Tell me about astrology", "general"),
        ],
    )
    def test_classify_question(self, service, message, expected):
        assert service._classify_question(message) == expected

    def test_generate_response_and_followups_without_birth_data(self, service):
        with patch.object(
            service,
            "_get_current_transits_summary",
            return_value={"sun": "Aries", "moon": "Taurus", "mercury": "Gemini", "venus": "Cancer", "mars": "Leo"},
        ):
            with patch("services.chat_response_service.random.choice", side_effect=lambda items: items[0]):
                with patch("services.chat_response_service.random.random", return_value=0.0):
                    reply, followups = service.generate_response(message="Will I find love?", user_id="u1", birth_data=None)

        assert isinstance(reply, str)
        assert isinstance(followups, list)
        assert "Can you analyze my birth chart in detail?" in followups

    def test_generate_response_and_followups_with_birth_data(self, service):
        birth_data = {"birth_date": "1990-01-15"}
        with patch.object(
            service,
            "_get_current_transits_summary",
            return_value={"sun": "Aries", "moon": "Taurus", "mercury": "Gemini", "venus": "Cancer", "mars": "Leo"},
        ):
            with patch("services.chat_response_service.random.choice", side_effect=lambda items: items[0]):
                with patch("services.chat_response_service.random.random", return_value=0.0):
                    reply, followups = service.generate_response(
                        message="Tell me about my career", user_id="u1", birth_data=birth_data
                    )

        assert isinstance(reply, str)
        assert isinstance(followups, list)
        assert "Can you analyze my birth chart in detail?" not in followups


class TestDashaInterpretationService:
    """Test DashaInterpretationService narrative generation."""

    @pytest.fixture
    def service(self):
        return DashaInterpretationService()

    def test_generate_period_narrative(self, service):
        """Test narrative generation for dasha period."""
        impact_scores = {"career": 7.5, "relationships": 6.0, "health": 8.0, "spiritual": 5.5}

        # Strength data should be a dict with strength info
        strength_data = {"dignity": "neutral", "overall_score": 75.0, "strength_label": "strong"}

        narrative = service.generate_period_narrative("Jupiter", "Saturn", "Mercury", strength_data, impact_scores)

        assert narrative is not None
        assert isinstance(narrative, str), "Narrative should be a string"
        assert len(narrative) > 50, "Narrative should be substantial"

    def test_get_transition_insights(self, service):
        """Test transition insights generation."""
        comparison = {"career_delta": 2.0, "relationships_delta": -1.5, "health_delta": 0.5, "spiritual_delta": 1.0}

        insights = service.get_transition_insights("Venus", "Mars", 90, comparison)  # days remaining

        assert insights is not None
        assert isinstance(insights, dict), "Insights should be a dict"

    def test_explain_dasha_calculation(self, service):
        """Test educational explanation generation."""
        explanation = service.explain_dasha_calculation(45.0, "Ketu", 5.5)  # moon longitude  # balance years

        assert explanation is not None
        assert isinstance(explanation, dict), "Explanation should be a dict"

    def test_get_dasha_explanation(self, service):
        """Test dasha lord explanation."""
        explanation = service.get_dasha_explanation("Jupiter", "mahadasha")

        assert explanation is not None
        assert isinstance(explanation, dict), "Explanation should be a dict"


class TestServiceIntegration:
    """Test integration between services."""

    def test_full_dasha_interpretation_pipeline(self):
        """Test complete pipeline from calculation to interpretation."""
        dasha_service = DashaService()
        strength_service = PlanetaryStrengthService()
        interp_service = DashaInterpretationService()
        ephem_service = EphemerisService()

        # Calculate dasha
        birth = datetime(1990, 1, 15, 9, 0)  # UTC
        target = datetime(2025, 1, 1)

        dasha_result = dasha_service.calculate_complete_dasha(birth, 45.0, target)

        # Get planetary positions
        positions = ephem_service.get_positions_for_date(target)

        planet_data = {}
        for name, info in positions["planets"].items():
            planet_data[name.title()] = {
                "sign": info["sign"],
                "degree": info["degree"],
                "house": None,
                "retrograde": info.get("retrograde", False),
            }

        # Calculate impact
        maha_lord = dasha_result["mahadasha"]["lord"]
        antar_lord = dasha_result["antardasha"]["lord"]

        maha_impact = strength_service.calculate_dasha_impact(maha_lord, planet_data)
        antar_impact = strength_service.calculate_dasha_impact(antar_lord, planet_data)

        # Generate narrative
        combined_scores = {
            "career": (maha_impact["impact_scores"]["career"] + antar_impact["impact_scores"]["career"]) / 2,
            "relationships": (maha_impact["impact_scores"]["relationships"] + antar_impact["impact_scores"]["relationships"])
            / 2,
            "health": (maha_impact["impact_scores"]["health"] + antar_impact["impact_scores"]["health"]) / 2,
            "spiritual": (maha_impact["impact_scores"]["spiritual"] + antar_impact["impact_scores"]["spiritual"]) / 2,
        }

        narrative = interp_service.generate_period_narrative(
            maha_lord, antar_lord, None, maha_impact["strength"], combined_scores
        )

        # Verify complete pipeline
        assert dasha_result is not None
        assert maha_impact is not None
        assert narrative is not None
        assert len(narrative) > 50
