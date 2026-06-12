"""Server-authoritative App Store payment verification.

These endpoints make the *server* the source of truth for entitlements:

- ``POST /verify`` validates a StoreKit 2 signed transaction from the client
  and records the resulting entitlement (Pro subscription, chat credits, or a
  report unlock). The client should call this after every successful purchase
  and trust the server's entitlement rather than a local flag.
- ``GET /credits`` returns the server-held chat-credit balance.
- ``POST /notifications`` receives App Store Server Notifications V2 (renewals,
  refunds, expirations, revocations) directly from Apple and updates the
  entitlement accordingly. This is what revokes access after a refund.

Every transaction is verified cryptographically against Apple's certificate
chain (see services/appstore_verification.py) and recorded idempotently.
"""

from __future__ import annotations

import logging
import os

from flask import Blueprint, g, jsonify, request
from flask_babel import gettext as _

import db
from extensions import limiter
from middleware import require_auth
from services.appstore_verification import (
    AppStoreVerificationError,
    verify_notification,
    verify_transaction,
)

payments_bp = Blueprint("payments", __name__)
logger = logging.getLogger(__name__)

APPLE_BUNDLE_ID = os.environ.get("APPLE_BUNDLE_ID", "com.astronova.app")

# Auto-renewable Pro subscription SKUs (see SUBSCRIPTION_EVENTS.md).
PRO_SUBSCRIPTION_SKUS = {
    "astronova_pro_12_month_commitment",
    "astronova_pro_monthly",
}

# Consumable chat-credit SKUs -> credits granted. Mirrors the client catalog
# (client/AstronovaApp/Services/ShopCatalog.swift).
CHAT_CREDIT_SKUS = {
    "chat_credits_5": 50,
    "chat_credits_15": 150,
    "chat_credits_50": 500,
}

REPORT_SKUS = {
    "report_general",
    "report_love",
    "report_career",
    "report_money",
    "report_health",
    "report_family",
    "report_spiritual",
}


def _ms_to_iso(value) -> str | None:
    """Apple expiry/purchase dates are epoch milliseconds."""
    if value is None:
        return None
    try:
        from datetime import datetime, timezone

        return datetime.fromtimestamp(int(value) / 1000.0, tz=timezone.utc).isoformat()
    except (ValueError, TypeError, OSError):
        return None


def _apply_transaction(user_id: str, tx: dict) -> dict:
    """Apply a verified transaction payload to the user's entitlements.

    Returns a summary dict describing what was granted.
    """
    product_id = tx.get("productId")
    transaction_id = str(tx.get("transactionId") or "")
    original_transaction_id = str(tx.get("originalTransactionId") or transaction_id)
    environment = tx.get("environment")
    expires_at = _ms_to_iso(tx.get("expiresDate"))
    revoked = tx.get("revocationDate") is not None

    # Idempotency: claiming the transaction (a PRIMARY KEY insert) is the
    # gate. Two concurrent submissions of the same transaction race on the
    # insert, and only the winner grants — a check-then-grant here would let
    # both through and double-credit the purchase.
    if product_id in PRO_SUBSCRIPTION_SKUS:
        tx_type = "subscription"
    elif product_id in CHAT_CREDIT_SKUS:
        tx_type = "credits"
    elif product_id in REPORT_SKUS:
        tx_type = "report"
    else:
        tx_type = "unknown"
    claimed = db.record_processed_transaction(
        transaction_id,
        user_id=user_id,
        product_id=product_id,
        type=tx_type,
        environment=environment,
    )

    if product_id in PRO_SUBSCRIPTION_SKUS:
        # Subscription state is an idempotent overwrite keyed on the latest
        # Apple-signed payload, so it applies regardless of claim outcome
        # (a replay must still be able to deliver a revocation).
        if revoked:
            db.deactivate_subscription(user_id, reason="revoked")
            granted = {"type": "subscription", "active": False, "productId": product_id}
        else:
            db.set_subscription_from_transaction(
                user_id,
                is_active=True,
                product_id=product_id,
                expires_at=expires_at,
                original_transaction_id=original_transaction_id,
                latest_transaction_id=transaction_id,
                environment=environment,
                auto_renew=True,
            )
            granted = {
                "type": "subscription",
                "active": True,
                "productId": product_id,
                "expiresAt": expires_at,
            }
    elif product_id in CHAT_CREDIT_SKUS:
        if claimed and not revoked:
            balance = db.add_credits(
                user_id,
                CHAT_CREDIT_SKUS[product_id],
                reason=f"purchase:{product_id}",
                transaction_id=transaction_id,
            )
        else:
            balance = db.get_credit_balance(user_id)
        granted = {"type": "credits", "productId": product_id, "balance": balance}
    elif product_id in REPORT_SKUS:
        granted = {"type": "report", "productId": product_id}
    else:
        granted = {"type": "unknown", "productId": product_id}

    return granted


