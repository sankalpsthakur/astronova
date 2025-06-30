import os
import sys
import pytest

# Ensure project root is on sys.path so "backend" imports work when running tests
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BACKEND_DIR = os.path.join(ROOT_DIR, "backend")
for path in (ROOT_DIR, BACKEND_DIR):
    if path not in sys.path:
        sys.path.insert(0, path)

try:
    from backend import app as app_module
except ImportError:
    # Fallback for CI environment
    import app as app_module

# Import Limiter directly for testing
from flask_limiter import Limiter

class TestLimiter(Limiter):
    def __init__(self, *args, **kwargs):
        kwargs['default_limits'] = ["2 per minute"]
        super().__init__(*args, **kwargs)

@pytest.fixture
def app(monkeypatch):
    # Patch the Limiter import in the app module
    import flask_limiter
    monkeypatch.setattr(flask_limiter, 'Limiter', TestLimiter)
    application = app_module.create_app()
    application.config['TESTING'] = True
    return application

@pytest.fixture
def client(app):
    return app.test_client()
