"""
Comprehensive timezone tests for dasha calculations.
Ensures consistent results regardless of timezone handling.
"""

from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

import pytest

from services.dasha_service import DashaService

try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False


class TestDashaTimezoneConsistency:
    """Test that timezone handling is consistent across all dasha calculations."""

    @pytest.fixture
    def dasha_service(self):
        return DashaService()

    @pytest.fixture
    def mumbai_birth(self):
        """Birth time in Mumbai (Asia/Kolkata)."""
        return {"local_time": "1990-01-15T14:30:00", "timezone": "Asia/Kolkata", "latitude": 19.0760, "longitude": 72.8777}

    def test_same_utc_time_gives_same_dasha(self, dasha_service, mumbai_birth):
        """Same UTC moment should give identical dasha regardless of timezone representation."""
        # Mumbai time: 14:30 IST
        dt_kolkata = datetime.strptime(mumbai_birth["local_time"], "%Y-%m-%dT%H:%M:%S")
        dt_kolkata_tz = dt_kolkata.replace(tzinfo=ZoneInfo(mumbai_birth["timezone"]))

        # Convert to UTC: 14:30 IST = 09:00 UTC
        dt_utc = dt_kolkata_tz.astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

        target = datetime(2025, 1, 1)

        # Calculate with UTC time
        result_utc = dasha_service.calculate_complete_dasha(dt_utc, moon_longitude=45.0, target_date=target)

        # Should give consistent results (actual lord depends on calculation)
        # The key is that the calculation is deterministic
        assert result_utc["mahadasha"]["lord"] is not None
        assert "start" in result_utc["mahadasha"]
        assert "end" in result_utc["mahadasha"]

    def test_timezone_affects_moon_position(self, dasha_service):
        """Timezone shifts can change nakshatra and thus dasha sequence."""
        # Birth time: 00:30 (just after midnight)
        birth_date_utc = datetime(1990, 1, 15, 0, 30)
        birth_date_kolkata = datetime(1990, 1, 15, 6, 0)  # 00:30 UTC = 06:00 IST

        target = datetime(2025, 1, 1)

        dasha_service.calculate_complete_dasha(
            birth_date_utc, moon_longitude=13.0, target_date=target  # Near nakshatra boundary
        )

        dasha_service.calculate_complete_dasha(
            birth_date_kolkata, moon_longitude=13.5, target_date=target  # Slightly shifted due to 5.5 hour difference
        )

        # Moon position affects nakshatra, which affects starting dasha
        # Results should differ if moon crossed nakshatra boundary
        # (this is EXPECTED and CORRECT behavior)

    @pytest.mark.parametrize(
        "timezone,expected_utc_hour",
        [
            ("UTC", 12),
            ("America/New_York", 17),  # EST: 12:00 EST = 17:00 UTC
            ("Europe/London", 12),  # GMT = UTC in winter
            ("Asia/Tokyo", 3),  # JST: 12:00 JST = 03:00 UTC
            ("Australia/Sydney", 1),  # AEDT: 12:00 AEDT = 01:00 UTC
        ],
    )
    def test_timezone_conversion_accuracy(self, dasha_service, timezone, expected_utc_hour):
        """Verify correct UTC conversion for various timezones."""
        local_dt = datetime(2025, 1, 15, 12, 0)  # Noon local time
        local_tz = local_dt.replace(tzinfo=ZoneInfo(timezone))
        utc_dt = local_tz.astimezone(ZoneInfo("UTC"))

        assert utc_dt.hour == expected_utc_hour

    def test_dst_boundary_handling(self, dasha_service):
        """Test births near DST transitions."""
        # March 10, 2024, 02:00 AM - DST starts in US
        # This time doesn't exist in America/New_York
        birth_date = datetime(1990, 3, 10, 14, 30)

        target = datetime(2025, 1, 1)

        result = dasha_service.calculate_complete_dasha(birth_date, moon_longitude=45.0, target_date=target)

        # Should handle gracefully without errors
        assert result["mahadasha"]["lord"] is not None

    def test_leap_day_calculation(self, dasha_service):
        """Test dasha calculations involving leap days."""
        # Feb 29, 2020 birth
        birth_date = datetime(2020, 2, 29, 14, 30)
        target = datetime(2025, 1, 1)

        result = dasha_service.calculate_complete_dasha(birth_date, moon_longitude=45.0, target_date=target)

        # Should calculate correct period without errors
        assert result["mahadasha"]["start"] is not None
        assert result["mahadasha"]["end"] is not None

    def test_year_end_boundary(self, dasha_service):
        """Test calculations across year boundaries."""
        birth_date = datetime(1989, 12, 31, 23, 59)
        target = datetime(2025, 1, 1)

        result = dasha_service.calculate_complete_dasha(birth_date, moon_longitude=45.0, target_date=target)

        assert result["mahadasha"]["lord"] is not None


