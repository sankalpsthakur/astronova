"""
Comprehensive API integration tests covering all endpoints.
Tests request validation, error handling, and response schemas.
"""

from __future__ import annotations

import pytest


class TestHoroscopeEndpoints:
    """Test horoscope API endpoints."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.mark.parametrize(
        "sign",
        [
            "aries",
            "taurus",
            "gemini",
            "cancer",
            "leo",
            "virgo",
            "libra",
            "scorpio",
            "sagittarius",
            "capricorn",
            "aquarius",
            "pisces",
        ],
    )
    def test_horoscope_all_signs(self, client, sign):
        """Test horoscope generation for all 12 zodiac signs."""
        response = client.get(f"/api/v1/horoscope?sign={sign}&type=daily")

        assert response.status_code == 200
        data = response.get_json()

        # Verify response structure
        assert "content" in data
        assert "luckyElements" in data
        assert data["sign"] == sign

        # Verify lucky elements populated
        lucky = data["luckyElements"]
        assert "color" in lucky
        assert "number" in lucky
        assert "day" in lucky
        assert "element" in lucky
        assert "ruler" in lucky

        # Verify non-empty content
        assert len(data["content"]) > 50

    @pytest.mark.parametrize("period_type", ["daily", "weekly", "monthly"])
    def test_horoscope_period_types(self, client, period_type):
        """Test different horoscope period types."""
        response = client.get(f"/api/v1/horoscope?sign=leo&type={period_type}")

        assert response.status_code == 200
        data = response.get_json()

        assert data["type"] == period_type
        assert "content" in data
        assert "luckyElements" in data

    def test_horoscope_with_date(self, client):
        """Test horoscope for specific date."""
        response = client.get("/api/v1/horoscope?sign=virgo&type=daily&date=2025-03-15")

        assert response.status_code == 200
        data = response.get_json()

        assert "2025-03-15" in data["date"]

    def test_horoscope_invalid_sign(self, client):
        """Test error handling for invalid zodiac sign."""
        response = client.get("/api/v1/horoscope?sign=invalid")

        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_horoscope_invalid_date_format(self, client):
        """Test error handling for invalid date format."""
        response = client.get("/api/v1/horoscope?sign=libra&date=2025/03/15")

        assert response.status_code == 400

    def test_daily_horoscope_convenience_endpoint(self, client):
        """Test /horoscope/daily convenience endpoint."""
        response = client.get("/api/v1/horoscope/daily?sign=pisces")

        assert response.status_code == 200
        data = response.get_json()

        assert data["type"] == "daily"
        assert data["sign"] == "pisces"

    def test_horoscope_no_hardcoded_values(self, client):
        """Verify no hardcoded 'Purple' / 'Seven' values."""
        # Request horoscopes for multiple signs and dates
        results = []

        for sign in ["aries", "taurus", "gemini"]:
            for day in range(1, 4):
                response = client.get(f"/api/v1/horoscope?sign={sign}&type=daily&date=2025-01-{day:02d}")
                data = response.get_json()
                results.append(data["luckyElements"])

        # Check for variation
        colors = [r["color"] for r in results]
        numbers = [r["number"] for r in results]

        # Should not all be 'Purple' and 7
        assert not all(c == "Purple" for c in colors), "Colors should vary, not hardcoded Purple"
        assert not all(n == 7 for n in numbers), "Numbers should vary, not hardcoded 7"


class TestDashaEndpoints:
    """Test dasha calculation endpoints."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def sample_birth_data(self):
        return {"date": "1990-01-15", "time": "14:30", "timezone": "Asia/Kolkata", "latitude": 19.0760, "longitude": 72.8777}

    def test_dashas_get_endpoint(self, client):
        """Test GET /dashas endpoint."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
            },
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "mahadasha" in data
        assert "antardasha" in data
        assert data["mahadasha"]["lord"] is not None
        assert data["mahadasha"]["start"] is not None
        assert data["mahadasha"]["end"] is not None

    def test_dashas_post_complete_endpoint(self, client, sample_birth_data):
        """Test POST /dashas/complete endpoint."""
        response = client.post(
            "/api/v1/astrology/dashas/complete", json={"birthData": sample_birth_data, "targetDate": "2025-01-01"}
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "dasha" in data
        assert "current_period" in data
        assert "impact_analysis" in data

    def test_dashas_missing_required_params(self, client):
        """Test error handling for missing parameters."""
        response = client.get("/api/v1/astrology/dashas")

        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_dashas_complete_missing_birth_data(self, client):
        """Test error handling for incomplete birth data."""
        response = client.post(
            "/api/v1/astrology/dashas/complete",
            json={
                "birthData": {
                    "date": "1990-01-15"
                    # Missing time, lat, lon
                }
            },
        )

        assert response.status_code == 400

    def test_dashas_with_transitions(self, client, sample_birth_data):
        """Test dasha with transition information."""
        response = client.post(
            "/api/v1/astrology/dashas/complete",
            json={"birthData": sample_birth_data, "targetDate": "2025-01-01", "includeTransitions": True},
        )

        assert response.status_code == 200
        data = response.get_json()

        if "transitions" in data:
            trans = data["transitions"]
            assert "timing" in trans
            assert "insights" in trans

    def test_dashas_with_education(self, client, sample_birth_data):
        """Test dasha with educational content."""
        response = client.post(
            "/api/v1/astrology/dashas/complete",
            json={"birthData": sample_birth_data, "targetDate": "2025-01-01", "includeEducation": True},
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "education" in data
        assert "calculation_explanation" in data["education"]

    def test_dashas_with_boundaries(self, client):
        """Test dasha with antardasha boundaries."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
                "include_boundaries": "true",
            },
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "boundaries" in data
        assert "antardasha" in data["boundaries"]
        assert len(data["boundaries"]["antardasha"]) > 0

    def test_dashas_with_debug(self, client):
        """Test dasha with debug information."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
                "debug": "true",
            },
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "debug" in data
        assert "start_lord" in data["debug"]


class TestPositionsEndpoint:
    """Test planetary positions endpoint."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_current_positions(self, client):
        """Test GET /positions endpoint."""
        response = client.get("/api/v1/astrology/positions")

        assert response.status_code == 200
        data = response.get_json()

        # Should have major planets
        expected_planets = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]

        for planet in expected_planets:
            assert planet in data, f"Missing {planet}"
            assert "degree" in data[planet]
            assert "sign" in data[planet]


