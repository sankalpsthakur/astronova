"""
Minimal misc endpoints: health and system status.
"""

import hmac
import logging
import os
import sys

from flask import Blueprint, g, jsonify, request
from werkzeug.exceptions import BadRequest

from db import (
    StoreKitTransactionConflict,
    get_oracle_credit_balance,
    get_subscription,
    init_db,
    record_storekit_transaction,
    set_subscription,
    sync_oracle_credit_purchase,
    sync_report_purchase_entitlement,
)
from middleware import require_auth
from services.storekit_verifier import StoreKitVerificationError, verify_storekit_transaction
from utils.time_utils import utc_now_iso

misc_bp = Blueprint("misc", __name__)
logger = logging.getLogger(__name__)
_PRO_PRODUCT_IDS = {
    "astronova_pro_monthly",
    "astronova_pro_12_month_commitment",
}
_REPORT_PRODUCT_TYPES = {
    "report_general": "birth_chart",
    "report_love": "love_forecast",
    "report_career": "career_forecast",
    "report_money": "money_forecast",
    "report_health": "health_forecast",
    "report_family": "family_forecast",
    "report_spiritual": "spiritual_forecast",
}
_ORACLE_CREDIT_PRODUCTS = {
    "chat_credits_5": 50,
    "chat_credits_15": 150,
    "chat_credits_50": 500,
}


@misc_bp.route("/oracle-credits/status", methods=["GET"])
@require_auth
def oracle_credits_status():
    return jsonify({"balance": get_oracle_credit_balance(g.user_id)})


def _is_production_environment() -> bool:
    markers = [os.environ.get(name, "").strip().lower() for name in ("FLASK_ENV", "APP_ENV", "ENV")]
    if any(marker in {"production", "prod"} for marker in markers):
        return True
    if any(marker in {"development", "dev", "local", "test", "testing"} for marker in markers):
        return False
    if os.environ.get("RENDER") or os.environ.get("RENDER_SERVICE_ID"):
        return True

    public_base_url = os.environ.get("PUBLIC_BASE_URL") or os.environ.get("ASTRONOVA_BASE_URL") or ""
    public_base_url = public_base_url.strip().lower()
    if public_base_url.startswith("https://") and "localhost" not in public_base_url and "127.0.0.1" not in public_base_url:
        return True

    return True


def _require_admin_token_if_production():
    if not _is_production_environment():
        return None

    authorization = request.headers.get("Authorization", "")
    supplied_token = request.headers.get("X-Admin-Token") or authorization.removeprefix("Bearer ").strip()
    if not supplied_token:
        return jsonify({"error": "Admin authorization required", "code": "ADMIN_AUTH_REQUIRED"}), 401

    expected_token = os.environ.get("ADMIN_API_TOKEN")
    if not expected_token:
        logger.error("ADMIN_API_TOKEN is not configured; refusing seed-test-user request")
        return jsonify({"error": "Admin API is not configured", "code": "ADMIN_NOT_CONFIGURED"}), 503

    if not hmac.compare_digest(supplied_token, expected_token):
        return jsonify({"error": "Admin authorization required", "code": "ADMIN_AUTH_REQUIRED"}), 401

    return None


@misc_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify(
        {"status": "healthy", "service": "astronova-api", "version": "minimal", "timestamp": utc_now_iso()}
    )