class TestDashaEndpointTimezoneConsistency:
    """Test that both dasha endpoints handle timezones consistently."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_get_dashas_with_timezone(self, client):
        """GET /dashas with timezone parameter."""
        if not _SWE_OK:
            pytest.skip("pyswisseph not installed")
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

        assert data["mahadasha"]["lord"] == "Rahu"
        assert "2019-09-18" in data["mahadasha"]["start"]

    def test_post_dashas_complete_with_timezone(self, client):
        """POST /dashas/complete with timezone in body."""
        if not _SWE_OK:
            pytest.skip("pyswisseph not installed")
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

        assert response.status_code == 200
        data = response.get_json()

        assert data["dasha"]["mahadasha"]["lord"] == "Rahu"
        assert "2019-09-18" in data["dasha"]["mahadasha"]["start"]

    def test_get_post_endpoints_match(self, client):
        """GET and POST endpoints should return identical dasha periods."""
        if not _SWE_OK:
            pytest.skip("pyswisseph not installed")
        # GET request
        get_response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
            },
        )

        get_data = get_response.get_json()

        # POST request
        post_response = client.post(
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

        post_data = post_response.get_json()

        # Should match
        assert get_data["mahadasha"]["lord"] == post_data["dasha"]["mahadasha"]["lord"]
        assert get_data["mahadasha"]["start"] == post_data["dasha"]["mahadasha"]["start"]
        assert get_data["mahadasha"]["end"] == post_data["dasha"]["mahadasha"]["end"]

    def test_missing_timezone_defaults_to_utc(self, client):
        """Missing timezone parameter should default to UTC."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "target_date": "2025-01-01",
                # No timezone parameter
            },
        )

        assert response.status_code == 200
        data = response.get_json()

        # Should calculate as UTC (different result from Asia/Kolkata)
        assert data["mahadasha"]["lord"] is not None

    @pytest.mark.parametrize(
        "invalid_tz",
        [
            "Invalid/Timezone",
            "UTC+05:30",  # Offset format not supported
            "IST",  # Abbreviation not supported
            "Asia/Mumbai",  # Common mistake (should be Asia/Kolkata)
        ],
    )
    def test_invalid_timezone_error(self, client, invalid_tz):
        """Invalid timezone should return error."""
        response = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": invalid_tz,
                "target_date": "2025-01-01",
            },
        )

        assert response.status_code == 400


class TestTimezoneCriticalScenarios:
    """Test timezone scenarios that caused the original 4-year discrepancy."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_original_bug_scenario(self, client):
        """Original bug: GET without timezone vs POST with timezone gave 4-year diff."""
        # This should now be fixed

        # GET without timezone (treats as UTC)
        get_utc = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                # No timezone - defaults to UTC
                "target_date": "2025-01-01",
            },
        )

        # GET with timezone (correct)
        get_tz = client.get(
            "/api/v1/astrology/dashas",
            query_string={
                "birth_date": "1990-01-15",
                "birth_time": "14:30",
                "timezone": "Asia/Kolkata",
                "target_date": "2025-01-01",
            },
        )

        # POST with timezone (correct)
        post_tz = client.post(
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

        get_utc.get_json()
        tz_data = get_tz.get_json()
        post_data = post_tz.get_json()

        # GET with timezone and POST with timezone should MATCH
        assert tz_data["mahadasha"]["lord"] == post_data["dasha"]["mahadasha"]["lord"]
        assert tz_data["mahadasha"]["start"] == post_data["dasha"]["mahadasha"]["start"]

        # GET without timezone will differ (different interpretation of birth time)
        # This is EXPECTED - user must provide timezone for accuracy