@payments_bp.route("", methods=["GET"])
def payments_info():
    return jsonify(
        {
            "service": "payments",
            "status": "available",
            "endpoints": {
                "POST /verify": "Verify a StoreKit 2 signed transaction",
                "GET /credits": "Get server-side chat-credit balance",
                "POST /notifications": "App Store Server Notifications V2 webhook",
            },
        }
    )


@payments_bp.route("/verify", methods=["POST"])
@limiter.limit("30 per minute")
@require_auth
def verify():
    data = request.get_json(silent=True) or {}
    signed = data.get("signedTransaction") or data.get("jwsRepresentation") or data.get("signedPayload")
    if not signed or not isinstance(signed, str):
        return jsonify({"error": _("signedTransaction is required"), "code": "SIGNED_TRANSACTION_REQUIRED"}), 400

    try:
        tx = verify_transaction(signed)
    except AppStoreVerificationError as exc:
        logger.warning("Receipt verification rejected for user %s: %s", g.user_id, exc)
        return jsonify({"error": _("Receipt could not be verified"), "code": "VERIFICATION_FAILED"}), 400

    # Reject receipts for a different app.
    bundle_id = tx.get("bundleId") or tx.get("appBundleId")
    if bundle_id and bundle_id != APPLE_BUNDLE_ID:
        logger.warning("Receipt bundle mismatch: %s != %s", bundle_id, APPLE_BUNDLE_ID)
        return jsonify({"error": _("Receipt is for a different app"), "code": "BUNDLE_MISMATCH"}), 400

    granted = _apply_transaction(g.user_id, tx)
    entitlement = db.get_premium_entitlement(g.user_id)
    return jsonify({"status": "ok", "granted": granted, "entitlement": entitlement})


@payments_bp.route("/credits", methods=["GET"])
@require_auth
def credits():
    return jsonify({"balance": db.get_credit_balance(g.user_id)})


# Notification types that grant/maintain access vs. revoke it.
_GRANT_TYPES = {"SUBSCRIBED", "DID_RENEW", "OFFER_REDEEMED", "DID_CHANGE_RENEWAL_STATUS", "DID_CHANGE_RENEWAL_PREF"}
_REVOKE_TYPES = {"REFUND", "REVOKE", "EXPIRED", "GRACE_PERIOD_EXPIRED"}


@payments_bp.route("/notifications", methods=["POST"])
@limiter.limit("120 per minute")
def notifications():
    """App Store Server Notifications V2 webhook.

    Apple POSTs ``{"signedPayload": "<JWS>"}``. We verify the signature, then
    update the subscription state. The endpoint is unauthenticated (Apple does
    not send a bearer token) but every payload is cryptographically verified.
    Always returns 200 on a well-formed-but-unactionable notification so Apple
    does not retry indefinitely.
    """
    data = request.get_json(silent=True) or {}
    signed = data.get("signedPayload")
    if not signed or not isinstance(signed, str):
        return jsonify({"error": "signedPayload required", "code": "SIGNED_PAYLOAD_REQUIRED"}), 400

    try:
        notification = verify_notification(signed)
    except AppStoreVerificationError as exc:
        logger.warning("Rejected unverifiable App Store notification: %s", exc)
        return jsonify({"error": "verification failed", "code": "VERIFICATION_FAILED"}), 400

    ntype = notification.get("notificationType")
    tx = notification.get("transactionInfo") or {}
    original_transaction_id = str(tx.get("originalTransactionId") or tx.get("transactionId") or "")

    user_id = db.find_user_by_original_transaction(original_transaction_id)
    if not user_id:
        # We have no record of this subscription yet (e.g. notification arrived
        # before the client called /verify). Acknowledge so Apple stops retrying.
        logger.info("Notification %s for unknown originalTransactionId %s", ntype, original_transaction_id)
        return jsonify({"status": "ignored", "reason": "unknown_subscription"}), 200

    product_id = tx.get("productId")
    expires_at = _ms_to_iso(tx.get("expiresDate"))
    environment = tx.get("environment") or notification.get("data", {}).get("environment")

    if ntype in _REVOKE_TYPES:
        db.deactivate_subscription(user_id, reason=ntype)
        action = "revoked"
    elif ntype in _GRANT_TYPES:
        renewal = notification.get("renewalInfo") or {}
        auto_renew = bool(renewal.get("autoRenewStatus", 1))
        db.set_subscription_from_transaction(
            user_id,
            is_active=True,
            product_id=product_id,
            expires_at=expires_at,
            original_transaction_id=original_transaction_id,
            latest_transaction_id=str(tx.get("transactionId") or ""),
            environment=environment,
            auto_renew=auto_renew,
        )
        action = "updated"
    else:
        action = "noop"

    logger.info("App Store notification %s -> %s for user %s", ntype, action, user_id)
    return jsonify({"status": "ok", "action": action, "notificationType": ntype}), 200
