"""
Unit tests for RajayogaService — Rajayoga pattern detection, optimization matrix,
constraint extraction, and archetype labeling.
"""

from __future__ import annotations

import pytest

from services.rajayoga_service import RajayogaService


class TestRajayogaService:
    """Test RajayogaService core calculations."""

    @pytest.fixture
    def service(self):
        return RajayogaService()

    # ------------------------------------------------------------------
    # Known chart fixtures
    # ------------------------------------------------------------------

    @staticmethod
    def _sagittarius_jupiter_5th_venus_11th() -> dict:
        """Sagittarius Lagna, Jupiter in 5th (Aries), Venus own-sign 11th (Libra).

        Other planets placed neutrally to avoid noise.
        """
        return {
            "Sun":    {"sign": "Leo",     "degree": 15.0, "house": 9,  "retrograde": False},
            "Moon":   {"sign": "Cancer",  "degree": 10.0, "house": 8,  "retrograde": False},
            "Mars":   {"sign": "Gemini",  "degree": 15.0, "house": 7,  "retrograde": False},
            "Mercury": {"sign": "Virgo",  "degree": 12.0, "house": 10, "retrograde": False},
            "Jupiter": {"sign": "Aries",  "degree": 20.0, "house": 5,  "retrograde": False},
            "Venus":   {"sign": "Libra",  "degree": 10.0, "house": 11, "retrograde": False},
            "Saturn":  {"sign": "Aquarius","degree": 5.0,  "house": 3,  "retrograde": False},
        }

    @staticmethod
    def _chart_with_exalted_mars() -> dict:
        """Mars at 28 deg Capricorn (exact exaltation point)."""
        return {
            "Sun":     {"sign": "Leo",       "degree": 15.0, "house": 1,  "retrograde": False},
            "Moon":    {"sign": "Taurus",    "degree": 10.0, "house": 10, "retrograde": False},
            "Mars":    {"sign": "Capricorn", "degree": 28.0, "house": 6,  "retrograde": False},
            "Mercury": {"sign": "Leo",       "degree": 5.0,  "house": 1,  "retrograde": False},
            "Jupiter": {"sign": "Pisces",    "degree": 20.0, "house": 8,  "retrograde": False},
            "Venus":   {"sign": "Virgo",     "degree": 12.0, "house": 2,  "retrograde": False},
            "Saturn":  {"sign": "Scorpio",   "degree": 15.0, "house": 4,  "retrograde": False},
        }

    @staticmethod
    def _chart_with_debilitated_saturn() -> dict:
        """Saturn at 20 deg Aries (exact debilitation point)."""
        return {
            "Sun":     {"sign": "Cancer",  "degree": 10.0, "house": 1,  "retrograde": False},
            "Moon":    {"sign": "Pisces",  "degree": 5.0,  "house": 9,  "retrograde": False},
            "Mars":    {"sign": "Leo",     "degree": 18.0, "house": 2,  "retrograde": False},
            "Mercury": {"sign": "Gemini",  "degree": 15.0, "house": 12, "retrograde": False},
            "Jupiter": {"sign": "Taurus",  "degree": 12.0, "house": 11, "retrograde": False},
            "Venus":   {"sign": "Cancer",  "degree": 8.0,  "house": 1,  "retrograde": False},
            "Saturn":  {"sign": "Aries",   "degree": 20.0, "house": 10, "retrograde": False},
        }

    @staticmethod
    def _chart_with_mercury_12th() -> dict:
        """Mercury in 12th house for constraint testing."""
        return {
            "Sun":     {"sign": "Taurus",  "degree": 15.0, "house": 5,  "retrograde": False},
            "Moon":    {"sign": "Virgo",   "degree": 10.0, "house": 9,  "retrograde": False},
            "Mars":    {"sign": "Aries",   "degree": 5.0,  "house": 4,  "retrograde": False},
            "Mercury": {"sign": "Sagittarius","degree": 20.0,"house": 12, "retrograde": False},
            "Jupiter": {"sign": "Cancer",  "degree": 15.0, "house": 7,  "retrograde": False},
            "Venus":   {"sign": "Gemini",  "degree": 10.0, "house": 6,  "retrograde": False},
            "Saturn":  {"sign": "Capricorn","degree": 8.0,  "house": 1,  "retrograde": False},
        }

    # ------------------------------------------------------------------
    # Rajayoga detection
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_detect_rajayoga_sagittarius_lagna(self, service):
        """Known Sagittarius chart with Jupiter 5th, Venus 11th -> detects yogas."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        result = service.detect_rajayoga_patterns(planet_data, "Sagittarius")

        assert "yogas" in result
        assert "blemishes" in result
        assert "summary" in result
        assert result["lagna"] == "Sagittarius"

        yoga_names = [y["name"] for y in result["yogas"]]
        assert "Lagna Lord in 5th" in yoga_names, (
            f"Expected Lagna Lord in 5th yoga; got {yoga_names}"
        )
        assert "Venus Own-Sign 11th Network Engine" in yoga_names, (
            f"Expected Venus 11th yoga; got {yoga_names}"
        )

        # Sagittarius Lagna lord is Jupiter; Jupiter is in house 5
        lagna_lord_yoga = [y for y in result["yogas"] if "Lagna Lord" in y["name"]][0]
        assert lagna_lord_yoga["strength"] == "strong"

    @pytest.mark.unit
    def test_detect_rajayoga_jupiter_aspect_lagna(self, service):
        """Jupiter in 5th (Aries) aspects Lagna -> Jupiter Aspect on Lagna."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        result = service.detect_rajayoga_patterns(planet_data, "Sagittarius")

        yoga_names = [y["name"] for y in result["yogas"]]
        assert "Jupiter Aspect on Lagna" in yoga_names, (
            f"Expected Jupiter Aspect on Lagna; got {yoga_names}"
        )

    # ------------------------------------------------------------------
    # Optimization matrix
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_exalted_mars_detection(self, service):
        """Mars at 28 deg Capricorn -> optimization matrix shows EXALTED."""
        planet_data = self._chart_with_exalted_mars()
        result = service.get_optimization_matrix(planet_data)

        assert "planets" in result
        assert result["exalted_count"] >= 1

        mars_entry = [p for p in result["planets"] if p["planet"] == "Mars"][0]
        assert mars_entry["status"] == "exalted"
        assert "EXALTED" in mars_entry["status_color"]
        assert "exaltation" in mars_entry["status_reason"].lower()
        assert mars_entry["sign"] == "Capricorn"

    @pytest.mark.unit
    def test_debilitated_saturn_detection(self, service):
        """Saturn at 20 deg Aries -> DEBILITATED status with reason."""
        planet_data = self._chart_with_debilitated_saturn()
        result = service.get_optimization_matrix(planet_data)

        assert result["debilitated_count"] >= 1

        saturn_entry = [p for p in result["planets"] if p["planet"] == "Saturn"][0]
        assert saturn_entry["status"] == "debilitated"
        assert "DEBILITATED" in saturn_entry["status_color"]
        assert "debilitation" in saturn_entry["status_reason"].lower()
        assert saturn_entry["sign"] == "Aries"

    @pytest.mark.unit
    def test_optimization_matrix_all_planets(self, service):
        """Returns entries for all 7 classical planets (Sun through Saturn)."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        result = service.get_optimization_matrix(planet_data)

        planets_found = {p["planet"] for p in result["planets"]}
        expected = {"Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"}
        assert planets_found == expected, f"Expected {expected}, got {planets_found}"

        for entry in result["planets"]:
            assert "planet" in entry
            assert "sign" in entry
            assert "house" in entry
            assert "degree" in entry
            assert "status" in entry
            assert "status_color" in entry
            assert "status_reason" in entry
            assert "directional_strength_note" in entry

    # ------------------------------------------------------------------
    # Constraint extraction
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_constraints_extracted(self, service):
        """Chart with Mercury in 12th -> constraint about hidden expenses appears."""
        planet_data = self._chart_with_mercury_12th()
        yoga_results = service.detect_rajayoga_patterns(planet_data, "Capricorn")
        constraints = service.extract_constraints(planet_data, "Capricorn", yoga_results)

        assert isinstance(constraints, list)
        assert len(constraints) > 0

        # Mercury in 12th should produce a "12th House" constraint
        constraint_titles = [c["title"] for c in constraints]
        has_12th = any("12th" in title for title in constraint_titles)
        assert has_12th, f"Expected 12th house constraint; got {constraint_titles}"

        for c in constraints:
            assert "title" in c
            assert "description" in c
            assert "guardrail" in c
            assert "severity" in c
            assert c["severity"] in ("critical", "high", "moderate")

    @pytest.mark.unit
    def test_constraints_no_more_than_five(self, service):
        """Constraints are capped at top 5 by severity."""
        # Use a chart with multiple debilitated planets and dusthana placements
        # to potentially generate many constraints
        complex_chart = {
            "Sun":     {"sign": "Libra",   "degree": 10.0, "house": 12, "retrograde": False},  # debilitated + 12th
            "Moon":    {"sign": "Scorpio", "degree": 3.0,  "house": 12, "retrograde": False},  # debilitated + 12th
            "Mars":    {"sign": "Cancer",  "degree": 28.0, "house": 6,  "retrograde": False},  # debilitated + dusthana
            "Mercury": {"sign": "Pisces",  "degree": 15.0, "house": 12, "retrograde": False},  # debilitated + 12th
            "Jupiter": {"sign": "Leo",     "degree": 5.0,  "house": 8,  "retrograde": False},  # dusthana
            "Venus":   {"sign": "Gemini",  "degree": 27.0, "house": 2,  "retrograde": False},
            "Saturn":  {"sign": "Aquarius","degree": 5.0,  "house": 11, "retrograde": False},
        }
        yoga_results = service.detect_rajayoga_patterns(complex_chart, "Leo")
        constraints = service.extract_constraints(complex_chart, "Leo", yoga_results)

        assert len(constraints) <= 5, f"Got {len(constraints)} constraints, expected <=5"

    # ------------------------------------------------------------------
    # Archetype labeling
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_archetype_labeling(self, service):
        """Known chart -> returns primary and secondary archetype labels."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        yoga_results = service.detect_rajayoga_patterns(planet_data, "Sagittarius")
        archetype = service.determine_archetype(planet_data, "Sagittarius", yoga_results)

        assert "primary" in archetype
        assert "secondary" in archetype
        assert "synthesis" in archetype
        assert "signals_detected" in archetype

        assert isinstance(archetype["primary"], str)
        assert len(archetype["primary"]) > 0
        assert isinstance(archetype["secondary"], str)
        assert len(archetype["secondary"]) > 0
        assert isinstance(archetype["synthesis"], str)
        assert len(archetype["synthesis"]) > 50
        assert isinstance(archetype["signals_detected"], list)

        # Sagittarius Lagna is Fire element, should have fire-related signal
        assert any("fire" in s.lower() for s in archetype["signals_detected"]), (
            f"Sagittarius (Fire) should produce fire_lagna; signals: {archetype['signals_detected']}"
        )

    @pytest.mark.unit
    def test_archetype_with_no_matches_falls_back(self, service):
        """Empty chart with no distinguishing features -> gets a fallback archetype."""
        sparse_chart = {
            "Sun":     {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Moon":    {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Mars":    {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Mercury": {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Jupiter": {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Venus":   {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
            "Saturn":  {"sign": "Aries", "degree": 1.0, "house": 1, "retrograde": False},
        }
        yoga_results = service.detect_rajayoga_patterns(sparse_chart, "Aries")
        archetype = service.determine_archetype(sparse_chart, "Aries", yoga_results)

        # Should always return a non-empty primary archetype
        assert archetype["primary"] is not None
        assert len(archetype["primary"]) > 0
        assert archetype["secondary"] is not None

    # ------------------------------------------------------------------
    # Full report
    # ------------------------------------------------------------------

    @pytest.mark.unit
    def test_full_report_structure(self, service):
        """Verify all expected keys in full rajayoga report."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        report = service.full_rajayoga_report(planet_data, "Sagittarius")

        # Top-level keys
        for key in ["yoga_analysis", "optimization_matrix", "constraints", "archetype"]:
            assert key in report, f"Missing report key: {key}"

        # Yoga analysis sub-keys
        ya = report["yoga_analysis"]
        for key in ["lagna", "yogas", "blemishes", "yoga_count", "blemish_count", "summary"]:
            assert key in ya, f"Missing yoga_analysis key: {key}"

        # Optimization matrix sub-keys
        om = report["optimization_matrix"]
        for key in ["planets", "exalted_count", "debilitated_count", "summary"]:
            assert key in om, f"Missing optimization_matrix key: {key}"

        # Constraints is a list
        assert isinstance(report["constraints"], list)

        # Archetype sub-keys
        arch = report["archetype"]
        for key in ["primary", "secondary", "synthesis", "signals_detected"]:
            assert key in arch, f"Missing archetype key: {key}"

    @pytest.mark.unit
    def test_vedic_sign_alias_normalisation(self, service):
        """Vedic alias 'Dhanu' normalises to 'Sagittarius' for lagna."""
        planet_data = self._sagittarius_jupiter_5th_venus_11th()
        result = service.detect_rajayoga_patterns(planet_data, "dhanu")

        assert result["lagna"] == "Sagittarius"
        # Same yogas as with "Sagittarius" input
        yoga_names = [y["name"] for y in result["yogas"]]
        assert "Lagna Lord in 5th" in yoga_names

    @pytest.mark.unit
    def test_own_sign_detection(self, service):
        """Planet in its own sign returns own_sign status."""
        planet_data = {
            "Sun": {"sign": "Leo", "degree": 15.0, "house": 1, "retrograde": False},
        }
        result = service.get_optimization_matrix(planet_data)
        sun = result["planets"][0]
        assert sun["status"] == "own_sign"
        assert "OWN_SIGN" in sun["status_color"]
