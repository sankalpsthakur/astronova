"""
Example test file demonstrating usage of conftest fixtures.
Shows best practices for test isolation and fixture usage.
"""

from __future__ import annotations

from datetime import datetime

import pytest

import db as db_module

# ============================================================================
# Database Isolation Tests
# ============================================================================


class TestDatabaseIsolation:
    """Demonstrate database isolation between tests."""

    def test_clean_db_starts_empty(self, clean_db):
        """Each test with clean_db starts with empty tables."""
        cursor = clean_db.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        count = cursor.fetchone()[0]
        assert count == 0, "Database should start empty"

    def test_data_does_not_persist(self, clean_db):
        """Data from previous test should not be visible."""
        # Previous test created no users, this test should also see 0
        cursor = clean_db.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        count = cursor.fetchone()[0]
        assert count == 0, "Database should be clean"


# ============================================================================
# User & Authentication Tests
# ============================================================================


class TestUserFixtures:
    """Demonstrate user fixture usage."""

    def test_sample_user_exists(self, sample_user, db):
        """sample_user fixture creates a test user."""
        cursor = db.cursor()
        cursor.execute("SELECT id, email FROM users WHERE id=?", (sample_user["id"],))
        row = cursor.fetchone()

        assert row is not None
        assert row["id"] == sample_user["id"]
        assert row["email"] == sample_user["email"]

    def test_authenticated_client_has_token(self, authenticated_client):
        """authenticated_client includes auth header."""
        response = authenticated_client.get("/api/v1/auth/validate")
        assert response.status_code == 200
        data = response.get_json()
        assert data["valid"] is True


# ============================================================================
# Factory Tests
# ============================================================================


class TestFactories:
    """Demonstrate factory fixture usage."""

    def test_user_factory_creates_multiple_users(self, user_factory, db):
        """UserFactory can create multiple unique users."""
        user1 = user_factory.create()
        user2 = user_factory.create()
        user3 = user_factory.create()

        assert user1["id"] != user2["id"] != user3["id"]
        assert user1["email"] != user2["email"]

        # Verify all created in DB
        cursor = db.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        count = cursor.fetchone()[0]
        assert count == 3

    def test_user_factory_with_overrides(self, user_factory):
        """UserFactory accepts field overrides."""
        user = user_factory.create(email="custom@example.com", first_name="Custom")

        assert user["email"] == "custom@example.com"
        assert user["first_name"] == "Custom"
        assert "test-user-" in user["id"]  # ID still auto-generated

    def test_birth_data_factory(self, birth_data_factory):
        """BirthDataFactory generates valid birth data."""
        bd1 = birth_data_factory.create()
        bd2 = birth_data_factory.create()

        # Should have all required fields
        assert "date" in bd1
        assert "time" in bd1
        assert "timezone" in bd1
        assert "latitude" in bd1
        assert "longitude" in bd1

        # Should be different
        assert bd1["date"] != bd2["date"] or bd1["time"] != bd2["time"]

    def test_birth_data_factory_with_overrides(self, birth_data_factory):
        """BirthDataFactory accepts overrides."""
        bd = birth_data_factory.create(date="2000-01-01", timezone="America/New_York")

        assert bd["date"] == "2000-01-01"
        assert bd["timezone"] == "America/New_York"

    def test_report_factory(self, report_factory, sample_user):
        """ReportFactory creates reports."""
        report = report_factory.create(user_id=sample_user["id"])

        assert report["user_id"] == sample_user["id"]
        assert "report_id" in report
        assert report["status"] == "completed"

    def test_report_factory_multiple_reports(self, report_factory, user_factory):
        """Can create multiple reports for same user."""
        user = user_factory.create()

        r1 = report_factory.create(user_id=user["id"], type="natal_chart")
        r2 = report_factory.create(user_id=user["id"], type="transit")
        r3 = report_factory.create(user_id=user["id"], type="compatibility")

        # All different report IDs
        assert len({r1["report_id"], r2["report_id"], r3["report_id"]}) == 3

        # All for same user
        assert r1["user_id"] == r2["user_id"] == r3["user_id"] == user["id"]

        # Verify in DB
        reports = db_module.get_user_reports(user["id"])
        assert len(reports) == 3


# ============================================================================
# Time Fixtures Tests
# ============================================================================


class TestTimeFreezing:
    """Demonstrate time freezing fixtures."""

    def test_freeze_time_context_manager(self, freeze_time):
        """freeze_time fixture returns context manager."""
        with freeze_time("2025-01-15 12:00:00"):
            frozen = datetime.now()
            assert frozen.year == 2025
            assert frozen.month == 1
            assert frozen.day == 15
            assert frozen.hour == 12

        # Outside context, time is normal
        now = datetime.now()
        assert now.year >= 2025

    def test_frozen_time_fixture(self, frozen_time):
        """frozen_time freezes time for entire test."""
        # Time is frozen throughout test
        t1 = datetime.now()
        t2 = datetime.now()

        # Should be identical (time is frozen)
        assert t1 == t2
        assert t1.year == 2025
        assert t1.month == 1
        assert t1.day == 1


