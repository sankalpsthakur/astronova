"""
Minimal misc endpoints: health and system status.
"""

import hmac
import logging
import os
import sys
from datetime import datetime

from flask import Blueprint, g, jsonify, request

from db import get_subscription, init_db
from middleware import require_auth

misc_bp = Blueprint("misc", __name__)
logger = logging.getLogger(__name__)


def _is_production_environment() -> bool:
    return any(
        os.environ.get(name, "").lower() == "production"
        for name in ("FLASK_ENV", "APP_ENV", "ENV")
    )


def _require_admin_token_if_production():
    if not _is_production_environment():
        return None

    expected_token = os.environ.get("ADMIN_API_TOKEN")
    if not expected_token:
        logger.error("ADMIN_API_TOKEN is not configured; refusing seed-test-user request")
        return jsonify({"error": "Admin API is not configured", "code": "ADMIN_NOT_CONFIGURED"}), 503

    authorization = request.headers.get("Authorization", "")
    supplied_token = request.headers.get("X-Admin-Token") or authorization.removeprefix("Bearer ").strip()
    if not supplied_token or not hmac.compare_digest(supplied_token, expected_token):
        return jsonify({"error": "Admin authorization required", "code": "ADMIN_AUTH_REQUIRED"}), 401

    return None


@misc_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify(
        {"status": "healthy", "service": "astronova-api", "version": "minimal", "timestamp": datetime.utcnow().isoformat()}
    )


@misc_bp.route("/system-status", methods=["GET"])
def system_status():
    return jsonify(
        {
            "status": "operational",
            "system": {
                "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                "timestamp": datetime.utcnow().isoformat(),
            },
            "endpoints": {
                "health": "/api/v1/health",
                "horoscope": "/api/v1/horoscope",
                "ephemeris": "/api/v1/ephemeris",
                "chart": "/api/v1/chart",
                "auth": "/api/v1/auth",
                "chat": "/api/v1/chat",
                "locations": "/api/v1/location",
                "reports": "/api/v1/reports",
            },
        }
    )


@misc_bp.route("/subscription/status", methods=["GET"])
@require_auth
def subscription_status():
    # Native clients may still send userId/X-User-Id, but the JWT subject is
    # authoritative so callers cannot inspect another user's subscription.
    init_db()
    requested_user_id = request.args.get("userId") or request.headers.get("X-User-Id")
    user_id = g.user_id
    if requested_user_id and requested_user_id != user_id:
        return jsonify({"error": "Access denied - cannot access other user's subscription", "code": "FORBIDDEN"}), 403
    return jsonify(get_subscription(user_id))


@misc_bp.route("/config", methods=["GET"])
def remote_config():
    """Lightweight remote configuration for the client.

    Mirrors the structure of client's remote_config.json and can be extended over time.
    """
    return jsonify(
        {
            "paywall_variant": "A",
            "widget_prompt_enabled": True,
            "daily_notification_default_hour": 9,
            "home_quick_tiles_enabled": True,
        }
    )


@misc_bp.route("/seed-test-user", methods=["POST"])
def seed_test_user():
    """
    Create a test user for App Store review with complete birth data.
    In production, this endpoint requires the configured admin token.
    Subsequent calls return the existing seeded user.
    """
    from db import get_connection

    production_auth_error = _require_admin_token_if_production()
    if production_auth_error:
        return production_auth_error

    test_user_id = "appstore-test-user-2026"
    test_email = "appstore-test@astronova.app"

    conn = get_connection()
    cur = conn.cursor()

    try:
        # Check if test user already exists
        cur.execute("SELECT id FROM users WHERE id = ?", (test_user_id,))
        existing = cur.fetchone()

        if existing:
            return jsonify({
                "message": "Test user already exists",
                "user_id": test_user_id,
                "email": test_email
            }), 200

        # Create test user
        now = datetime.utcnow().isoformat()
        cur.execute("""
            INSERT INTO users (id, email, first_name, last_name, full_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (test_user_id, test_email, "Test", "Reviewer", "Test Reviewer", now, now))

        # Add complete birth data for testing all features
        # Birth data: Jan 15, 1990, 2:30 PM, New York, NY (40.7128, -74.0060)
        cur.execute("""
            INSERT INTO user_birth_data
            (user_id, birth_date, birth_time, timezone, latitude, longitude, location_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            test_user_id,
            "1990-01-15",
            "14:30",
            "America/New_York",
            40.7128,
            -74.0060,
            "New York, NY, USA",
            now,
            now
        ))

        # Set subscription to active for testing premium features
        cur.execute("""
            INSERT INTO subscription_status (user_id, is_active, product_id, updated_at)
            VALUES (?, ?, ?, ?)
        """, (test_user_id, 1, "astronova_pro_monthly", now))

        conn.commit()

        return jsonify({
            "message": "Test user created successfully",
            "user_id": test_user_id,
            "email": test_email,
            "birth_data": {
                "date": "1990-01-15",
                "time": "14:30",
                "timezone": "America/New_York",
                "location": "New York, NY, USA"
            },
            "subscription": "active (Pro)",
            "instructions": "Use X-User-Id header with this user_id for API testing"
        }), 201

    except Exception as e:
        conn.rollback()
        logger.error(f"Failed to seed test user: {e}")
        return jsonify({"error": "Failed to create test user", "details": str(e)}), 500
    finally:
        conn.close()
