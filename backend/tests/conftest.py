import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure project root is on sys.path so "backend" imports work when running tests
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BACKEND_DIR = os.path.join(ROOT_DIR, "backend")
for path in (ROOT_DIR, BACKEND_DIR):
    if path not in sys.path:
        sys.path.insert(0, path)

os.environ.setdefault("SECRET_KEY", "test")
from backend import app as app_module


class TestLimiter(app_module.Limiter):
    """Limiter with very low limits for testing."""

    def __init__(self, *args, **kwargs):
        kwargs["default_limits"] = ["2/minute"]
        super().__init__(*args, **kwargs)


@pytest.fixture
def app(monkeypatch):
    """Create FastAPI app instance for tests."""

    monkeypatch.setattr(app_module, "Limiter", TestLimiter)
    os.environ.setdefault("SECRET_KEY", "test")
    application = app_module.create_app()
    return application


@pytest.fixture
def client(app):
    """Return a TestClient for the FastAPI app."""

    with TestClient(app) as test_client:
        yield test_client
