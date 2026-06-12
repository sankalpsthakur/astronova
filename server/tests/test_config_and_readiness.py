"""Tests for startup config validation and the readiness probe."""

from __future__ import annotations

import pytest

from config_validation import ConfigError, readiness_report, validate_startup_config


def _clear_prod_env(monkeypatch):
    for name in ("FLASK_ENV", "APP_ENV", "ENV"):
        monkeypatch.delenv(name, raising=False)


def test_validate_config_non_production_never_raises(monkeypatch):
    _clear_prod_env(monkeypatch)
    monkeypatch.delenv("JWT_SECRET", raising=False)
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    result = validate_startup_config()
    assert result["production"] is False
    # Missing JWT secret is only a warning outside production.
    assert any("JWT_SECRET" in w for w in result["warnings"])
    assert result["errors"] == []


def test_validate_config_production_fails_without_jwt_secret(monkeypatch):
    monkeypatch.setenv("FLASK_ENV", "production")
    monkeypatch.delenv("JWT_SECRET", raising=False)
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    with pytest.raises(ConfigError):
        validate_startup_config()


def test_validate_config_production_passes_with_required_secrets(monkeypatch):
    monkeypatch.setenv("FLASK_ENV", "production")
    monkeypatch.setenv("JWT_SECRET", "a-strong-production-secret")
    monkeypatch.setenv("IP_HASH_SALT", "a-long-enough-salt")
    # Missing Apple root / rate-limit store are warnings, not errors.
    result = validate_startup_config()
    assert result["errors"] == []
    assert result["production"] is True


def test_validate_config_production_fails_without_ip_hash_salt(monkeypatch):
    monkeypatch.setenv("FLASK_ENV", "production")
    monkeypatch.setenv("JWT_SECRET", "a-strong-production-secret")
    monkeypatch.delenv("IP_HASH_SALT", raising=False)
    with pytest.raises(ConfigError):
        validate_startup_config()


def test_readiness_report_shape_and_db_ok(client):
    # The client fixture builds an app with an initialized test DB.
    report = readiness_report()
    assert set(report["checks"].keys()) == {"database", "ephemeris", "payments", "ai_provider"}
    assert report["checks"]["database"]["ok"] is True
    assert isinstance(report["ready"], bool)


def test_readiness_endpoint(client):
    resp = client.get("/api/v1/readiness")
    assert resp.status_code in (200, 503)
    body = resp.get_json()
    assert "ready" in body and "checks" in body
    # Database must be healthy in the test environment.
    assert body["checks"]["database"]["ok"] is True