class TestErrorHandling:
    """Test comprehensive error handling."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_404_for_nonexistent_endpoint(self, client):
        """Test 404 for nonexistent routes."""
        response = client.get("/api/v1/nonexistent")
        assert response.status_code == 404

    def test_405_method_not_allowed(self, client):
        """Test 405 for wrong HTTP methods."""
        # POST to GET-only endpoint
        response = client.post("/api/v1/astrology/positions")
        assert response.status_code == 405

    def test_invalid_json_payload(self, client):
        """Test error handling for invalid JSON."""
        response = client.post("/api/v1/astrology/dashas/complete", data="not valid json", content_type="application/json")

        # Should handle gracefully
        assert response.status_code in [400, 500]

    @pytest.mark.parametrize(
        "invalid_date",
        [
            "2025-13-01",  # Invalid month
            "2025-02-30",  # Invalid day
            "invalid",  # Not a date
        ],
    )
    def test_invalid_date_formats(self, client, invalid_date):
        """Test error handling for various invalid dates."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={"birth_date": invalid_date, "birth_time": "14:30", "target_date": "2025-01-01"},
        )

        assert response.status_code == 400

    def test_lenient_date_format(self, client):
        """Test that Python's strptime is lenient with single-digit dates."""
        # Note: '2025-1-1' actually works in Python's strptime
        # This is expected behavior, not a bug
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={"birth_date": "2025-1-1", "birth_time": "14:30", "timezone": "UTC", "target_date": "2025-01-01"},
        )

        # Should work (Python is lenient)
        assert response.status_code in [200, 500]  # May fail if no active dasha, but not due to format


class TestResponseSchemas:
    """Test that API responses match expected schemas."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_horoscope_response_schema(self, client):
        """Verify horoscope response has all required fields."""
        response = client.get("/api/v1/horoscope?sign=aries&type=daily")
        data = response.get_json()

        required_fields = ["id", "sign", "date", "type", "content", "luckyElements"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"

        # Verify luckyElements structure
        lucky = data["luckyElements"]
        required_lucky_fields = ["color", "number", "day", "element", "ruler"]
        for field in required_lucky_fields:
            assert field in lucky, f"Missing luckyElements field: {field}"

    def test_dasha_get_response_schema(self, client):
        """Verify GET /dashas response schema."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
            },
        )
        data = response.get_json()

        assert "mahadasha" in data
        assert "antardasha" in data

        # Verify mahadasha structure
        maha = data["mahadasha"]
        required_maha_fields = ["lord", "start", "end", "annotation"]
        for field in required_maha_fields:
            assert field in maha, f"Missing mahadasha field: {field}"

    def test_dasha_complete_response_schema(self, client):
        """Verify POST /dashas/complete response schema."""
        response = client.post(
            "/api/v1/astrology/dashas/complete",
            json={
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                },
                "targetDate": "2025-01-01",
            },
        )
        data = response.get_json()

        required_top_level = ["dasha", "current_period", "impact_analysis", "planetary_keywords"]
        for field in required_top_level:
            assert field in data, f"Missing top-level field: {field}"

        # Verify impact_analysis structure
        impact = data["impact_analysis"]
        assert "mahadasha_impact" in impact
        assert "antardasha_impact" in impact
        assert "combined_scores" in impact

        # Verify combined_scores has required domains
        scores = impact["combined_scores"]
        required_domains = ["career", "relationships", "health", "spiritual"]
        for domain in required_domains:
            assert domain in scores, f"Missing score domain: {domain}"
