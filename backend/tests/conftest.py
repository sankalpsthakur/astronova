import os
import sys
import pytest

# Ensure project root is on sys.path so "backend" imports work when running tests
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BACKEND_DIR = os.path.join(ROOT_DIR, "backend")
for path in (ROOT_DIR, BACKEND_DIR):
    if path not in sys.path:
        sys.path.insert(0, path)

from backend import app as app_module

class TestLimiter(app_module.Limiter):
    def __init__(self, *args, **kwargs):
        kwargs['default_limits'] = ["2 per minute"]
        super().__init__(*args, **kwargs)

@pytest.fixture
def app(monkeypatch):
    monkeypatch.setattr(app_module, 'Limiter', TestLimiter)
    application = app_module.create_app()
    application.config['TESTING'] = True
    return application

@pytest.fixture
def client(app):
    return app.test_client()