@misc_bp.route("/system-status", methods=["GET"])
def system_status():
    return jsonify(
        {
            "status": "operational",
            "system": {
                "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                "timestamp": utc_now_iso(),
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
    # A query userId is tolerated as a consistency check, but the JWT subject is
    # authoritative so callers cannot inspect another user's subscription.
    init_db()
    requested_user_id = request.args.get("userId")
    user_id = g.user_id
    if requested_user_id and requested_user_id != user_id:
        return jsonify({"error": "Access denied - cannot access other user's subscription", "code": "FORBIDDEN"}), 403
    return jsonify(get_subscription(user_id))


@misc_bp.route("/subscription/sync", methods=["POST"])
@require_auth
def subscription_sync():
    """
    Sync a StoreKit-verified Pro entitlement from the native client.

    The JWT subject is authoritative for the user. The client may include a
    transaction/original transaction identifier for audit and idempotent retry,
    but only known Pro product IDs can activate server-side premium gates.
    """
    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Request body must be a JSON object", "code": "INVALID_PAYLOAD"}), 400

    product_id = data.get("productId") or data.get("product_id")
    transaction_id = data.get("transactionId") or data.get("transaction_id")
    original_transaction_id = data.get("originalTransactionId") or data.get("original_transaction_id")
    signed_transaction_jws = data.get("signedTransactionJWS") or data.get("signed_transaction_jws")

    if not isinstance(product_id, str) or not product_id.strip():
        return jsonify({"error": "productId is required", "code": "INVALID_PAYLOAD"}), 400

    product_id = product_id.strip()
    if product_id not in _PRO_PRODUCT_IDS:
        return jsonify({
            "error": "Only Astronova Pro products can activate subscription status",
            "code": "UNSUPPORTED_PRODUCT",
        }), 400

    if not any(isinstance(value, str) and value.strip() for value in (transaction_id, original_transaction_id)):
        return jsonify({
            "error": "A transactionId or originalTransactionId is required",
            "code": "INVALID_PAYLOAD",
        }), 400

    try:
        verified_transaction = verify_storekit_transaction(
            signed_transaction_jws,
            expected_product_id=product_id,
            expected_transaction_id=transaction_id.strip() if isinstance(transaction_id, str) and transaction_id.strip() else None,
        )
    except StoreKitVerificationError as exc:
        logger.warning("Rejected StoreKit subscription sync for user=%s product=%s: %s", g.user_id, product_id, exc)
        status = 503 if "root certificates" in str(exc) else 400
        return jsonify({"error": str(exc), "code": "STOREKIT_TRANSACTION_UNVERIFIED"}), status

    try:
        record_storekit_transaction(
            user_id=g.user_id,
            product_id=verified_transaction.product_id,
            purchase_kind="subscription",
            transaction_id=verified_transaction.transaction_id,
            original_transaction_id=verified_transaction.original_transaction_id,
            environment=verified_transaction.environment,
        )
    except StoreKitTransactionConflict:
        return jsonify({"error": "Transaction already belongs to another delivery", "code": "TRANSACTION_REPLAY"}), 409

    set_subscription(g.user_id, True, verified_transaction.product_id)
    subscription = get_subscription(g.user_id)
    logger.info(
        "Synced StoreKit subscription for user=%s product=%s",
        g.user_id,
        verified_transaction.product_id,
    )

    return jsonify({
        "isActive": bool(subscription.get("isActive")),
        "productId": subscription.get("productId"),
        "updatedAt": subscription.get("updatedAt"),
        "entitlement": {
            "hasPremium": bool(subscription.get("isActive")),
            "source": "subscription_sync",
        },
    })


@misc_bp.route("/report-entitlements/sync", methods=["POST"])
@require_auth
def report_entitlement_sync():
    """
    Sync a StoreKit-verified individual report purchase.

    Individual reports are non-consumable in the client catalog, but the
    server still needs an auditable entitlement before allowing one matching
    report generation for non-Pro users.
    """
    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Request body must be a JSON object", "code": "INVALID_PAYLOAD"}), 400

    product_id = data.get("productId") or data.get("product_id")
    transaction_id = data.get("transactionId") or data.get("transaction_id")
    original_transaction_id = data.get("originalTransactionId") or data.get("original_transaction_id")
    environment = data.get("environment")
    signed_transaction_jws = data.get("signedTransactionJWS") or data.get("signed_transaction_jws")

    if not isinstance(product_id, str) or not product_id.strip():
        return jsonify({"error": "productId is required", "code": "INVALID_PAYLOAD"}), 400
    product_id = product_id.strip()

    report_type = _REPORT_PRODUCT_TYPES.get(product_id)
    if not report_type:
        return jsonify({
            "error": "Only Astronova report products can activate report generation",
            "code": "UNSUPPORTED_PRODUCT",
        }), 400

    if not isinstance(transaction_id, str) or not transaction_id.strip():
        return jsonify({
            "error": "transactionId is required",
            "code": "INVALID_PAYLOAD",
        }), 400

    try:
        verified_transaction = verify_storekit_transaction(
            signed_transaction_jws,
            expected_product_id=product_id,
            expected_transaction_id=transaction_id.strip(),
        )
    except StoreKitVerificationError as exc:
        logger.warning("Rejected StoreKit report sync for user=%s product=%s: %s", g.user_id, product_id, exc)
        status = 503 if "root certificates" in str(exc) else 400
        return jsonify({"error": str(exc), "code": "STOREKIT_TRANSACTION_UNVERIFIED"}), status

    try:
        record_storekit_transaction(
            user_id=g.user_id,
            product_id=verified_transaction.product_id,
            purchase_kind="report",
            transaction_id=verified_transaction.transaction_id,
            original_transaction_id=verified_transaction.original_transaction_id,
            units=1,
            environment=verified_transaction.environment,
        )
    except StoreKitTransactionConflict:
        return jsonify({"error": "Transaction already belongs to another delivery", "code": "TRANSACTION_REPLAY"}), 409

    entitlement = sync_report_purchase_entitlement(
        user_id=g.user_id,
        product_id=verified_transaction.product_id,
        report_type=report_type,
        transaction_id=verified_transaction.transaction_id,
        original_transaction_id=verified_transaction.original_transaction_id
        or (original_transaction_id.strip() if isinstance(original_transaction_id, str) else None),
        environment=verified_transaction.environment or (environment.strip() if isinstance(environment, str) else None),
    )
    logger.info(
        "Synced report purchase entitlement for user=%s product=%s report_type=%s",
        g.user_id,
        product_id,
        report_type,
    )

    return jsonify({
        "isAvailable": bool(entitlement.get("isAvailable")),
        "productId": entitlement.get("productId"),
        "reportType": entitlement.get("reportType"),
        "transactionId": entitlement.get("transactionId"),
        "consumedReportId": entitlement.get("consumedReportId"),
        "createdAt": entitlement.get("createdAt"),
    })


@misc_bp.route("/oracle-credits/sync", methods=["POST"])
@require_auth
def oracle_credits_sync():
    """Deliver a verified consumable purchase into the durable credit ledger."""
    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({"error": "Request body must be valid JSON", "code": "INVALID_JSON"}), 400

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Request body must be a JSON object", "code": "INVALID_PAYLOAD"}), 400

    product_id = data.get("productId") or data.get("product_id")
    transaction_id = data.get("transactionId") or data.get("transaction_id")
    signed_transaction_jws = data.get("signedTransactionJWS") or data.get("signed_transaction_jws")
    if not isinstance(product_id, str) or product_id.strip() not in _ORACLE_CREDIT_PRODUCTS:
        return jsonify({"error": "Unsupported Oracle credit product", "code": "UNSUPPORTED_PRODUCT"}), 400
    product_id = product_id.strip()
    if not isinstance(transaction_id, str) or not transaction_id.strip():
        return jsonify({"error": "transactionId is required", "code": "INVALID_PAYLOAD"}), 400

    try:
        verified_transaction = verify_storekit_transaction(
            signed_transaction_jws,
            expected_product_id=product_id,
            expected_transaction_id=transaction_id.strip(),
        )
        delivery = sync_oracle_credit_purchase(
            user_id=g.user_id,
            product_id=verified_transaction.product_id,
            transaction_id=verified_transaction.transaction_id,
            credits=_ORACLE_CREDIT_PRODUCTS[verified_transaction.product_id],
            original_transaction_id=verified_transaction.original_transaction_id,
            environment=verified_transaction.environment,
        )
    except StoreKitVerificationError as exc:
        logger.warning("Rejected StoreKit credit sync for user=%s product=%s: %s", g.user_id, product_id, exc)
        status = 503 if "root certificates" in str(exc) else 400
        return jsonify({"error": str(exc), "code": "STOREKIT_TRANSACTION_UNVERIFIED"}), status
    except StoreKitTransactionConflict:
        return jsonify({"error": "Transaction already belongs to another delivery", "code": "TRANSACTION_REPLAY"}), 409

    logger.info("Delivered StoreKit Oracle credits for user=%s product=%s replayed=%s", g.user_id, product_id, delivery["replayed"])
    return jsonify({
        "productId": product_id,
        "balance": delivery["balance"],
        "creditedUnits": delivery["creditedUnits"],
        "replayed": delivery["replayed"],
        "updatedAt": delivery["updatedAt"],
    })


@misc_bp.route("/config", methods=["GET"])
def remote_config():
    """Lightweight remote configuration for the client.

    Mirrors the structure of client's remote_config.json and can be extended over time.
    """
    return jsonify(
        {
            "paywall_variant": "control",
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
        now = utc_now_iso()
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
            "instructions": "Authenticate with /api/v1/auth/apple and use the returned Bearer JWT for API testing"
        }), 201

    except Exception as e:
        conn.rollback()
        logger.error(f"Failed to seed test user: {e}")
        return jsonify({"error": "Failed to create test user", "details": str(e)}), 500
    finally:
        conn.close()
