"""Production configuration validation and readiness checks.

Two responsibilities:

1. ``validate_startup_config(app)`` — called once during app creation. In a
   production environment it fails fast when a security-critical setting is
   missing (so a misconfigured deploy never serves traffic with a public dev
   secret), and logs prominent warnings for settings that degrade behavior
   (e.g. payments will fail closed without a trusted Apple root). Outside
   production it only logs, so local/dev and tests are unaffected.

2. ``readiness_report()`` — a real dependency probe (DB, ephemeris, payments,
   AI provider) used by the /readiness endpoint, distinct from the cheap
   liveness /health check.
"""

from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)


def is_production_environment() -> bool:
    return any(
        os.environ.get(name, "").lower() == "production"
        for name in ("FLASK_ENV", "APP_ENV", "ENV")
    )


class ConfigError(RuntimeError):
    """Raised at startup when a required production setting is missing."""


def validate_startup_config(app=None) -> dict:
    """Validate runtime configuration.

    Returns a dict summary {errors, warnings}. Raises ConfigError in production
    when a critical setting is missing. Safe (non-raising) outside production.
    """
    production = is_production_environment()
    errors: list[str] = []
    warnings: list[str] = []

    # JWT signing secret — without it auth tokens are forgeable.
    if not (os.environ.get("JWT_SECRET") or os.environ.get("JWT_SECRET_KEY")):
        (errors if production else warnings).append(
            "JWT_SECRET (or JWT_SECRET_KEY) is not set; tokens would use the public dev secret."
        )

    # Apple bundle id — required for Sign-In audience and receipt bundle checks.
    if not os.environ.get("APPLE_BUNDLE_ID"):
        warnings.append("APPLE_BUNDLE_ID is not set; using the default bundle id.")

    # Apple root cert — payment verification fails closed without it, so a
    # production deploy that sells subscriptions but omits this cannot grant
    # entitlements. Warn loudly rather than hard-fail (the rest of the app works).
    if not (os.environ.get("APPLE_ROOT_CA_PEM") or os.environ.get("APPLE_ROOT_CA_PATH")):
        warnings.append(
            "APPLE_ROOT_CA_PEM/APPLE_ROOT_CA_PATH not set; /payments/verify will reject "
            "all receipts until an Apple Root CA is configured."
        )

    # Rate-limit store — memory:// does not share limits across gunicorn workers.
    if production and not (os.environ.get("RATELIMIT_STORAGE_URI") or os.environ.get("REDIS_URL")):
        warnings.append(
            "No RATELIMIT_STORAGE_URI/REDIS_URL set; rate limits are per-worker only "
            "(effective limit multiplies by worker count)."
        )

    # Admin token — admin endpoints are unusable/locked without it.
    if production and not os.environ.get("ADMIN_API_TOKEN"):
        warnings.append("ADMIN_API_TOKEN is not set; admin endpoints will return 503.")

    for w in warnings:
        logger.warning("[config] %s", w)
    for e in errors:
        logger.error("[config] %s", e)

    if production and errors:
        raise ConfigError(
            "Refusing to start in production with invalid configuration: " + "; ".join(errors)
        )

    return {"production": production, "errors": errors, "warnings": warnings}


def _check_database() -> tuple[bool, str]:
    try:
        from db import get_connection

        conn = get_connection()
        try:
            conn.execute("SELECT 1")
        finally:
            conn.close()
        return True, "ok"
    except Exception as exc:  # pragma: no cover - exercised via readiness test on failure
        return False, f"unavailable: {type(exc).__name__}"


def _check_ephemeris() -> tuple[bool, str]:
    try:
        from services.ephemeris_service import SWE_AVAILABLE

        return bool(SWE_AVAILABLE), "ok" if SWE_AVAILABLE else "swisseph not installed"
    except Exception as exc:
        return False, f"error: {type(exc).__name__}"


def _check_payments() -> tuple[bool, str]:
    configured = bool(os.environ.get("APPLE_ROOT_CA_PEM") or os.environ.get("APPLE_ROOT_CA_PATH"))
    return configured, "ok" if configured else "apple root not configured"


def _check_ai_provider() -> tuple[bool, str]:
    configured = bool(os.environ.get("GEMINI_API_KEY") or os.environ.get("OPENAI_API_KEY"))
    return configured, "ok" if configured else "no AI provider key"


def readiness_report() -> dict:
    """Probe core dependencies. ``ready`` is True only when the hard
    dependencies (database, ephemeris) are healthy; payments/AI are reported
    but treated as soft (the app still serves most journeys without them)."""
    db_ok, db_msg = _check_database()
    eph_ok, eph_msg = _check_ephemeris()
    pay_ok, pay_msg = _check_payments()
    ai_ok, ai_msg = _check_ai_provider()

    checks = {
        "database": {"ok": db_ok, "detail": db_msg},
        "ephemeris": {"ok": eph_ok, "detail": eph_msg},
        "payments": {"ok": pay_ok, "detail": pay_msg},
        "ai_provider": {"ok": ai_ok, "detail": ai_msg},
    }
    ready = db_ok and eph_ok
    return {"ready": ready, "checks": checks}
