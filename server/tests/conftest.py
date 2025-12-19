"""
Pytest configuration and fixtures for astronova test suite.
Provides comprehensive test isolation, database management, and test data factories.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import Mock, patch
from zoneinfo import ZoneInfo

import pytest
from freezegun import freeze_time as _freeze_time

SERVER_ROOT = Path(__file__).resolve().parents[1]
if str(SERVER_ROOT) not in sys.path:
    sys.path.append(str(SERVER_ROOT))

import db as db_module
from app import create_app

# ============================================================================
# Pytest Configuration
# ============================================================================


def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')")
    config.addinivalue_line("markers", "integration: marks tests as integration tests")
    config.addinivalue_line("markers", "unit: marks tests as unit tests")
    config.addinivalue_line("markers", "external: marks tests that require external services (ephemeris, geocoding)")


# ============================================================================
# Application & Client Fixtures
# ============================================================================


@pytest.fixture(scope="session")
def app_config():
    """Test application configuration."""
    return {
        "TESTING": True,
        "DEBUG": False,
        "PRESERVE_CONTEXT_ON_EXCEPTION": False,
        "PROPAGATE_EXCEPTIONS": False,
    }


@pytest.fixture()
def app(app_config, test_db_path):
    """
    Flask test app with test configuration and isolated database.
    Each test gets a fresh app instance with clean database.
    """
    # Override DB_PATH to use test database
    original_db_path = db_module.DB_PATH
    db_module.DB_PATH = test_db_path

    try:
        app = create_app()
        app.config.update(app_config)

        # Initialize test database
        db_module.init_db()

        yield app
    finally:
        # Restore original DB_PATH
        db_module.DB_PATH = original_db_path


class ThreadSafeTestClient:
    """Create a fresh Flask test client per request to allow threading in tests."""

    def __init__(self, app):
        self._app = app
        self.environ_base: dict = {}

    def _call(self, method_name: str, *args, **kwargs):
        with self._app.test_client() as client:
            if self.environ_base:
                client.environ_base.update(self.environ_base)
            method = getattr(client, method_name)
            return method(*args, **kwargs)

    def open(self, *args, **kwargs):
        return self._call("open", *args, **kwargs)

    def get(self, *args, **kwargs):
        return self._call("get", *args, **kwargs)

    def post(self, *args, **kwargs):
        return self._call("post", *args, **kwargs)

    def put(self, *args, **kwargs):
        return self._call("put", *args, **kwargs)

    def delete(self, *args, **kwargs):
        return self._call("delete", *args, **kwargs)

    def options(self, *args, **kwargs):
        return self._call("options", *args, **kwargs)


@pytest.fixture()
def client(app):
    """Thread-safe Flask test client fixture."""
    return ThreadSafeTestClient(app)


# ============================================================================
# Database Fixtures
# ============================================================================


@pytest.fixture()
def test_db_path(tmp_path):
    """
    Temporary database path for test isolation.
    Each test gets its own database file that's cleaned up automatically.
    """
    db_file = tmp_path / "test_astronova.db"
    return str(db_file)


@pytest.fixture()
def db(test_db_path):
    """
    Direct database connection for tests that need low-level access.
    Automatically cleaned up after test.
    """
    # Override module-level DB_PATH
    original_db_path = db_module.DB_PATH
    db_module.DB_PATH = test_db_path

    try:
        # Initialize database
        db_module.init_db()

        # Return connection
        conn = db_module.get_connection()
        yield conn

        # Cleanup
        conn.close()
    finally:
        db_module.DB_PATH = original_db_path


@pytest.fixture()
def clean_db(db):
    """
    Fresh database reset before each test.
    Deletes all data but preserves schema.
    """
    cursor = db.cursor()

    # Clear all tables
    tables = [
        "chat_messages",
        "chat_conversations",
        "user_birth_data",
        "subscription_status",
        "reports",
        "content_insights",
        "content_quick_questions",
        "users",
    ]

    for table in tables:
        cursor.execute(f"DELETE FROM {table}")

    db.commit()

    yield db


# ============================================================================
# Authentication & User Fixtures
# ============================================================================


@pytest.fixture()
def sample_user(clean_db):
    """
    Pre-created test user with minimal data.
    Returns user dict with id, email, and names.
    """
    user_data = {
        "id": "test-user-123",
        "email": "test@astronova.com",
        "first_name": "Test",
        "last_name": "User",
        "full_name": "Test User",
    }

    db_module.upsert_user(
        user_data["id"], user_data["email"], user_data["first_name"], user_data["last_name"], user_data["full_name"]
    )

    return user_data


@pytest.fixture()
def authenticated_client(client, sample_user):
    """
    Flask test client with valid JWT token in headers.
    Uses the demo token from auth.py for testing.
    """
    # Add authorization header to all requests
    client.environ_base["HTTP_AUTHORIZATION"] = "Bearer demo-token"
    return client


@pytest.fixture()
def sample_subscription(sample_user, clean_db):
    """Pre-created subscription for test user."""
    from datetime import datetime
    conn = db_module.get_connection()
    cur = conn.cursor()
    now = datetime.utcnow().isoformat()
    cur.execute(
        "INSERT INTO subscription_status (user_id, is_active, product_id, updated_at) VALUES (?,?,?,?)",
        (sample_user["id"], 1, "pro_monthly", now),
    )
    conn.commit()
    conn.close()
    return {"user_id": sample_user["id"], "is_active": True, "product_id": "pro_monthly"}


# ============================================================================
# Birth Data & Astrology Fixtures
# ============================================================================


@pytest.fixture()
def sample_birth_data():
    """
    Standard birth data for testing.
    Mumbai, India - Jan 15, 1990, 2:30 PM IST
    """
    return {
        "date": "1990-01-15",
        "time": "14:30",
        "timezone": "Asia/Kolkata",
        "latitude": 19.0760,
        "longitude": 72.8777,
        "location_name": "Mumbai, India",
    }


@pytest.fixture()
def sample_birth_datetime():
    """
    Birth datetime for service-level tests.
    Returns UTC datetime object.
    """
    local_dt = datetime(1990, 1, 15, 14, 30)
    return local_dt.replace(tzinfo=ZoneInfo("Asia/Kolkata")).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)


@pytest.fixture()
def sample_user_with_birth_data(sample_user, sample_birth_data, clean_db):
    """User with stored birth data for personalized astrology tests."""
    db_module.upsert_user_birth_data(
        sample_user["id"],
        sample_birth_data["date"],
        sample_birth_data["time"],
        sample_birth_data["timezone"],
        sample_birth_data["latitude"],
        sample_birth_data["longitude"],
        sample_birth_data.get("location_name"),
    )
    return sample_user


@pytest.fixture()
def sample_moon_longitude():
    """Sample Moon longitude for dasha calculations (Krittika nakshatra)."""
    return 45.0


@pytest.fixture()
def sample_target_date():
    """Standard target date for testing."""
    return datetime(2025, 1, 1, 0, 0, 0)


@pytest.fixture()
def all_zodiac_signs():
    """List of all 12 zodiac signs."""
    return [
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
    ]


@pytest.fixture()
def common_timezones():
    """List of common timezones for testing."""
    return ["UTC", "Asia/Kolkata", "America/New_York", "Europe/London", "Asia/Tokyo", "Australia/Sydney"]


# ============================================================================
# Data Factory Fixtures
# ============================================================================


class UserFactory:
    """Factory for creating test users."""

    def __init__(self):
        self._counter = 0

    def create(self, **overrides):
        """Create a test user with optional field overrides."""
        self._counter += 1
        defaults = {
            "id": f"test-user-{self._counter}",
            "email": f"user{self._counter}@test.com",
            "first_name": f"User{self._counter}",
            "last_name": "Test",
            "full_name": f"User{self._counter} Test",
        }
        defaults.update(overrides)

        db_module.upsert_user(
            defaults["id"], defaults["email"], defaults["first_name"], defaults["last_name"], defaults["full_name"]
        )

        return defaults


class BirthDataFactory:
    """Factory for creating valid birth data."""

    LOCATIONS = [
        {"name": "Mumbai, India", "lat": 19.0760, "lon": 72.8777, "tz": "Asia/Kolkata"},
        {"name": "New York, USA", "lat": 40.7128, "lon": -74.0060, "tz": "America/New_York"},
        {"name": "London, UK", "lat": 51.5074, "lon": -0.1278, "tz": "Europe/London"},
        {"name": "Tokyo, Japan", "lat": 35.6762, "lon": 139.6503, "tz": "Asia/Tokyo"},
        {"name": "Sydney, Australia", "lat": -33.8688, "lon": 151.2093, "tz": "Australia/Sydney"},
    ]

    def __init__(self):
        self._counter = 0

    def create(self, **overrides):
        """Create birth data with optional field overrides."""
        self._counter += 1
        location = self.LOCATIONS[self._counter % len(self.LOCATIONS)]

        # Generate varied birth dates
        base_date = datetime(1990, 1, 1) + timedelta(days=self._counter * 30)

        defaults = {
            "date": base_date.strftime("%Y-%m-%d"),
            "time": f"{(self._counter * 2) % 24:02d}:30",
            "timezone": location["tz"],
            "latitude": location["lat"],
            "longitude": location["lon"],
            "location_name": location["name"],
        }
        defaults.update(overrides)

        return defaults


class ReportFactory:
    """Factory for creating test reports."""

    def __init__(self):
        self._counter = 0

    def create(self, user_id=None, **overrides):
        """Create a test report with optional field overrides."""
        import uuid

        self._counter += 1

        defaults = {
            "report_id": str(uuid.uuid4()),
            "user_id": user_id or f"test-user-{self._counter}",
            "type": "natal_chart",
            "title": f"Test Report {self._counter}",
            "content": f"Test report content for report {self._counter}",
            "status": "completed",
        }
        defaults.update(overrides)

        db_module.insert_report(
            defaults["report_id"],
            defaults["user_id"],
            defaults["type"],
            defaults["title"],
            defaults["content"],
            defaults["status"],
        )

        return defaults


@pytest.fixture()
def user_factory(clean_db):
    """Factory for creating test users."""
    return UserFactory()


@pytest.fixture()
def birth_data_factory():
    """Factory for creating valid birth data."""
    return BirthDataFactory()


@pytest.fixture()
def report_factory(clean_db):
    """Factory for creating test reports."""
    return ReportFactory()


# ============================================================================
# Time & Mocking Fixtures
# ============================================================================


@pytest.fixture()
def freeze_time():
    """
    Fixture that returns a context manager for freezing time.

    Usage:
        def test_something(freeze_time):
            with freeze_time('2025-01-01 12:00:00'):
                # Time is frozen at Jan 1, 2025 12:00 PM
                assert datetime.now().year == 2025
    """
    return _freeze_time


@pytest.fixture()
def frozen_time():
    """
    Fixture that freezes time at a specific moment for the entire test.
    Time is frozen at Jan 1, 2025 00:00:00 UTC.
    """
    with _freeze_time("2025-01-01 00:00:00"):
        yield datetime(2025, 1, 1, 0, 0, 0)


@pytest.fixture()
def mock_ephemeris():
    """
    Mock ephemeris service to avoid external dependency.
    Returns predictable planetary positions for testing.
    """

    def mock_get_positions(dt, lat=None, lon=None):
        """Return mock planetary positions."""
        return {
            "planets": {
                "sun": {"longitude": 280.0, "degree": 10.0, "sign": "Capricorn", "retrograde": False},
                "moon": {"longitude": 45.0, "degree": 15.0, "sign": "Taurus", "retrograde": False},
                "mars": {"longitude": 120.0, "degree": 0.0, "sign": "Leo", "retrograde": False},
                "mercury": {"longitude": 290.0, "degree": 20.0, "sign": "Capricorn", "retrograde": False},
                "jupiter": {"longitude": 60.0, "degree": 0.0, "sign": "Gemini", "retrograde": False},
                "venus": {"longitude": 300.0, "degree": 0.0, "sign": "Aquarius", "retrograde": False},
                "saturn": {"longitude": 330.0, "degree": 0.0, "sign": "Pisces", "retrograde": False},
            }
        }

    with patch("services.ephemeris_service.EphemerisService.get_positions_for_date", side_effect=mock_get_positions):
        yield mock_get_positions


@pytest.fixture()
def mock_geocoding():
    """
    Mock geocoding service to avoid external dependency.
    Returns predictable location data.
    """

    def mock_geocode(query):
        """Return mock location data."""
        mock_location = Mock()
        mock_location.latitude = 19.0760
        mock_location.longitude = 72.8777
        mock_location.address = "Mumbai, India"
        return mock_location

    try:
        with patch("geopy.geocoders.Nominatim.geocode", side_effect=mock_geocode):
            yield mock_geocode
    except ModuleNotFoundError:
        # geopy not installed, skip mocking
        yield mock_geocode


@pytest.fixture()
def enable_real_ephemeris():
    """
    Marker fixture that indicates test should use real ephemeris.
    Use with @pytest.mark.external to run tests with actual calculations.
    """
    # This is a marker fixture - it doesn't mock anything
    # Tests decorated with @pytest.mark.external will use real services
    pass


# ============================================================================
# Planetary Data Fixtures
# ============================================================================


@pytest.fixture()
def sample_planet_data():
    """Sample planetary data for strength/impact calculations."""
    return {
        "Sun": {"sign": "Leo", "degree": 15.5, "house": 1, "retrograde": False},
        "Moon": {"sign": "Cancer", "degree": 10.2, "house": 7, "retrograde": False},
        "Mars": {"sign": "Aries", "degree": 20.0, "house": 10, "retrograde": False},
        "Mercury": {"sign": "Virgo", "degree": 5.5, "house": 2, "retrograde": False},
        "Jupiter": {"sign": "Sagittarius", "degree": 25.0, "house": 5, "retrograde": False},
        "Venus": {"sign": "Libra", "degree": 12.0, "house": 11, "retrograde": False},
        "Saturn": {"sign": "Capricorn", "degree": 8.0, "house": 6, "retrograde": False},
    }


@pytest.fixture()
def exalted_planets():
    """Planetary data with planets in exaltation."""
    return {
        "Sun": {"sign": "Aries", "degree": 10.0, "house": 1, "retrograde": False},
        "Moon": {"sign": "Taurus", "degree": 3.0, "house": 2, "retrograde": False},
        "Mars": {"sign": "Capricorn", "degree": 28.0, "house": 10, "retrograde": False},
        "Mercury": {"sign": "Virgo", "degree": 15.0, "house": 6, "retrograde": False},
        "Jupiter": {"sign": "Cancer", "degree": 5.0, "house": 4, "retrograde": False},
        "Venus": {"sign": "Pisces", "degree": 27.0, "house": 12, "retrograde": False},
        "Saturn": {"sign": "Libra", "degree": 20.0, "house": 7, "retrograde": False},
    }


@pytest.fixture()
def debilitated_planets():
    """Planetary data with planets in debilitation."""
    return {
        "Sun": {"sign": "Libra", "degree": 10.0, "house": 7, "retrograde": False},
        "Moon": {"sign": "Scorpio", "degree": 3.0, "house": 8, "retrograde": False},
        "Mars": {"sign": "Cancer", "degree": 28.0, "house": 4, "retrograde": False},
        "Mercury": {"sign": "Pisces", "degree": 15.0, "house": 12, "retrograde": False},
        "Jupiter": {"sign": "Capricorn", "degree": 5.0, "house": 10, "retrograde": False},
        "Venus": {"sign": "Virgo", "degree": 27.0, "house": 6, "retrograde": False},
        "Saturn": {"sign": "Aries", "degree": 20.0, "house": 1, "retrograde": False},
    }