# ============================================================================
# Mock Fixtures Tests
# ============================================================================


class TestMockFixtures:
    """Demonstrate mocking fixtures."""

    def test_mock_ephemeris(self, mock_ephemeris):
        """mock_ephemeris provides predictable positions."""
        from services.ephemeris_service import EphemerisService

        service = EphemerisService()
        result = service.get_positions_for_date(datetime(2025, 1, 1))

        # Should return mocked data
        assert "planets" in result
        assert result["planets"]["sun"]["sign"] == "Capricorn"
        assert result["planets"]["moon"]["sign"] == "Taurus"

    def test_mock_geocoding(self, mock_geocoding):
        """mock_geocoding provides predictable location."""
        try:
            from geopy.geocoders import Nominatim

            geocoder = Nominatim(user_agent="test")
            location = geocoder.geocode("Mumbai")

            # Should return mocked data
            assert location is not None
            assert location.latitude == 19.0760
            assert location.longitude == 72.8777
        except ImportError:
            # geopy not installed, just test the mock function directly
            location = mock_geocoding("Mumbai")
            assert location is not None
            assert location.latitude == 19.0760


# ============================================================================
# Planetary Data Tests
# ============================================================================


class TestPlanetaryDataFixtures:
    """Demonstrate planetary data fixtures."""

    def test_sample_planet_data(self, sample_planet_data):
        """sample_planet_data provides neutral planetary positions."""
        assert "Sun" in sample_planet_data
        assert "Moon" in sample_planet_data
        assert sample_planet_data["Sun"]["sign"] == "Leo"  # Sun exalted
        assert sample_planet_data["Moon"]["sign"] == "Cancer"  # Moon exalted

    def test_exalted_planets(self, exalted_planets):
        """exalted_planets has all planets in exaltation."""
        assert exalted_planets["Sun"]["sign"] == "Aries"
        assert exalted_planets["Moon"]["sign"] == "Taurus"
        assert exalted_planets["Mars"]["sign"] == "Capricorn"
        assert exalted_planets["Jupiter"]["sign"] == "Cancer"
        assert exalted_planets["Venus"]["sign"] == "Pisces"
        assert exalted_planets["Saturn"]["sign"] == "Libra"

    def test_debilitated_planets(self, debilitated_planets):
        """debilitated_planets has all planets in debilitation."""
        assert debilitated_planets["Sun"]["sign"] == "Libra"
        assert debilitated_planets["Moon"]["sign"] == "Scorpio"
        assert debilitated_planets["Mars"]["sign"] == "Cancer"
        assert debilitated_planets["Jupiter"]["sign"] == "Capricorn"
        assert debilitated_planets["Venus"]["sign"] == "Virgo"
        assert debilitated_planets["Saturn"]["sign"] == "Aries"


# ============================================================================
# Integration Test Example
# ============================================================================


@pytest.mark.integration
class TestIntegrationExample:
    """Example of integration tests using multiple fixtures."""

    def test_user_can_store_and_retrieve_birth_data(self, client, user_factory, birth_data_factory):
        """Integration test: user stores birth data via API."""
        # Create user
        user = user_factory.create()

        # Create birth data
        bd = birth_data_factory.create()

        # Store via DB (in real app would be via API)
        db_module.upsert_user_birth_data(
            user["id"], bd["date"], bd["time"], bd["timezone"], bd["latitude"], bd["longitude"], bd.get("location_name")
        )

        # Retrieve
        stored = db_module.get_user_birth_data(user["id"])

        assert stored is not None
        assert stored["birth_date"] == bd["date"]
        assert stored["birth_time"] == bd["time"]
        assert stored["timezone"] == bd["timezone"]


# ============================================================================
# Marker Examples
# ============================================================================


@pytest.mark.unit
def test_unit_example(sample_birth_data):
    """Fast unit test with @pytest.mark.unit."""
    assert sample_birth_data["date"] == "1990-01-15"


@pytest.mark.slow
def test_slow_example(client):
    """Slow test with @pytest.mark.slow (can skip with -m 'not slow')."""
    # Simulate slow operation
    import time

    time.sleep(0.1)
    assert True


@pytest.mark.external
def test_external_example(enable_real_ephemeris):
    """Test requiring external services (skip with -m 'not external')."""
    # This would use real ephemeris
    pass
